require_relative 'parsed_link_node'

class RubyLsp::Ree::ParsedObjectLinkNode < RubyLsp::Ree::ParsedLinkNode
  def multi_object_link?
    @linked_objects.size > 1
  end

  def link_package_name
    from_arg_value || document_package
  end

  def link_type
    :object_name
  end

  def object_name_type?
    true
  end

  def import_block_open_location
    import_arg.value.opening_loc
  end

  def import_block_close_location
    import_arg.value.closing_loc
  end

  private

  def parse_name
    name_arg_node.value
  end

  def parse_linked_objects
    @linked_objects = @node.arguments.arguments.select{ _1.is_a?(Prism::SymbolNode) }.map do |arg|
      LinkedObject.new(name: arg.unescaped, alias_name: @alias_name, location: arg.location)
    end
  end

  def import_arg
    return unless @kw_args
    @kw_args.elements.detect{ _1.key.unescaped == IMPORT_ARG_KEY }
  end

  def get_import_items
    return [] unless has_import_section?
    
    import_body = import_arg.value.body.body.first
    parse_object_link_multiple_imports(import_body)
  end
end