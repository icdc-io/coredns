# frozen_string_literal: true

require './spec/shared_params.rb'

RSpec.describe CoreDns::Etcd::Domain do
  include_context 'shared params'

  describe '#add' do
    let(:domain) do
      coredns.domain('domain1.dns.zone').add(owner: 'domain_owner')
    end

    let(:range_body) do
      {
        key: Base64.encode64('/skydns/zone/dns/domain1/'),
        range_end: Base64.encode64('/skydns/zone/dns/domain1~')
      }.to_json
    end

    let(:put_body) do
      {
        key: Base64.encode64('/skydns/zone/dns/domain1/x1'),
        value: Base64.encode64("{\"owner\":\"domain_owner\"}")
      }.to_json
    end

    before do
      stub_request(:post, range_url).with(body: range_body)
      stub_request(:post, put_url).with(body: put_body)
    end
      
    it 'creates a new domain' do
      expect(domain).to eq(put_body)
    end

    it 'sends a post request to the etcd server' do
      domain

      expect(WebMock).to have_requested(:post, put_url).with(body: put_body)
    end

    it 'sends a post request to the etcd server' do
      domain

      expect(WebMock).to have_requested(:post, range_url)
        .with(body: range_body)
    end
  end

  describe '#show' do
    let(:domain) { coredns.domain('x1.domain1.dns.zone').show }

    before do
      stub_request(:post, range_url).with(body: range_request_body)
        .to_return(body: show_response_body)
    end

    it 'shows informaiton about appropriate domain' do
      expect(domain['name']).to eq('x1.domain1.dns.zone') 
    end

    it 'sends a post request to the etcd server' do
      domain

      expect(WebMock).to have_requested(:post, range_url)
        .with(body: range_request_body)
    end
  end

  describe '#delete' do
    it 'deletes dns domain'
  end
end
