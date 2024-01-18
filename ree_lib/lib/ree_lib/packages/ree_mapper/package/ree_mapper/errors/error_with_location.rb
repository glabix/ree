# frozen_string_literal: true

class ReeMapper::ErrorWithLocation < ReeMapper::Error
  attr_reader :location

  def initialize(message, location = nil)
    super(message)
    @location = location
  end

  def full_message(...)
    msg = super
    return msg if location.nil?

    idx = msg.index(/\).*\n/)
    return msg if idx.nil?
    
    msg.insert(idx + 1, "\nlocated at #{location}")
  end
end
