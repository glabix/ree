require 'prism'

class RubyLsp::Ree::ParsedLinkNode
  attr_reader :node, :document_package, :name

  FROM_ARG_KEY = 'from'
  IMPORT_ARG_KEY = 'import'

  class ImportItem
    attr_reader :name, :original_name

    def initialize(name:, original_name: nil)
      @name = name
      @original_name = original_name
    end
  end

  def initialize(node, document_package = nil)
    @node = node
    @document_package = document_package
    @name = parse_name
  end

  def link_package_name
    case link_type
    when :object_name
      from_arg_value || document_package
    when :file_path
      @name.split('/').first
    end
  end

  def location
    @node.location
  end

  def from_arg_value
    @kw_args ||= @node.arguments.arguments.detect{ |arg| arg.is_a?(Prism::KeywordHashNode) }
    return unless @kw_args

    @from_param ||= @kw_args.elements.detect{ _1.key.unescaped == FROM_ARG_KEY }
    return unless @from_param

    @from_param.value.unescaped
  end

  def name_arg_node
    @node.arguments.arguments.first
  end

  def link_type
    return @link_type if @link_type
    
    @link_type = case name_arg_node
    when Prism::SymbolNode
      :object_name
    when Prism::StringNode
      :file_path
    else
      nil
    end
  end

  def file_path_type?
    link_type == :file_path
  end

  def object_name_type?
    link_type == :object_name
  end

  def parse_name
    case name_arg_node
    when Prism::SymbolNode
      name_arg_node.value
    when Prism::StringNode
      name_arg_node.unescaped
    else
      ""
    end
  end

  def parse_imports
    @import_items ||= get_import_items
  end

  def imports
    @import_items.map(&:name)
  end

  def has_import_section?
    return false if @node.arguments.arguments.size == 1

    !!import_arg
  end

  def first_arg_location
    @node.arguments.arguments.first.location
  end

  def import_block_open_location
    if object_name_type?
      import_arg.value.opening_loc
    else
      import_arg.opening_loc
    end
  end

  def import_block_close_location
    # TODO maybe use two classes for link types
    if object_name_type?
      import_arg.value.closing_loc
    else
      import_arg.closing_loc
    end
  end

  private

  def last_arg
    @node.arguments.arguments.last
  end

  def import_arg
    if object_name_type?
      last_arg.elements.detect{ _1.key.unescaped == IMPORT_ARG_KEY }
    else
      last_arg
    end
  end

  def get_import_items
    return [] if @node.arguments.arguments.size == 1
    
    if object_name_type?
      return [] unless import_arg
      import_body = import_arg.value.body.body.first
      parse_object_link_multiple_imports(import_body)
    elsif last_arg.is_a?(Prism::LambdaNode)
      return [] unless last_arg.body
      import_body = last_arg.body.body.first
      parse_object_link_multiple_imports(import_body)
    else
      return []
    end
  rescue => e
    $stderr.puts("can't parse imports: #{e.message}")
    return []
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