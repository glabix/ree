require_relative 'error_factory'

class ReeErrors::ConflictError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :conflict_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:conflict, code, locale)
  end
end