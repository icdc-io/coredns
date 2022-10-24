module CoreDns
  module Helpers
    class PutRequest
      VALUES_WHITELIST = %w[host mail port priority text ttl group].freeze # TODO change for a specific classes
    
      def self.put(key, value, client)
        raise ArgumentError, "Unsupported values keys" unless (value.keys - VALUES_WHITELIST).empty? ? false : true
    
        payload = { key: Base64.encode64(key), value: Base64.encode64(value.to_json) }.to_json
        response = CoreDns::Helpers::RequestHelper.request("#{client.api_url}/kv/put", :post, {}, payload)
        if response.code == 200
          payload
        else
          response.code
        end
      end
    end
  end
end
