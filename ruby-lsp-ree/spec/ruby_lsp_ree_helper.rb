module RubyLspReeHelper
  def index_fn(server, name, package = nil)
    location = RubyIndexer::Location.new(0, 0, 0, 0)
    file_uri = if package
      URI("file:///#{package}/package/#{package}/#{name}.rb")
    else
      URI("file:///#{name}.rb")
    end
    
    server.global_state.index.add(RubyIndexer::Entry::Method.new(
      name,
      file_uri,
      location,
      location,
      "ree_object\ntype: :fn",
      [],
      RubyIndexer::Entry::Visibility::PUBLIC,
      nil,
    ))
  end

  def index_class(server, name, uri)
    location = RubyIndexer::Location.new(0, 0, 0, 0)
    
    server.global_state.index.add(RubyIndexer::Entry::Class.new(
      [name],
      uri,
      location,
      location,
      '',
      nil
    ))
  end

  def send_completion_request(server, uri, position)
    server.process_message(
      id: 1,
      method: "textDocument/completion",
      params: {
        textDocument: {
          uri: uri,
        },
        position: position
      }
    )
  end

  def send_definition_request(server, uri, position)
    server.process_message(
      id: 1,
      method: "textDocument/definition",
      params: {
        textDocument: {
          uri: uri,
        },
        position: position
      }
    )
  end

  def send_hover_request(server, uri, position)
    server.process_message(
      id: 1,
      method: "textDocument/hover",
      params: {
        textDocument: {
          uri: uri,
        },
        position: position
      }
    )
  end
end