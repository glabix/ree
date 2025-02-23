module RubyLspReeHelper
  def index_fn(server, name)
    location = RubyIndexer::Location.new(0, 0, 0, 0)
    file_uri = URI("file:///fake.rb")
    
    server.global_state.index.add(RubyIndexer::Entry::Method.new(
      'seconds_ago',
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
end