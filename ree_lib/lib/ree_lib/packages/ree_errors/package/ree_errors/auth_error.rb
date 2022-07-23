require_relative 'error_factory'

class ReeErrors::AuthError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :auth_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:auth, code, locale)
  end
end