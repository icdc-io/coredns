# frozen_string_literal: true

require "rest_client"

class Request
  def self.put(key, value, client, values_whitelist)
    raise ArgumentError, "Unsupported values keys" unless (value.keys - values_whitelist).empty? ? false : true

    value = HashWithIndifferentAccessCustom.new(value).attributes.to_json
    payload = {
      key: Base64.encode64(key),
      value: Base64.encode64(value)
    }.to_json
    response = request("#{client.api_url}/kv/put", :post, {}, payload)
    response.code == 200 ? payload : response.code
  end

  def self.remove(hostname, client, logger)
    payload = { key: Base64.encode64(hostname) }.to_json
    response = request("#{client.api_url}/kv/deleterange", :post, {}, payload)
    response.code == 200 ? hostname : response.code
  rescue StandardError => e
    logger.error(e.message)
  end

  def self.fetch(hostname, namespace, client)
    unless namespace == hostname
      hostname =
        [hostname, namespace.split(".")].flatten.compact.join(".")[1..]
    end

    prefix = client.prefix
    key = "/#{prefix}/#{hostname.split(".").reverse.join("/")}/"
    range_end = "/#{prefix}/#{hostname.split(".").reverse.join("/")}~"

    payload = {
      key: Base64.encode64(key),
      range_end: Base64.encode64(range_end)
    }.to_json

    response = request("#{client.api_url}/kv/range", :post, {}, payload)
    parsed_response(response)
  rescue StandardError
    []
  end

  private_class_method def self.parsed_response(response)
    JSON.parse(response)["kvs"].map do |encoded_hash|
      [
        { "hostname" => Base64.decode64(encoded_hash["key"]) },
        JSON.parse(Base64.decode64(encoded_hash["value"]))
      ].reduce({}, :merge)
    rescue StandardError
      next
    end.compact
  end

  private_class_method def self.request(url, method, params = {}, payload = {})
    params = { url: url, method: method,  headers: params }
    params[:payload] = payload if %i[post put].include?(method)
    params[:verify_ssl] = OpenSSL::SSL::VERIFY_NONE
    RestClient::Request.execute(params)
  end
end
