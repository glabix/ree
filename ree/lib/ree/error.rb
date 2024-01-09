# frozen_string_literal: true

class Ree::Error < StandardError
  attr_reader :code, :type

  def initialize(message, code = nil, type = nil)
    super(message)
    @type = type
    @code = code
  end
end