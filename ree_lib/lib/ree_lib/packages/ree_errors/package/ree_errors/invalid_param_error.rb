require_relative 'error_factory'

class ReeErrors::InvalidParamError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :invalid_param_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:invalid_param, code, locale)
  end
end