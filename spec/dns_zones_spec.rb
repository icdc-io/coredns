# frozen_string_literal: true

require './spec/shared_params.rb'

RSpec.describe CoreDns::Etcd::DnsZone do
  include_context 'shared params'

  let(:zone_name) { 'dns.zone.name' }
  let(:owner_name) { 'owner_name' }
  let(:metadata) { {owner: owner_name} }
  let(:params) { {metadata: metadata} }

  describe '#list' do
    let(:zones) { coredns.zone('').list }

    before do
      stub_request(:post, range_url).with(body: range_request_body)
        .to_return(body: show_response_body)
    end

    it 'lists DNS zones' do
      expect(zones.count).to eq(4)
    end

    it "sends a post request to the etcd server" do
      zones 

      expect(WebMock).to have_requested(:post, range_url)
    end
  end

  describe '#add' do
    let(:zone) { coredns.zone(zone_name).add(params) }
    before { stub_request(:post, put_url) }

    it 'adds a new DNS zone' do
      key = "/skydns/#{zone_name.split('.').reverse.join('/')}"
      value = params
      value[:metadata].merge!(zone: true)
      encoded_key = Base64.encode64 key
      encoded_value = Base64.encode64 value.to_json
      expected_result = {key: encoded_key, value: encoded_value}.to_json

      expect(zone).to eq(expected_result)
    end

    it 'sends a post request to the etcd server' do
      zone

      expect(WebMock).to have_requested(:post, put_url)
    end
  end

  describe '#show' do
    let(:zone) { coredns.zone(zone_name).show }

    before do
      stub_request(:post, range_url).with(body: range_request_body)
        .to_return(body: show_response_body)
    end

    it 'shows information about selected DNS zone' do
      expected_response = params
      expected_response[:name] = zone_name
      expected_response[:metadata][:zone] = true

      expect(JSON.generate(zone)).to eq(JSON.generate(expected_response))
    end

    it 'returns nil if there is no appropriate DNS zone' do
      zone = coredns.zone('some.unexisted.zone.name').show

      expect(zone).to eq(nil)
    end

    it 'sends a post request to the etcd server' do
      zone

      expect(WebMock).to have_requested(:post, range_url)
    end
  end

  describe '#delete' do
    let(:deleterange_body) do
      {key: Base64.encode64('/skydns/name/zone/dns')}.to_json
    end

    let(:range_body) do
      {
        key: Base64.encode64('/skydns/name/zone/dns/'),
        range_end: Base64.encode64('/skydns/name/zone/dns~')
      }.to_json
    end

    before do
      stub_request(:post, range_url).with(body: range_body)
      stub_request(:post, deleterange_url).with(body: deleterange_body)
    end

    before { @returned_value = coredns.zone(zone_name).delete } # change to let

    it 'removes specified DNS zone' do
      expected_value = ["/skydns/#{zone_name.split('.').reverse.join('/')}"]

      expect(@returned_value).to eq(expected_value)
    end

    it "sends a post request to the etcd server twice" do
      expect(WebMock).to have_requested(:post, range_url)
        .with(body: range_body).twice
    end

    it "sends a post request to the etcd server" do
      expect(WebMock).to have_requested(:post, deleterange_url)
        .with(body: deleterange_body)
    end
  end

  describe '#subzones' do
    let(:subzones) { coredns.zone(zone_name).subzones }

    let(:request_body) do
      {
        key: Base64.encode64('/skydns/name/zone/dns/'),
        range_end: Base64.encode64('/skydns/name/zone/dns~')
      }.to_json
    end

    let(:response_body) do
      File.open('spec/fixtures/subzones_response_body.json')
    end

    before do
      stub_request(:post, range_url).with(body: request_body)
        .to_return(body: response_body.read)
    end

    it 'returns list of subzones' do
      expect(subzones.count).to eq(3)
    end

    it "sends a post request to the etcd server" do
      subzones

      expect(WebMock).to have_requested(:post, range_url)
        .with(body: request_body)
    end
  end

  describe '#parent_zone' do
    let(:zone) { coredns.zone("foo.bar.#{zone_name}").parent_zone }

    let(:response_body) do
      File.open('spec/fixtures/subzones_response_body.json')
    end

    before do
      stub_request(:post, range_url).with(body: range_request_body)
        .to_return(body: response_body.read)
    end

    it 'returns parent DNS zone' do
      expect(zone.namespace).to eq("bar.#{zone_name}")
    end

    it 'sends a post request to the etcd server' do
      zone 

      expect(WebMock).to have_requested(:post, range_url)
        .with(body: range_request_body)
    end
  end
end
