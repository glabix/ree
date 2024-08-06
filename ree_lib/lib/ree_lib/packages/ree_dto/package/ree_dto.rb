module ReeDto
  include Ree::PackageDSL

  package do
    depends_on :ree_object
  end

  class << self
    def set_debug_mode
      @debug_mode = true
    end

    def debug_mode?
      !!@debug_mode
    end
  end
end

require_relative 'ree_dto/entity_dsl'
require_relative 'ree_dto/dsl'