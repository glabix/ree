module ReeDto
  include Ree::PackageDSL

  package do
  end

  def self.enable_strict_mode
    @strict_mode = true
  end

  def self.strict_mode?
    !!@strict_mode
  end
end

require_relative 'ree_dto/entity_dsl'