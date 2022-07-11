class ReeHttp::BuildRequestExecutor
  include Ree::FnDSL

  fn :build_request_executor

  DEFAULTS = {
    timeout: 60,
    write_timeout: 30,
    force_ssl: false,
    proxy: {}
  }.freeze

  doc(<<~DOC)
    Returns configured Net::HTTP, it uses in execute_request.
    Options:
      uri - uri for sending request
      timeout - timeout of waiting of response after request was sent, default 60
      write_timeout - timeout of waiting of sending request, if you send large file maybe should be increased, default 30
      force_ssl - Turn on/off SSL. This flag must be set before starting session. If you change use_ssl value after session started, a Net::HTTP object raises IOError.
      ca_certs - adds ca_certs by reading files
      proxy - auth on proxy server, address required
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
