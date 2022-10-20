RSpec.shared_context 'shared params' do
  # creating a connection object
  let(:etcd_url) { 'etcd.server.url.example' }
  let(:coredns) { CoreDns::Etcd.new(etcd_url) }

  let(:zone_name) { 'dns.zone.name' }
  let(:put_url) { "#{coredns.api_url}/kv/put" }
  let(:range_url) { "#{coredns.api_url}/kv/range" }
  let(:deleterange_url) { "#{coredns.api_url}/kv/deleterange" }

  let(:range_request_body) do
    {
      key: Base64.encode64("/#{coredns.prefix}//"),
      range_end: Base64.encode64("/#{coredns.prefix}/~")
    }.to_json
  end

  let(:show_response_body) do
    File.open('./spec/fixtures/show_response_body.json') 
  end
end
