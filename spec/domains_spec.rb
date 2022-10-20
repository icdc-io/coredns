# frozen_string_literal: true

require './spec/shared_params.rb'

RSpec.describe CoreDns::Etcd::Domain do
  include_context 'shared params'

  describe '#add' do
    let(:domain) { coredns.domain(zone_name).add(owner: 'domain_owner') }

    let(:range_body) do
      {
        key: Base64.encode64('/skydns/name/zone/dns/'),
        range_end: Base64.encode64('/skydns/name/zone/dns~')
      }.to_json
    end

    let(:put_body) do
      {
        key: Base64.encode64('/skydns/name/zone/dns/x1'),
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

      expect(WebMock).to have_requested(:post, range_url).with(body: range_body)
    end
  end

  describe '#show' do
    let(:domain) { coredns.domain("x1.domain1.#{zone_name}").show }

    before do
      stub_request(:post, range_url).with(body: range_request_body)
        .to_return(body: show_response_body)
    end

    it 'shows informaiton about appropriate domain' do
      expect(domain['name']).to eq("x1.domain1.#{zone_name}")
    end

    it 'sends a post request to the etcd server' do
      domain

      expect(WebMock).to have_requested(:post, range_url)
        .with(body: range_request_body)
    end
  end

  describe '#delete' do
    let(:returned_value) do
      coredns.domain(zone_name).delete(name: 'x1.domain1')
    end

    let(:request_body) do
      {key: Base64.encode64('/skydns/name/zone/dns/domain1/x1')}.to_json
    end

    before { stub_request(:post, deleterange_url).with(body: request_body) }

    it 'deletes dns domain' do
      expect(returned_value).to eq('/skydns/name/zone/dns/domain1/x1')
    end

    it 'sends a post request to the etcd server' do
      returned_value

      expect(WebMock).to have_requested(:post, deleterange_url)
        .with(body: request_body)
    end
  end
end
