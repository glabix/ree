# frozen_string_literal: true

class ReeMapper::FilterFieldsContract
  def self.valid?(value)
    return false unless value.is_a? Array

    value.each do |item|
      next if item.is_a? Symbol
      return false unless item.is_a? Hash

      item.each do |key, val|
        return false unless key.is_a?(Symbol)
        return false unless valid?(val)
      end
    end

    true
  end

  def self.to_s
    "FilterFieldsContract"
  end

  def self.message(*)
    "Invalid filter fields contract"
  end
end