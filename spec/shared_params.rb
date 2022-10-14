RSpec.shared_context 'shared params' do
  # creating a connection object
  let(:etcd_url) { 'etcd.server.url.example' }
  let(:coredns) { CoreDns::Etcd.new(etcd_url) }

  let(:range_url) { 'http://etcd.server.url.example:2379/v3/kv/range' }
  let(:put_url) { 'http://etcd.server.url.example:2379/v3/kv/put' }

  let(:deleterange_url) do
    'http://etcd.server.url.example:2379/v3/kv/deleterange'
  end

  let(:range_request_body) do
    {
      key: Base64.encode64('/skydns//'),
      range_end: Base64.encode64('/skydns/~')
    }.to_json
  end

  let(:show_response_body) do
    File.open('./spec/fixtures/show_response_body.json') 
  end
end
