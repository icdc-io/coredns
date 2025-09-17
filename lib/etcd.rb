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
      raise RuntimeError.new "Invalid hostname" unless SimpleIDN.to_unicode(hostname).match?(/\A(?:(?!-)(?!.*--)[а-яА-Яa-zA-Z0-9\-\_]{1,63}\.)+[а-яА-Яa-zA-Z]{2,}\z/)
    end

    CoreDns::Etcd::Domain.new(self, hostname)
  end

  def zone(domain)
    
    unless domain.empty?
      raise RuntimeError.new "Invalid domain" unless SimpleIDN.to_unicode(domain).match?(/\A(?:(?!-)(?!.*--)[а-яА-Яa-zA-Z0-9]{1,63}\.)+[а-яА-Яa-zA-Z]{2,}\z/)
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
