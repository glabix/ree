module RubyLspReeHelper
  def index_fn(server, name, package = nil, uri = nil)
    index_ree_object(server, name, :fn, package, uri)
  end

  def index_ree_object(server, name, type, package = nil, uri = nil)
    location = RubyIndexer::Location.new(0, 0, 0, 0)
    file_uri = if uri
      uri
    elsif package
      URI("file:///#{package}/package/#{package}/#{name}.rb")
    else
      URI("file:///#{name}.rb")
    end
    
    server.global_state.index.add(RubyIndexer::Entry::Method.new(
      name,
      file_uri,
      location,
      location,
      "ree_object\ntype: :#{type.to_s}",
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

  def sample_package_dir
    @sample_package_dir ||= File.expand_path(
      File.join(__dir__, 'sample_package')
    )
  end

  def sample_package_locales_dir
    File.join(sample_package_dir, 'package', 'sample_package', 'locales')
  end

  def sample_file_uri
    file_name = 'my_file'
    package_name = 'sample_package'
    URI("file://#{sample_package_dir}/package/#{package_name}/#{file_name}.rb")
  end

  def ruby_document(source)
    RubyLsp::RubyDocument.new(
      source: source, 
      version: 1, 
      uri: URI.parse(''), 
      global_state: RubyLsp::GlobalState.new
    )
  end

  def store_locales_cache
    {
      en: File.read(sample_package_locales_dir + '/en.yml'),
      ru: File.read(sample_package_locales_dir + '/ru.yml')
    }
  end

  def restore_locales_cache(cache)
    File.write(sample_package_locales_dir + '/en.yml', cache[:en])
    File.write(sample_package_locales_dir + '/ru.yml', cache[:ru])
  end
end