require 'prism'

class RubyLsp::Ree::ParsedLinkNode
  attr_reader :node, :document_package, :name, :import_items, :from_param, :linked_objects

  FROM_ARG_KEY = 'from'
  IMPORT_ARG_KEY = 'import'
  AS_ARG_KEY = 'as'

  class ImportItem
    attr_reader :name, :original_name

    def initialize(name:, original_name: nil)
      @name = name
      @original_name = original_name
    end

    def to_s
      if @original_name
        "#{@original_name}.as(#{@name})"
      else
        @name
      end
    end
  end

  class LinkedObject
    attr_reader :name, :alias_name, :location

    def initialize(name:, alias_name:, location:)
      @name = name
      @alias_name = alias_name
      @location = location
    end

    def usage_name
      return @alias_name if @alias_name
      @name
    end
  end

  def initialize(node, document_package = nil)
    @node = node
    @document_package = document_package
    @name = parse_name

    parse_params
    parse_linked_objects
  end

  def multi_object_link?
    false
  end

  def link_package_name
    raise "abstract method"
  end

  def location
    @node.location
  end

  def usage_name
    return @alias_name if @alias_name
    @name
  end

  def from_arg_value
    return unless @from_param
    @from_param.value.respond_to?(:unescaped) ? @from_param.value.unescaped : nil
  end

  def name_arg_node
    @node.arguments.arguments.first
  end

  def link_type
    raise "abstract method"
  end

  def file_path_type?
    false
  end

  def object_name_type?
    false
  end

  def parse_imports
    @import_items ||= get_import_items
  end

  def imports
    @import_items.map(&:name)
  end

  def has_import_section?
    !!import_arg
  end

  def first_arg_location
    @node.arguments.arguments.first.location
  end

  def import_block_open_location
    raise "abstract method"
  end

  def import_block_close_location
    raise "abstract method"
  end

  private

  def parse_name
    raise "abstract method"
  end

  def parse_params
    @kw_args = @node.arguments.arguments.detect{ |arg| arg.is_a?(Prism::KeywordHashNode) }
    @from_param = nil
    return unless @kw_args

    @from_param = @kw_args.elements.detect{ _1.key.unescaped == FROM_ARG_KEY }
    @as_param = @kw_args.elements.detect{ _1.key.unescaped == AS_ARG_KEY }
    @alias_name = @as_param ? @as_param.value.unescaped : nil
  end

  def parse_linked_objects
    raise "abstract method"
  end

  def import_arg
    raise "abstract method"
  end

  def get_import_items
    raise "abstract method"
  end

  def parse_object_link_multiple_imports(import_body)
    if import_body.is_a?(Prism::CallNode) && import_body.name == :&
      parse_object_link_multiple_imports(import_body.receiver) + parse_object_link_multiple_imports(import_body.arguments.arguments.first)
    elsif import_body.is_a?(Prism::CallNode) && import_body.name == :as
      [
        ImportItem.new(
          name: import_body.arguments.arguments.first.name.to_s,
          original_name: import_body.receiver.name.to_s
        )
      ]
    else 
      [ ImportItem.new(name: import_body.name.to_s) ]
    end
  end
end