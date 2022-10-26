# frozen_string_literal: true

require "logger"
require_relative "../helpers/hash_with_indifferent_access_custom"
require_relative "../helpers/request_helper"
require_relative "../helpers/request"

module CoreDns
  class Etcd
    class Domain
      class Error < StandardError; end
      attr_reader :namespace

      def initialize(client, hostname = "")
        @namespace = hostname
        @client = client
      end

      VALUES_WHITELIST = %w[host mail port priority text ttl group].freeze

      def delete(data = {})
        data = HashWithIndifferentAccessCustom.new(data).attributes
        hostname = nil
        if data[:name]
          hostname = "#{data.delete(:name)}.#{@namespace}./#{@client.prefix}"
                     .split(".").compact.reverse.join("/")
        elsif data[:host]
          hostname = list
                     .select { |record| record["host"] == data[:host] }[0]["hostname"]
        end
        remove(hostname) if hostname
      end

      def add(data = {})
        Request.put(key, data, @client, VALUES_WHITELIST)
      end

      def show
        self.class.new(@client, "").list_all
            .select { |x| x["name"] == namespace }[0]
      end

      def list(level = 1)
        one_level_records(level)
          .map { |record| format_record record }
      end

      def list_all
        fetch("").map { |record| format_record record }
      end

      private

      def one_level_records(level)
        fetch("").map do |record|
          levels_difference = (record["hostname"].sub("/#{@client.prefix}/#{@namespace.split(".").reverse.join("/")}",
                                                      "")).split("/")[1..]
          next unless levels_difference.count == level

          record
        end.compact
      end

      def format_name(name)
        [@namespace, @client.prefix].reject(&:empty?)
                                    .each { |part| name.gsub!(".#{part}", "") }
        name
      end

      def format_record(record)
        hostname = record.delete("hostname")
        name = format_name(hostname.split("/").reverse.reject(&:empty?)
          .join("."))
        record.merge!({ "name" => name })
      end

      def available_postfix(postfixes)
        postfixes_range = (1..postfixes.count + 1).map do |i|
          "#{@client.postfix}#{i + 1}"
        end
        (postfixes_range - postfixes).first
      end

      def postfix
        postfixes = list.map { |record| record["name"].split("/").last }
        if postfixes.empty?
          "#{@client.postfix}1"
        else
          available_postfix(postfixes)
        end
      end

      def fetch(hostname)
        unless @namespace == hostname
          hostname =
            [hostname, @namespace.split(".")].flatten.compact.join(".")[1..]
        end

        prefix = @client.prefix
        key = "/#{prefix}/#{hostname.split(".").reverse.join("/")}/"
        range_end = "/#{prefix}/#{hostname.split(".").reverse.join("/")}~"

        payload = {
          key: Base64.encode64(key),
          range_end: Base64.encode64(range_end)
        }.to_json

        response = CoreDns::Helpers::RequestHelper
                   .request("#{@client.api_url}/kv/range", :post, {}, payload)
        parsed_response(response)
      rescue StandardError
        []
      end

      def parsed_response(response)
        JSON.parse(response)["kvs"].map do |encoded_hash|
          [
            { "hostname" => Base64.decode64(encoded_hash["key"]) },
            JSON.parse(Base64.decode64(encoded_hash["value"]))
          ].reduce({}, :merge)
        rescue StandardError
          next
        end.compact
      end

      def key
        prefix = @client.prefix
        namespace = @namespace.split(".").reverse.join("/")
        "/#{prefix}/#{namespace}/#{postfix}"
      end

      def remove(hostname)
        payload = { key: Base64.encode64(hostname) }.to_json
        response = CoreDns::Helpers::RequestHelper
                   .request("#{@client.api_url}/kv/deleterange", :post, {}, payload)
        response.code == 200 ? hostname : response.code
      rescue StandardError => e
        @logger.error(e.message)
      end
    end
  end
end
