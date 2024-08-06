class Errors::RaiseError
  include Ree::FnDSL

  fn :raise_error

  contract Any => nil
  def call(err)
    raise err.new('error')
  end
end