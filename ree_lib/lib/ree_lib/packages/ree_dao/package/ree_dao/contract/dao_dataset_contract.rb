class ReeDao::DaoDatasetContract
  extend Ree::Contracts::Truncatable

  def self.valid?(obj)
    obj.class.ancestors.include?(ReeDao::DatasetExtensions::InstanceMethods)
  end

  def self.to_s
    "PackageName::DaoName::Dao: \"SELECT * FROM `table`\""
  end

  def self.message(value, name, lvl = 1)
    "expected #{to_s}, got => #{truncate(value.inspect)}"
  end
end