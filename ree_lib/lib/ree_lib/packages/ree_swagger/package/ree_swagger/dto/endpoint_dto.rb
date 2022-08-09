class ReeSwagger::EndpointDto
  include ReeDto::EntityDSL
  include Ree::LinkDSL

  link 'ree_swagger/dto/error_dto', -> { ErrorDto }
  link 'ree_swagger/functions/get_mime_type', -> { MIME_TYPES }


  properties(
    method: Or[:get, :post, :put, :patch, :delete],
    respond_to: Or[*MIME_TYPES.keys],
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
