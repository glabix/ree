class ReeSwagger::PathDto
  include ReeDto::EntityDSL

  properties(
    path: String,
    schema: Hash
  )
end
