
  class ReeSwagger::ErrorDto
    include ReeDto::EntityDSL

    properties(
      status: Integer,
      description: String,
    )
  end