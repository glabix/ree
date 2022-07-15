# frozen_string_literal: true

class ReeHttp::BuildRequestExecutor
  include Ree::FnDSL

  fn :build_request_executor do
    link 'ree_http/constants', -> {
      DEFAULT_TIMEOUT & DEFAULT_WRITE_TIMEOUT & DEFAULT_FORCE_SSL
    }
  end

  DEFAULTS = {
    timeout: DEFAULT_TIMEOUT,
    write_timeout: DEFAULT_WRITE_TIMEOUT,
    force_ssl: DEFAULT_FORCE_SSL,
    proxy: {}
  }.freeze

  doc(<<~DOC)
    Builds Net::HTTP object that could be further used for execution
  DOC

  contract(
    URI,
    Ksplat[
      timeout?: Integer,
      write_timeout?: Integer,
      force_ssl?: Bool,
      ca_certs?: ArrayOf[File],
      proxy?: {
        address: String,
        port?: Integer,
        username?: String,
        password?: String
      }
    ] => Net::HTTP
  )
  def call(uri, **opts)
    opts = DEFAULTS.merge(opts)
    proxy = opts[:proxy] || {}

    request_executor = Net::HTTP.new(
      uri.hostname, uri.port ,
      proxy[:address], proxy[:port], proxy[:username], proxy[:password]
    )

    request_executor.write_timeout = opts[:write_timeout]
    request_executor.read_timeout = opts[:timeout]

    request_executor.use_ssl = opts[:force_ssl]

    if opts[:ca_certs?]
      request_executor = build_ca_certs(request_executor, opts[:ca_certs?])
    end

    request_executor
  end

  private

  def build_ca_certs(request_executor, ca_files)
    store = OpenSSL::X509::Store.new

    ca_files.each do |ca_file|
      store.add_cert(OpenSSL::X509::Certificate.new(ca_file.read))
    end

    request_executor.cert_store = store
    request_executor
  end
end
