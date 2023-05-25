class ReeDao::EntityContract
  extend Ree::Contracts::Truncatable

  def self.valid?(obj)
    obj.class.ancestors.include?(ReeDto::EntityDSL)
  end

  def self.to_s
    "PackageName::Entity"
  end

  def self.message(value, name, lvl = 1)
    "expected #{to_s}, got => #{truncate(value.inspect)}"
  end
end