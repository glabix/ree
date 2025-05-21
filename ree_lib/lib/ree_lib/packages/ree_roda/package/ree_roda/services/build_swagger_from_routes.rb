class ReeRoda::BuildSwaggerFromRoutes
  include Ree::FnDSL

  fn :build_swagger_from_routes do
    link :build_route_errors
    link :build_schema, from: :ree_swagger
    link "ree_swagger/dto/endpoint_dto", -> { EndpointDto }
  end

  contract(ArrayOf[ReeRoutes::Route], String, String, String, String => Hash)
  def call(routes, title, description, version, api_url)
    endpoints = routes.map do |route|
      method_decorator = Ree::Contracts.get_method_decorator(
        route.action.klass, :call, scope: :instance
      )

      response_status = case route.request_method
      when :post
        201
      when :put, :delete, :patch
        204
      else
        200
      end

      caster = if route.action.klass.const_defined?(:ActionCaster)
        route.action.klass.const_get(:ActionCaster)
      end

      EndpointDto.new(
        method: route.request_method,
        sections: route.sections,
        respond_to: route.respond_to,
        path: route.path.start_with?("/") ? route.path : "/#{route.path}",
        caster: caster,
        serializer: route.serializer&.klass&.new,
        summary: route.summary,
        authenticate: route.warden_scope != :visitor,
        description: method_decorator&.doc || "",
        response_status: response_status,
        response_description: nil,
        errors: build_route_errors(route)
      )
    end

    build_schema(
      title: title,
      description: description,
      version: version,
      api_url: api_url,
      endpoints: endpoints
    )
  end
end
