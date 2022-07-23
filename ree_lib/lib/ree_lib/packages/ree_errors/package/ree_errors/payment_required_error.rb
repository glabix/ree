require_relative 'error_factory'

class ReeErrors::PaymentRequiredError < ReeErrors::ErrorFactory
  include Ree::BeanDSL

  bean :payment_required_error do
    link :build_error
    link 'ree_errors/error', -> { Error }
  end

  contract Symbol, Nilor[String] => SubclassOf[Error]
  def build(code, locale = nil)
    build_error(:payment_required, code, locale)
  end
end