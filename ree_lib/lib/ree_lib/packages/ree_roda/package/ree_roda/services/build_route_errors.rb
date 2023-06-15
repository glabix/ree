class ReeRoda::BuildRouteErrors
  include Ree::FnDSL

  fn :build_route_errors do
    link "ree_swagger/dto/error_dto", -> { ErrorDto }
  end

  contract(ReeRoutes::Route => ArrayOf[ErrorDto])
  def call(route)
    ree_object = route.action
    errors = recursively_extract_errors(ree_object)

    errors
      .select {
        _1.ancestors.include?(ReeErrors::Error) && status_from_error(_1)
      }
      .map {
        e = _1.new
        description = "type: **#{e.type}**, code: **#{e.code}**, message: **#{e.message}**"

        ErrorDto.new(
          status: status_from_error(_1),
          description: description
        )
      }
      .uniq { [_1.status, _1.description] }
  end

  private

  def recursively_extract_errors(ree_object)
    errors = extract_errors(ree_object)

    ree_object.links.each do |link|
      obj = Ree.container.packages_facade.get_object(
        link.package_name, link.object_name
      )

      if obj.fn?
        errors += recursively_extract_errors(obj)
      end
    end

    errors
  end

  def extract_errors(ree_object)
    klass = ree_object.klass
    return [] if ree_object.object?

    method_decorator = Ree::Contracts.get_method_decorator(
      klass, :call, scope: :instance
    )

    original_method_decorator = Ree::Contracts.get_method_decorator(
      klass, :__original_call, scope: :instance
    )

    method_decorator&.errors || original_method_decorator&.errors || []
  end

  def status_from_error(error)
    case error.instance_variable_get(:@type)
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