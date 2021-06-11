require 'logger'
require_relative '../helpers/hash_with_indifferent_access_custom'
require_relative '../helpers/request_helper'

class CoreDns::Etcd::Domain < CoreDns::Domain
  class Error < StandardError; end

  VALUES_WHITELIST = %w[host mail port priority text ttl group].freeze

  def delete(data = {})
    data = HashWithIndifferentAccessCustom.new(data)
    hostname = nil
    if data[:hostname]
      hostname = data[:hostname]
    elsif data[:host]
      hostname = list.select { |record| record["host"] == data[:host] }[0]["hostname"]
    end

    remove(hostname) if hostname
  end

  def get(hostname)
    self.class.new(@client, "#{hostname}.#{@namespace}")
  end

  def add(data = {})
    put(@namespace, HashWithIndifferentAccessCustom.new(data))
  end

  def list(level = 1)
    one_level_records = []
    fetch('').each do |record|
      levels_difference = (record["hostname"].sub("/#{@client.prefix}/#{@namespace.split('.').reverse.join('/')}",
                                                  '')).split('/')[1..-1]
      if levels_difference.count == level
        one_level_records << record
      end
    end
    one_level_records
  end

  def list_all
    fetch('')
  end

  private

  def allowed_values?(data)
    (data.keys - VALUES_WHITELIST).empty? ? true : false
  end

  def generate_postfix
    postfixes = list.collect do |record|
                  record['hostname']
                end.map { |key| key.split('/').last }
    if postfixes.empty?
      "#{@client.postfix}1"
    else
      ((1..postfixes.count + 1).map { |i| "#{@client.postfix}#{i + 1}" } - postfixes).first
    end
  end

  def fetch(hostname)
    hostname = [hostname, @namespace.split('.')].flatten.compact.join('.')[1..-1] unless @namespace == hostname
    payload = {
      key: Base64.encode64("/#{@client.prefix}/#{hostname.split('.').reverse.join('/')}/"),
      range_end: Base64.encode64("/#{@client.prefix}/#{hostname.split('.').reverse.join('/')}~")
    }.to_json
    response = CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/range", :post, {}, payload)
    JSON.parse(response)['kvs']
        .map do |encoded_hash|
      [{ 'hostname' => Base64.decode64(encoded_hash['key']) }, JSON.parse(Base64.decode64(encoded_hash['value']))]
        .reduce(
          {}, :merge
        )
    rescue StandardError
      next
    end.compact
  rescue StandardError
    []
  end

  def put(key, value)
    raise ArgumentError, 'Unsupported values keys' unless allowed_values?(value)

    postfix = generate_postfix
    key = "/#{@client.prefix}/#{key.split('.').reverse.join('/')}/#{postfix}"
    (value.keys - VALUES_WHITELIST).each { |k| value.delete(k) }
    payload = { key: Base64.encode64(key), value: Base64.encode64(value.to_json) }.to_json
    CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/put", :post, {}, payload)
  end

  def remove(hostname)
    payload = {
      key: Base64.encode64(hostname)
    }.to_json
    CoreDns::Helpers::RequestHelper.request("#{@client.api_url}/kv/deleterange", :post, {}, payload)
  rescue StandardError => e
    @logger.error(e.message)
  end
end
