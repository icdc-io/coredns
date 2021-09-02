require_relative '../helpers/hash_with_indifferent_access_custom'
require_relative '../helpers/request_helper'

class CoreDns::Etcd::DnsZone < CoreDns::Etcd::Domain # CoreDns::Domain
  VALUES_WHITELIST = %w[metadata].freeze 

  def add(data = {})
    data[:imetadata][:zone] = true
    put(@namespace, HashWithIndifferentAccessCustom.new(data).attributes)
  end

  def list(level = 1)
    super.select { |record| record.dig("metadata", "zone") }
  end

  def list_all
    super.select { |dns| dns.dig("metadata", "zone") }
  end

  def list_subzones
    result = []
    fetch('').each do |record|
     metadata_element = record.dig("metadata", "zone")
     subzone_exists = record["hostname"].include?("/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}/") && !metadata_element.nil?  && (metadata_element == true)
      test ="/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}/"
     subzone_data   = record["hostname"].split('/').reverse.join('.')[0..-2]
     result << subzone_data if subzone_exists
    end
    result
  end

  def list_records
    result = []
    one_level_records = []
    fetch('').each do |record|
      levels_difference = (record["hostname"].sub("/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}/",
                                                  '')).split('/')
      test = record["hostname"].sub("/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}/",'')
      if levels_difference.count == 1
        one_level_records << record
      end
    end
    one_level_records.map do |record|
     result << record unless record.dig("metadata", "zone")
    end
    result.map do |record|
      hostname = record.delete("hostname")
      record.merge!({"name" => (hostname.split('/').reverse - @namespace.split('.') - [@client.prefix]).reject!(&:empty?).join('.')})
    end
  end

  def delete(data = {})
    hosts = []
    results = []
    list_records.each do |record|
      # delete records in this zone
      record_hostname = "#{record["name"]}.#{@namespace}./#{@client.prefix}".split('.').reverse.join('/')
      hosts << record_hostname
    end
    hostname = "#{@namespace}./#{@client.prefix}".split('.').reverse.join('/')
    hosts << hostname
    hosts.each do |name|
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
