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
end
