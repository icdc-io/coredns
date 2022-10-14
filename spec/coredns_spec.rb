# frozen_string_literal: true

require './spec/shared_params.rb'

RSpec.describe CoreDns::Etcd do
  include_context 'shared params'

  describe '::new' do
    it 'creates a connection object' do # TODO Default params ENV
      expect(coredns.class).to eq(CoreDns::Etcd) # eq(described_class)
    end
  end
end
