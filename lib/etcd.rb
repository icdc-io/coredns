# frozen_string_literal: true

require "base64"
require "json"
require "logger"
require "simpleidn"

class CoreDns::Etcd
  attr_reader :api_url, :prefix, :postfix

  def initialize(url = nil)
    @logger = Logger.new($stdout)

    initialize_params
    @api_url = "http://#{url}:#{@port}/#{@version}"
    @endpoint = url
  end

  def domain(hostname)
    unless hostname.empty?
      raise RuntimeError.new "Invalid hostname" unless SimpleIDN.to_unicode(hostname).match?(/\A(?:(?!-)(?!.*--)[\p{L}\p{N}_][\p{L}\p{N}\-\_]{0,62}\.)+[\p{L}]{2,}\z/)
    end

    CoreDns::Etcd::Domain.new(self, hostname)
  end

  def zone(domain)
    
    unless domain.empty?
      raise RuntimeError.new "Invalid domain" unless SimpleIDN.to_unicode(domain).match?(/\A(?:(?!-)(?!.*--)[\p{L}\p{N}-]{1,63}\.)+[\p{L}]{2,}\z/)
    end

    CoreDns::Etcd::DnsZone.new(self, domain)
  end

  private

  def initialize_params
    @prefix = ENV["COREDNS_PREFIX"] || "skydns"
    @postfix = ENV["COREDNS_POSTFIX"] || "x"
    @port = ENV["COREDNS_PORT"] || 2379
    @version = ENV["COREDNS_VERSION"] || "v3"
  end
end
