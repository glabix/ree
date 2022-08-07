class ReeSwagger::EndpointDto
  include ReeDto::EntityDSL
  include Ree::LinkDSL

  link 'ree_swagger/dto/error_dto', -> { ErrorDto }

  properties(
    method: Or[:get, :post, :put, :patch, :delete],
    path: String,
    caster: Nilor[ReeMapper::Mapper],
    serializer: Nilor[ReeMapper::Mapper],
    summary: Nilor[String],
    description: Nilor[String],
    response_status: Integer,
    response_description: Nilor[String],
    errors: ArrayOf[ErrorDto]
  )
end
