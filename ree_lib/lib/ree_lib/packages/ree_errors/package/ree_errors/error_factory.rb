require_relative 'error'

class ReeErrors::ErrorFactory
  class << self
    contract Symbol, String => SubclassOf[ReeErrors::Error]
    def build(code, locale = nil)
      self.new.build(code, locale)
    end
  end

  contract Symbol, String => SubclassOf[ReeErrors::Error]
  def build(code, locale = nil)
    raise NotImplementedError, "should be implemented in derived class"
  end
end