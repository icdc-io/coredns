# frozen_string_literal: true

module CoreDns
  class Domain
    attr_reader :namespace

    def initialize(client, hostname = "")
      @namespace = hostname
      @client = client
    end

    def get
      raise NotImplementedError, ".get must be implemented in a subclass"
    end

    def add(_values = {})
      raise NotImplementedError, ".add must be implemented in a subclass"
    end
  end
end
