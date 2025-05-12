class Ree::ClassUtils
  def self.eigenclass_of(target)
    class << target
      self
    end
  end
end
