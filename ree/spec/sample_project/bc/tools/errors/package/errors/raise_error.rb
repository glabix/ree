class Errors::RaiseError
  include Ree::FnDSL

  fn :raise_error

  def call(err)
    raise err.new
  end
end