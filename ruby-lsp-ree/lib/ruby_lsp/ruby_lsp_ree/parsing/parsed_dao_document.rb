class RubyLsp::Ree::ParsedDaoDocument < RubyLsp::Ree::ParsedClassDocument
  include RubyLsp::Ree::ReeLspUtils

  attr_reader :dao_fields, :filters

  class DaoField
    attr_reader :name, :location, :type, :default

    def initialize(name:, location:, type:, default:)
      @name = name
      @location = location
      @type = type
      @default = default
    end

    def has_default?
      !!@default
    end
  end

  def initialize(ast, package_name = nil)
    super
    parse_filters
    parse_dao_fields
  end

  private 

  def parse_dao_fields
    return unless has_body?
   
    schema_node = class_node.body.body
      .detect{ |node| node.is_a?(Prism::CallNode) && node.name == :schema }

    @dao_fields ||= schema_node.block.body.body.map do |node|
      field_type = node.name.to_s.capitalize
      default_val = nil

      if field_allows_null?(node)
        field_type = "Nilor[#{field_type}]"  
        default_val = "nil"
      end

      DaoField.new(
        name: node.arguments.arguments.first.unescaped,
        location: node.location,
        type: field_type,
        default: default_val
      )
    end
  end

  def parse_filters
    return unless has_body?
    
    @filters ||= class_node.body.body
      .select{ node_name(_1) == :filter }
      .map{ OpenStruct.new(name: _1.arguments.arguments.first.unescaped, signatures: parse_filter_signature(_1)) }
  end

  def field_allows_null?(node)
    kw_node = node.arguments.arguments.detect{ _1.is_a?(Prism::KeywordHashNode) }
    return false unless kw_node
    
    null_el = kw_node.elements.detect{ _1.key.unescaped == "null" }
    return false unless null_el

    null_el.value.is_a?(Prism::TrueNode)
  end
end