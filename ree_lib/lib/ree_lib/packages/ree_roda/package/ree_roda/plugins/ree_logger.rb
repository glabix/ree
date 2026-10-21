require "uri"
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
        log_params: true,
        filter_params: [],
        filter_params_placeholder: '[FILTERED]'
      }

      def self.configure(app, **opts)
        opts = REE_LOGGER_DEFAULTS.merge(opts)
        app.opts[:ree_logger] = opts[:ree_logger] || ::ReeLogger::Logger.new
        app.opts[:ree_logger_filter] = opts[:filter] if opts[:filter]
        app.opts[:ree_logger_log_params] = !!opts[:log_params]
        app.opts[:ree_logger_filter_params] = opts[:filter_params].map(&:to_s)
        app.opts[:ree_logger_filter_params_placeholder] = opts[:filter_params_placeholder]
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
              Request: #{env["REQUEST_METHOD"]} #{_ree_logger_request_path(env)} #{opts[:ree_logger_log_params] ? "\n  Params: " + _ree_logger_filtered_params.inspect : ""}
              Response status: #{response.status || "-"}#{(400..499).include?(response.status) ? "\n  Response body: " + response.body[0].to_s : ""}
              Time Taken: #{elapsed_time}
          DOC

          opts[:ree_logger].info(message)
        end

        def _ree_logger_filtered_params
          params = request.params
          filter_keys = opts[:ree_logger_filter_params]

          return params if filter_keys.empty?

          _ree_logger_filter_value(params, filter_keys, opts[:ree_logger_filter_params_placeholder])
        end

        # Keys are matched by exact name at any depth: a password nested in
        # `{user: {password: ...}}` is still a password. Exact match, unlike the
        # substring match of ree_audit, keeps `token_id` and the like readable.
        def _ree_logger_filter_value(value, filter_keys, placeholder)
          case value
          when Hash
            value.each_with_object({}) do |(k, v), h|
              h[k] = if filter_keys.include?(k.to_s)
                placeholder
              else
                _ree_logger_filter_value(v, filter_keys, placeholder)
              end
            end
          when Array
            value.map { _ree_logger_filter_value(_1, filter_keys, placeholder) }
          else
            value
          end
        end

        def _ree_logger_request_path(env)
          path = env["SCRIPT_NAME"].to_s + env["PATH_INFO"].to_s
          query = env["QUERY_STRING"]

          return path if query.nil? || query.empty?

          "#{path}?#{_ree_logger_filtered_query(query)}"
        end

        # The query string is logged verbatim next to the path, so without this
        # a secret sent in the URL (OAuth callback code, a token from an email
        # link) reached the log even though Params showed it as filtered.
        def _ree_logger_filtered_query(query)
          filter_keys = opts[:ree_logger_filter_params]

          return query if filter_keys.empty?

          placeholder = opts[:ree_logger_filter_params_placeholder]

          query.split("&", -1).map do |pair|
            key, value = pair.split("=", 2)

            if value && _ree_logger_filtered_query_key?(key, filter_keys)
              "#{key}=#{placeholder}"
            else
              pair
            end
          end.join("&")
        end

        # `user[password]=...` is the nested form of the same param, so every
        # bracket segment of the name is checked.
        def _ree_logger_filtered_query_key?(key, filter_keys)
          name = begin
            URI.decode_www_form_component(key)
          rescue ArgumentError
            key
          end

          name.scan(/[^\[\]]+/).any? { filter_keys.include?(_1) }
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