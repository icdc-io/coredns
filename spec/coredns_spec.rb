# frozen_string_literal: true

require './spec/shared_params.rb'

RSpec.describe CoreDns::Etcd do
  include_context 'shared params'

  describe '::new' do
    it 'creates a connection object' do
      expect(coredns.class).to eq(described_class)
    end

    it 'creates a connection object with default params' do
      default_params = coredns.api_url.split(':')[-1].split('/')
      default_params << coredns.prefix << coredns.postfix

      expect(default_params).to eq(['2379', 'v3', 'skydns', 'x'])
    end

    it 'creates a connection object with custom params' do
      ENV['COREDNS_PORT']    = port    = '9732'
      ENV['COREDNS_VERSION'] = version = 'v5'
      ENV['COREDNS_PREFIX']  = prefix  = 'sky'
      ENV['COREDNS_POSTFIX'] = postfix = 'y'

      custom_params = coredns.api_url.split(':')[-1].split('/')
      custom_params << coredns.prefix << coredns.postfix

      ENV['COREDNS_PORT'] = ENV['COREDNS_VERSION'] =
        ENV['COREDNS_PREFIX'] = ENV['COREDNS_POSTFIX'] = nil

      expect(custom_params).to eq([port, version, prefix, postfix])
    end
  end
end
