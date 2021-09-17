require_relative '../helpers/hash_with_indifferent_access_custom'
require_relative '../helpers/request_helper'

class CoreDns::Etcd::DnsZone < CoreDns::Etcd::Domain # CoreDns::Domain
  VALUES_WHITELIST = %w[metadata].freeze 

  def add(data = {})
    data[:metadata][:zone] = true
    put(@namespace, HashWithIndifferentAccessCustom.new(data).attributes)
  end

  def list(level = 1)
    super.select { |record| record.dig("metadata", "zone") }
  end

  def list_all
    super.select { |dns| dns.dig("metadata", "zone") }
  end

  def subzones
    @client.domain(@namespace).list_all
      .select{ |domain| domain.dig("metadata", "zone") }
      .map { |zone_hash| @client.zone("#{zone_hash["name"]}.#{namespace}") }
  end

  def records
    zone_records = fetch('').select{ |record| record if record.dig("group")&.end_with?("#{@namespace}") }
    subzones.collect(&:namespace).map do |subzone_name|
      zone_records.reject! { |record| record.dig("group")&.end_with?("#{subzone_name}") }
    end
    zone_records.map do |record|
      hostname = record.delete("hostname")
      #record.merge!({"name" => (hostname.split('/').reverse - @namespace.split('.') - [@client.prefix]).reject!(&:empty?).join('.')})
      record.merge!({"name" => hostname.split("/").reverse.reject(&:empty?).join(".").gsub(".#{@namespace}.#{@client.prefix}", "")})
    end
  end

  def delete
    to_remove = []
    results = []
    records.each do |record|
      # delete records in this zone
      record_hostname = "#{record["name"]}.#{@namespace}./#{@client.prefix}".split('.').reverse.join('/')
      to_remove << record_hostname
    end
    zone_name = "#{@namespace}./#{@client.prefix}".split('.').reverse.join('/')
    to_remove << zone_name
    to_remove.each do |name|
      results << remove(name)
    end
    results
  end

  private

  def put(key, value)
    raise ArgumentError.new('Unsupported values keys') unless allowed_values?(value)

    postfix = generate_postfix
    key = "/#{@client.prefix}/#{key.split('.').reverse.join('/')}"
    payload = { key: Base64.encode64(key), value: Base64.encode64(value.to_json) }.to_json
    response = CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/put", :post, {}, payload)
    if response.code == 200
      payload 
    else
      response.code
    end
  end
end
