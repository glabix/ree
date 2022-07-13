# frozen_string_literal: true

class ReeHttp::HttpPatch
  include Ree::FnDSL

  fn :http_patch do
    link :http_exec, import: -> { OPTS_CONTRACT }
  end

  doc(<<~DOC)
    Sends PATCH HTTP request to a specified destination.
    See http_exec for usage examples.
  DOC

  contract(
    String,
    Ksplat[**OPTS_CONTRACT],
    Optblock => Net::HTTPResponse
  )
  def call(url, **opts, &block)
    http_exec(:patch, url, **opts, &block)
  end
end
