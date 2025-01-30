class ReeFormatter
  include RubyLsp::Requests::Support::Formatter
  include RubyLsp::Ree::ReeLspUtils

  def initialize
  end

  def run_formatting(uri, document)
    $stderr.puts("run_formating")

    source = document.source
    sort_links(source)
  end

  private

  def sort_links(source)
    doc_info = parse_document_from_source(source)
  
    return source unless doc_info.fn_node
    return source if doc_info.fn_node && !doc_info.block_node
    
    if doc_info.link_nodes.size < doc_info.block_node.body.body.size
      $stderr.puts("block contains not only link, don't sort")
      return source
    end

    if doc_info.link_nodes.any?{ _1.location.start_line != _1.location.end_line }
      $stderr.puts("multiline link definitions, don't sort")
      return source
    end

    # sort link nodes
    sorted_link_nodes = doc_info.link_nodes.sort{ |a, b|
      a_name = a.arguments.arguments.first
      b_name = b.arguments.arguments.first
      
      if a_name.is_a?(Prism::SymbolNode) && !b_name.is_a?(Prism::SymbolNode)
        -1
      elsif b_name.is_a?(Prism::SymbolNode) && !a_name.is_a?(Prism::SymbolNode)
        1
      else
        a_name.unescaped <=> b_name.unescaped
      end
    }
      
    # check if no re-order
    if doc_info.link_nodes.map{ _1.arguments.arguments.first.unescaped } == sorted_link_nodes.map{ _1.arguments.arguments.first.unescaped }
      return source
    end

    # insert nodes to source
    link_lines = doc_info.link_nodes.map{ _1.location.start_line }

    source_lines = source.lines

    sorted_lines = sorted_link_nodes.map do |sorted_link|
      source_lines[sorted_link.location.start_line - 1]
    end

    link_lines.each_with_index do |link_line, index|
      source_lines[link_line - 1] = sorted_lines[index]
    end

    source_lines.join()
  end
end