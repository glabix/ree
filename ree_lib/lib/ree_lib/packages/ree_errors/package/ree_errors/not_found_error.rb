require_relative 'error_factory'

class ReeErrors::NotFoundError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :not_found_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:not_found, code, locale)
  end
end