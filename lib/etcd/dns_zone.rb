require_relative '../helpers/hash_with_indifferent_access_custom'
require_relative '../helpers/request_helper'

class CoreDns::Etcd::DnsZone < CoreDns::Etcd::Domain # CoreDns::Domain
  VALUES_WHITELIST = %w[host metadata].freeze 

  def add(data = {})
    data[:metadata] = {:zone => true, "owner" => data.delete(:owner), "account" => data.delete(:account)}
    return "need to add {:host =>}" unless data[:host]
    put( @namespace, HashWithIndifferentAccessCustom.new(data).attributes)
  end


  def list
    fetch('').select { |dns| dns["hostname"] == "/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}/dns/apex" }
  end

  def list_all
    fetch('').select { |dns| dns.dig("metadata", "zone") }
  end
  
 private

 def put(key, value)
    raise ArgumentError.new('Unsupported values keys') unless allowed_values?(value)

    key = "/#{@client.prefix}/#{key.split('.').reverse.join('/')}/dns/apex"
    payload = { key: Base64.encode64(key), value: Base64.encode64(value.to_json) }.to_json
    response = CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/put", :post, {}, payload)
    if response.code == 200
      payload
    else
      response.code
    end
 end

  def allowed_values?(data)
    (data.keys - VALUES_WHITELIST).empty? ? false : true
  end
end
