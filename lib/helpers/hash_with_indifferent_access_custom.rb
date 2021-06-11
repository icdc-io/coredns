class HashWithIndifferentAccessCustom
  def initialize(hash = {})
      @attributes = Hash.new
      hash.each { |key, val| self[key] = val }
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