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
