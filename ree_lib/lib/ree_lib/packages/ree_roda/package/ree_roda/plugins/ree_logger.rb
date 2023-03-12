package_require "ree_logger/beans/logger"

class Roda
  module RodaPlugins
    # The ree_logger plugin adds ReeLogger support to Roda
    #
    # Example:
    #
    #   plugin :ree_logger
    #   plugin :ree_logger, log_params: true, filter: -> { request.path.include?("health") }
    module ReeLogger
      REE_LOGGER_DEFAULTS = {
        method: :info,
        log_params: true
      }

      def self.configure(app, **opts)
        opts = REE_LOGGER_DEFAULTS.merge(opts)
        app.opts[:ree_logger] = ::ReeLogger::Logger.new
        app.opts[:ree_logger_filter] = opts[:filter] if opts[:filter]
        app.opts[:ree_logger_log_params] = !!opts[:log_params]
      end

      def self.start_timer
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end

      module InstanceMethods
        private

        # Log request/response information in common log format to logger.
        def _roda_after_90__ree_logger(result)
          return unless result && result[0] && result[1]

          if opts[:ree_logger_filter]
            return if self.instance_exec(&opts[:ree_logger_filter])
          end

          elapsed_time = if timer = @_request_timer
            "%0.4f" % (ReeLogger.start_timer - timer)
          else
            "-"
          end

          env = @_request.env

          message = <<~DOC
            Request/Response details:
              Request: #{env["REQUEST_METHOD"]} #{env["QUERY_STRING"] && !env["QUERY_STRING"].empty? ? env["SCRIPT_NAME"].to_s + env["PATH_INFO"] + "?#{env["QUERY_STRING"]}": env["SCRIPT_NAME"].to_s + env["PATH_INFO"]} #{opts[:ree_logger_log_params] ? "\n  Params: " + request.params.inspect : ""}
              Response status: #{response.status || "-"}#{(400..499).include?(response.status) ? "\n  Response body: " + response.body[0] : ""}
              Time Taken: #{elapsed_time}
          DOC

          opts[:ree_logger].info(message)
        end

        # Create timer instance used for timing
        def _roda_before_05__ree_logger
          @_request_timer = ReeLogger.start_timer
        end
      end
    end

    register_plugin(:ree_logger, ReeLogger)
  end
end