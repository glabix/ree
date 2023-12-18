# frozen_string_literal: true
package_require("ree_errors/error")
package_require("ree_actions/errors")

class ReeRoda::App < Roda
  include Ree::LinkDSL

  link :logger, from: :ree_logger
  link :status_from_error
  link :to_json, from: :ree_json

  plugin :error_handler
  plugin :json_parser
  plugin :type_routing, default_type: :json

  error do |e|
    response["Content-Type"] = "application/json"

    if e.is_a?(ReeErrors::Error)
      body = {
        code: e.code,
        message: e.message,
        type: e.type,
      }

      response.status = status_from_error(e.type)
      response.write(to_json(body))
      response.finish
    elsif e.is_a?(ReeActions::ParamError)
      body = {
        code: "param",
        message: e.message,
        type: :invalid_param,
      }

      response.status = 400
      response.write(to_json(body))
      response.finish
    else
      logger.error(e.message, {}, e)
      response["Content-Type"] = "text/plain"
      response.status = 500
      response.write("unhandled server error")
      response.finish
    end
  end
end