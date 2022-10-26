# frozen_string_literal: true

class PutRequest
  VALUES_WHITELIST = %w[host mail port priority text ttl group].freeze # TODO: change for a specific classes (as an argument for put method)

  def self.put(key, value, client)
    raise ArgumentError, "Unsupported values keys" unless (value.keys - VALUES_WHITELIST).empty? ? false : true

    value = HashWithIndifferentAccessCustom.new(value).attributes.to_json
    payload = {
      key: Base64.encode64(key),
      value: Base64.encode64(value)
    }.to_json
    response = CoreDns::Helpers::RequestHelper.request("#{client.api_url}/kv/put", :post, {}, payload)
    response.code == 200 ? payload : response.code
  end
end
