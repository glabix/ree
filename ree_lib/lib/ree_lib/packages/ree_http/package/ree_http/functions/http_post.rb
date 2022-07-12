# frozen_string_literal: true

class ReeHttp::HttpPost
  include Ree::FnDSL

  fn :http_post do
    link :http_exec, import: -> { OPTS_CONTRACT }
  end

  doc(<<~DOC)
    Sends POST HTTP request to a specified destination.
    See http_exec for usage examples.
  DOC

  contract(
    String,
    Ksplat[**OPTS_CONTRACT],
    Optblock => Net::HTTPResponse,
  )
  def call(url, **opts, &block)
    http_exec(:post, url, **opts, &block)
  end
end