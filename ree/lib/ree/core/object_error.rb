# frozen_string_literal: true

class Ree::ObjectError
  attr_reader :class_name

  def initialize(class_name)
    @class_name = class_name
  end
end