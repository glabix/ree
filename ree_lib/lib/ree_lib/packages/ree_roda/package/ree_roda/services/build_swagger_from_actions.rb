class ReeRoda::BuildSwaggerFromActions
  include Ree::FnDSL

  fn :build_swagger_from_actions do
    link :build_action_errors
    link :build_schema, from: :ree_swagger
    link "ree_swagger/dto/endpoint_dto", -> { EndpointDto }
  end

  contract(ArrayOf[ReeActions::Action], String, String, String, String => Hash)
  def call(actions, title, description, version, api_url)
    endpoints = actions.map do |action|
      method_decorator = Ree::Contracts.get_method_decorator(
        action.action.klass, :call, scope: :instance
      )

      response_status = case action.request_method
      when :post
        201
      when :put, :delete, :patch
        204
      else
        200
      end

      caster = if action.action.klass.const_defined?(:ActionCaster)
        action.action.klass.const_get(:ActionCaster)
      end

      EndpointDto.new(
        method: action.request_method,
        sections: action.sections,
        respond_to: action.respond_to,
        path: action.path.start_with?("/") ? action.path : "/#{action.path}",
        caster: caster,
        serializer: action.serializer&.klass&.new,
        summary: action.summary,
        authenticate: action.warden_scope != :visitor,
        description: method_decorator&.doc || "",
        response_status: response_status,
        response_description: nil,
        errors: build_action_errors(action)
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

