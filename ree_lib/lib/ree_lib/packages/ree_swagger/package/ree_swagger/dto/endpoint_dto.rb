class ReeSwagger::EndpointDto
  include ReeDto::EntityDSL

  properties(
    method: Or[:get, :post, :put, :patch, :delete],
    path: String,
    caster: Nilor[ReeMapper::Mapper],
    serializer: Nilor[ReeMapper::Mapper],
    description: Nilor[String],
    response_status: Integer,
    response_description: Nilor[String]
  )
end
