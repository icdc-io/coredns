# frozen_string_literal: true
require 'rest_client'
module CoreDns
  module Helpers
    class RequestHelper
      def self.request(url, method, params = {}, payload = {})
        params = { url: url, method: method,  headers: params }
        params[:payload] = payload if %i[post put].include?(method)
        params[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
        RestClient::Request.execute(params)
      end
    end
  end
end
