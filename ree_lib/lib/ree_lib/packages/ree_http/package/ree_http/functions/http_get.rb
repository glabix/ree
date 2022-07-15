# frozen_string_literal: true

class ReeHttp::HttpGet
  include Ree::FnDSL

  fn :http_get do
    link :http_exec, import: -> { OPTS_CONTRACT }
  end

  doc(<<~DOC)
    Sends GET HTTP request to a specified destination.
    See http_exec for usage examples.
  DOC

  contract(
    String,
    Ksplat[**OPTS_CONTRACT],
    Optblock => Net::HTTPResponse
  )
  def call(url, **opts, &block)
    http_exec(:get, url, **opts, &block)
  end
end