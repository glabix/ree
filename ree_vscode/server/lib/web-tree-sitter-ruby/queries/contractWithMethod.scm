(
      (contract (_) @contract_params) @contract
      .
      [
        (method (method_parameters)? @method_params) @method
      ]
      (#select-adjacent! @contract @method)
    ) @contract_with_method