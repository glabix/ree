module ReeDto
  include Ree::PackageDSL

  package

  def self.enable_test_mode
    @test_mode = true
  end

  def self.test_mode
    @test_mode
  end
end

require_relative 'ree_dto/entity_dsl'