class ReeRoda::StatusFromError
  include Ree::FnDSL

  fn :status_from_error

  contract(Symbol => Nilor[Integer])
  def call(error_type)
    case error_type
    when :not_found
      404
    when :invalid_param
      400
    when :conflict
      405
    when :auth
      401
    when :permission
      403
    when :payment
      402
    when :validation
      422
    end
  end
end