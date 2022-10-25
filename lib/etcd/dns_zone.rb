# frozen_string_literal: true

require_relative "../helpers/hash_with_indifferent_access_custom"

# CoreDns::Domain
module CoreDns
  class Etcd
    class DnsZone < CoreDns::Etcd::Domain
      VALUES_WHITELIST = %w[metadata].freeze

      def add(data = {})
        data[:metadata][:zone] = true
        PutRequest.put(key, data, @client)
      end

      def list(level = 1)
        super.select { |record| record.dig('metadata', 'zone') }
      end

      def list_all
        super.select { |dns| dns.dig('metadata', 'zone') }
      end

      def subzones
        @client.domain(@namespace).list_all
          .select { |domain| domain.dig('metadata', 'zone') }
          .map { |zone_hash| @client.zone("#{zone_hash['name']}.#{namespace}") }
      end

      def parent_zone
        @namespace = @namespace.split('.')[1..].join('.')
        return nil if @namespace.empty?

        zone_hash = @client.zone(@namespace).show
        return @client.zone(@namespace) if zone_hash

        parent_zone
      end

      def fetch_zone_records
        fetch('').select do |record|
          record if record['group']&.end_with?(@namespace.to_s)
        end
      end

      def records
        zone_records = fetch_zone_records

        subzones.collect(&:namespace).map do |subzone_name|
          zone_records.reject! do |record|
            record['group']&.end_with?(subzone_name.to_s)
          end
        end

        zone_records.map do |record|
          hostname = record.delete('hostname')
          name = hostname.split('/').reverse.reject(&:empty?).join('.')
            .gsub(".#{@namespace}.#{@client.prefix}", '')
          record.merge!({'name' => name})
        end
      end

      def delete
        to_remove = []
        results = []
        prefix = @client.prefix
        records.each { |record| to_remove << get_hostname(record) }
        zone_name = "#{@namespace}./#{prefix}".split('.').reverse.join('/')
        to_remove << zone_name
        to_remove.each do |name|
          results << remove(name)
        end
        results
      end

      private

      def get_hostname(record)
        "#{record['name']}.#{@namespace}./#{@client.prefix}"
          .split('.').reverse.join('/')
      end

      def key
        "/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}"
      end
    end
  end
end
