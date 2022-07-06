class Errors::Error < StandardError
  attr_reader :package, :layer, :type, :code, :message

  def initialize(package, layer, type, code, message = nil)
    @package = package
    @layer = layer
    @type = type
    @code = code
    super(message)
  end
end