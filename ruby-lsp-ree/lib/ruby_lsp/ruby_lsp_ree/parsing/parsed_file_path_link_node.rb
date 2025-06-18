require_relative 'parsed_link_node'

class RubyLsp::Ree::ParsedFilePathLinkNode < RubyLsp::Ree::ParsedLinkNode
  def link_package_name
    @name.split('/').first
  end

  def link_type
    :file_path
  end

  def file_path_type?
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
    name_arg_node.unescaped
  end

  def parse_linked_objects
    @linked_objects = []
  end

  def import_arg
    last_arg
  end

  def get_import_items
    return [] unless has_import_section?
    
    if last_arg.is_a?(Prism::LambdaNode)
      return [] unless last_arg.body
      import_body = last_arg.body.body.first
      parse_object_link_multiple_imports(import_body)
    else
      return []
    end
  end
end