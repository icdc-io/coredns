class HashWithIndifferentAccessCustom
  attr_reader :keys, :values, :attributes
  
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

  def delete(key)
    @attributes.delete(key)
    self.class.new(@attributes)
  end

  def to_json
    @attributes.to_json
  end
end