class HashWithIndifferentAccessCustom
  attr_reader :keys, :values
  
  def initialize(hash = {})
      @attributes = Hash.new
      hash.each { |key, val| self[key] = val }
      @keys = @attributes.keys
      @values = @attributes.values
  end

  def []=(key, value)
      @attributes[key.to_sym] = value
  end

  def [](key)
      @attributes[key.to_sym]
  end

  def self.[](*arr)
      self.new(Hash[*arr])
  end
end