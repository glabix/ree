# frozen_string_literal: true

class Ree::PackageDep
  attr_reader :name

  def initialize(name)
    @name = name
  end
end