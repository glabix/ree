require_relative 'error_factory'

class ReeErrors::ValidationError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :validation_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:validation, code, locale)
  end
end