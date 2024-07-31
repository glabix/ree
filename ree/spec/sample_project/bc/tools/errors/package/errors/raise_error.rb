class Errors::RaiseError
  include Ree::FnDSL

  fn :raise_error

  contract SubclassOf[Ree::DomainError] => nil
  def call(err)
    raise err.new('error', :error_code)
  end
end