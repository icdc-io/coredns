require 'base64'
require 'json'
require 'logger'

class CoreDns::Etcd
  attr_reader :api_url, :prefix, :postfix

  def initialize(url = nil)
    @logger = Logger.new(STDOUT)

    initialize_params
    @api_url = "http://#{url}:#{@port}/#{@version}"
    @endpoint = url
  end

  def domain(hostname)
    CoreDns::Etcd::Domain.new(self, hostname)
  end

  private

  def initialize_params
    @prefix = ENV['COREDNS_PREFIX'] || 'skydns'
    @postfix = ENV['COREDNS_POSTFIX'] || 'x'
    @port = ENV['COREDNS_PORT'] || 2379
    @version = ENV['COREDNS_VERSION'] || 'v3beta'
  end
end
