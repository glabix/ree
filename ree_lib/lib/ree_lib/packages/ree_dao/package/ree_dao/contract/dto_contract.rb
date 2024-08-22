# frozen_string_literal: true
class ReeDao::DtoContract
  extend Ree::Contracts::Truncatable

  def self.valid?(obj)
    obj.class.ancestors.include?(ReeDto::DSL)
  end

  def self.to_s
    "ReeDto::Dto"
  end

  def self.message(value, name, lvl = 1)
    "expected #{to_s}, got => #{truncate(value.inspect)}"
  end
end