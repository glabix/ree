# frozen_string_literal: true

class ReeHash::HashKeysContract
  extend Ree::Contracts::Truncatable

  def self.valid?(obj)
    return false if !obj.is_a?(Array)
    return false if obj.any? { !valid_item?(_1) }
    true
  end

  def self.to_s
    "[:key0, .., :keyM => [:keyN, .., :keyZ]]"
  end

  def self.message(value, name, lvl = 1)
    "expected #{to_s}, got => #{truncate(value.inspect)}"
  end

  private

  def self.valid_item?(obj)
    return true if obj.is_a?(Symbol)
    return false if !obj.is_a?(Hash)  

    obj.each do |k, v|
      return false if !k.is_a?(Symbol)
      return false if !v.is_a?(Array)
      return false if v.any? { !valid_item?(_1) }
    end

    true
  end
end