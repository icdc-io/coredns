# frozen_string_literal: true

require "logger"
require_relative "../helpers/hash_with_indifferent_access_custom"
require_relative "../helpers/request_helper"

module CoreDns
  class Etcd
    class Domain < CoreDns::Domain
      class Error < StandardError; end

      VALUES_WHITELIST = %w[host mail port priority text ttl group].freeze

      def delete(data = {})
        data = HashWithIndifferentAccessCustom.new(data).attributes
        hostname = nil
        if data[:name]
          hostname = "#{data.delete(:name)}.#{@namespace}./#{@client.prefix}".split(".").compact.reverse.join("/")
        elsif data[:host]
          hostname = list.select { |record| record["host"] == data[:host] }[0]["hostname"]
        end
        remove(hostname) if hostname
      end

      def get(hostname)
        self.class.new(@client, "#{hostname}.#{@namespace}")
      end

      def add(data = {})
        put(@namespace, HashWithIndifferentAccessCustom.new(data).attributes)
      end

      def show
        self.class.new(@client, "").list_all.select { |x| x["name"] == namespace }[0]
      end

      def list(level = 1)
        one_level_records(level).map do |record|
          hostname = record.delete("hostname")
          name = format_name hostname.split("/").reverse.reject(&:empty?).join(".")
          record.merge!({ "name" => name })
        end
      end

      def one_level_records(level)
        fetch("").each do |record|
          levels_difference = (record["hostname"].sub("/#{@client.prefix}/#{@namespace.split(".").reverse.join("/")}",
                                                      "")).split("/")[1..]
          next unless levels_difference.count == level

          record
        end
      end

      def list_all
        fetch("").map do |record|
          hostname = record.delete("hostname")
          name = format_name hostname.split("/").reverse.reject(&:empty?).join(".")
          record.merge!({ "name" => name })
        end
      end

      private

      def format_name(name)
        [@namespace, @client.prefix].reject(&:empty?).each { |part| name.gsub!(".#{part}", "") }
        name
      end

      def allowed_values?(data)
        (data.keys - VALUES_WHITELIST).empty? ? false : true
      end

      def generate_postfix
        postfixes = list.collect { |record| record["name"] }.map { |key| key.split("/").last }
        if postfixes.empty?
          "#{@client.postfix}1"
        else
          ((1..postfixes.count + 1).map { |i| "#{@client.postfix}#{i + 1}" } - postfixes).first
        end
      end

      def fetch(hostname)
        hostname = [hostname, @namespace.split(".")].flatten.compact.join(".")[1..] unless @namespace == hostname
        payload = {
          key: Base64.encode64("/#{@client.prefix}/#{hostname.split(".").reverse.join("/")}/"),
          range_end: Base64.encode64("/#{@client.prefix}/#{hostname.split(".").reverse.join("/")}~")
        }.to_json
        response = CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/range", :post, {}, payload)
        parsed_response(response)
      rescue StandardError
        []
      end

      def parsed_response(response)
        JSON.parse(response)["kvs"]
            .map do |encoded_hash|
          [{ "hostname" => Base64.decode64(encoded_hash["key"]) }, JSON.parse(Base64.decode64(encoded_hash["value"]))]
            .reduce(
              {}, :merge
            )
        rescue StandardError
          next
        end.compact
      end

      def put(key, value)
        raise ArgumentError, "Unsupported values keys" unless allowed_values?(value)

        # [:txt].include?(record_type(value)) ? postfix = nil : postfix = "/#{generate_postfix}"
        postfix = "/#{generate_postfix}"
        key = "/#{@client.prefix}/#{key.split(".").reverse.join("/")}#{postfix}"
        payload = { key: Base64.encode64(key), value: Base64.encode64(value.to_json) }.to_json
        response = CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/put", :post, {}, payload)
        if response.code == 200
          payload
        else
          response.code
        end
      end

      def remove(hostname)
        payload = {
          key: Base64.encode64(hostname)
        }.to_json
        response = CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/deleterange", :post, {}, payload)
        response.code == 200 ? hostname : response.code
      rescue StandardError => e
        @logger.error(e.message)
      end

      def record_type(record)
        require "resolv"
        if record.keys.include?("text") then :txt
        elsif record.keys.include?("mail") then :mx
        elsif record.keys.include?("port") then :srv
        elsif Resolv::IPv4::Regex.match?(record["host"]) then :a
        elsif Resolv::IPv6::Regex.match?(record["host"]) then :aaaa
        elsif record["name"].match?(/ns.dns/) then :ns
        else
          :cname end
      end
    end
  end
end
