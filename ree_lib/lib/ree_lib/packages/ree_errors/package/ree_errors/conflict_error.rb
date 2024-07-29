class ReeErrors::ConflictError
  include Ree::FnDSL

  fn :conflict_error do
    target :class
    with_caller
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String], Kwargs[msg: Nilor[String]] => SubclassOf[Error]
  def call(code, locale = nil, msg: nil)
    build_error(get_caller, :conflict, code,locale, msg)
  end
end