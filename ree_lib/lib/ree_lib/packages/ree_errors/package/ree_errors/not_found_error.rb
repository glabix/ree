class ReeErrors::NotFoundError
  include Ree::FnDSL

  fn :not_found_error do
    target :class
    with_caller
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String], Kwargs[msg: Nilor[String]] => SubclassOf[Error]
  def call(code, locale = nil, msg: nil)
    build_error(get_caller, :not_found, code,locale, msg)
  end
end