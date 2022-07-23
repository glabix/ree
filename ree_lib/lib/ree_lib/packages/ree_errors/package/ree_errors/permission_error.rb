require_relative 'error_factory'

class ReeErrors::PermissionError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :permission_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:permission, code, locale)
  end
end