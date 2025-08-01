require_relative 'parsed_link_node'

class RubyLsp::Ree::ParsedImportLinkNode < RubyLsp::Ree::ParsedLinkNode
  def link_package_name
    from_arg_value || document_package
  end

  def link_type
    :import_link
  end

  def import_link_type?
    true
  end

  def import_block_open_location
    import_arg.opening_loc
  end

  def import_block_close_location
    import_arg.closing_loc
  end

  private

  def parse_name
    ''
  end

  def parse_linked_objects
    @linked_objects = []
  end

  def import_arg
    @node.arguments.arguments.detect{ _1.is_a?(Prism::LambdaNode) }
  end

  def get_import_items
    return [] unless has_import_section?
    
    import_body = import_arg.body.body.first
    parse_object_link_multiple_imports(import_body)
  end
end