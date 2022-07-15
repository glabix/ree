# frozen_string_literal: true

class ReeHttp::HttpDelete
  include Ree::FnDSL

  fn :http_delete do
    link :http_exec, import: -> { OPTS_CONTRACT }
  end

  doc(<<~DOC)
    Sends DELETE HTTP request to a specified destination.
    See http_exec for usage examples.
  DOC

  contract(
    String,
    Ksplat[**OPTS_CONTRACT],
    Optblock => Net::HTTPResponse
  )
  def call(url, **opts, &block)
    http_exec(:delete, url, **opts, &block)
  end
end