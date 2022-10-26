# frozen_string_literal: true

require "logger"
require_relative "../helpers/hash_with_indifferent_access_custom"
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
        Request.remove(hostname, @client, @logger) if hostname
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
        Request.fetch("", @namespace, @client).map { |record| format_record record }
      end

      private

      def one_level_records(level)
        Request.fetch("", @namespace, @client).map do |record|
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

      def key
        prefix = @client.prefix
        namespace = @namespace.split(".").reverse.join("/")
        "/#{prefix}/#{namespace}/#{postfix}"
      end
    end
  end
end
