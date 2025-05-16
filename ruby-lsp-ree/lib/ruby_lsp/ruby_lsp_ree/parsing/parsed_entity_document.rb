class RubyLsp::Ree::ParsedEntityDocument < RubyLsp::Ree::ParsedClassDocument
  include RubyLsp::Ree::ReeLspUtils

  attr_reader :columns, :build_dto_node

  class EntityField
    attr_reader :name, :location

    def initialize(name:, location:)
      @name = name
      @location = location
    end
  end

  def initialize(ast, package_name = nil)
    super
    parse_class_includes
    parse_build_dto_structure
  end

  private 

  def parse_build_dto_structure
    @columns = []
    @build_dto_node = nil

    return unless has_body?

    @build_dto_node = @class_node.body.body.detect{ node_name(_1) == :build_dto }
    return unless @build_dto_node.block.body

    @columns = @build_dto_node.block.body.body
      .select{ _1.name == :column }
      .map do 
        EntityField.new(
          name: _1.arguments.arguments.first.unescaped,
          location: _1.location
        )
      end
  end
end