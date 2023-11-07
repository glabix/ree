class Roda
  module RodaPlugins
    module ReeRoutes
      def self.load_dependencies(app, opts = {})
        package_require("ree_roda/services/build_routing_tree")
        package_require("ree_roda/services/build_swagger_from_routes")
        package_require("ree_json/functions/to_json")
        package_require("ree_hash/functions/transform_values")
        package_require("ree_object/functions/not_blank")

        app.plugin :all_verbs
      end

      def self.configure(app, opts = {})
        app.opts[:ree_routes_before] = opts[:before] if opts[:before]
      end

      module ClassMethods
        def ree_routes(routes, swagger_title: "", swagger_description: "",
                        swagger_version: "", swagger_url: "", api_url: "")
          @ree_routes ||= []
          @ree_routes += routes

          opts[:ree_routes_swagger_title] = swagger_title
          opts[:ree_routes_swagger_description] = swagger_description
          opts[:ree_routes_swagger_version] = swagger_version
          opts[:ree_routes_swagger_url] = swagger_url
          opts[:ree_routes_api_url] = api_url

          opts[:ree_routes_swagger] = ReeRoda::BuildSwaggerFromRoutes.new.call(
            @ree_routes,
            opts[:ree_routes_swagger_title],
            opts[:ree_routes_swagger_description],
            opts[:ree_routes_swagger_version],
            opts[:ree_routes_api_url]
          )

          build_routes_proc
          nil
        end

        private

        def build_routes_proc
          list = []
          context = self

          return list if @ree_routes.nil? || @ree_routes.empty?

          if context.opts[:ree_routes_swagger_url]
            list << Proc.new do |r|
              r.get context.opts[:ree_routes_swagger_url] do
                r.json do
                  response.status = 200
                  ReeJson::ToJson.new.call(context.opts[:ree_routes_swagger])
                end
              end
            end
          end

          routing_tree = ReeRoda::BuildRoutingTree.new.call(@ree_routes)
          route_tree_proc = build_traverse_tree_proc(routing_tree, context)

          list << Proc.new do |r|
            r.instance_exec(r, &route_tree_proc)
          end

          opts[:ree_routes_proc] = list
        end

        def route_proc(route, context)
          Proc.new do |r|
            r.send(route.request_method) do
              if route.override
                r.instance_exec(r, &route.override)
              else
                r.send(route.respond_to) do
                  r.env["warden"].authenticate!(scope: route.warden_scope)

                  if context.opts[:ree_routes_before]
                    r.instance_exec(@_request, route.warden_scope, &r.scope.opts[:ree_routes_before])
                  end

                  params = r.params

                  if r.body
                    body = begin
                      JSON.parse(r.body.read)
                    rescue => e
                      {}
                    end

                    params = params.merge(body)
                  end

                  not_blank = ReeObject::NotBlank.new

                  filtered_params = ReeHash::TransformValues.new.call(params) do |k, v|
                    v.is_a?(Array) ? v.select { not_blank.call(_1) } : v
                  end

                  accessor = r.env["warden"].user(route.warden_scope)
                  action_result = get_cached_action(route).call(accessor, filtered_params)

                  if route.serializer
                    serialized_result = get_cached_serializer(route).serialize(action_result)
                  else
                    serialized_result = {}
                  end

                  case route.request_method
                  when :post
                    r.response.status = 201
                    ReeJson::ToJson.new.call(serialized_result)
                  when :put, :delete, :patch
                    r.response.status = 204
                    ""
                  else
                    r.response.status = 200
                    ReeJson::ToJson.new.call(serialized_result)
                  end
                end
              end

              nil
            end
          end
        end

        def build_traverse_tree_proc(tree, context)
          has_arbitrary_param = tree.values[0].start_with?(":")
          route_parts = has_arbitrary_param ? tree.values.map { _1.gsub(":", "") } : tree.values
          procs = []

          child_procs = tree.children.map do |child|
            build_traverse_tree_proc(child, context)
          end

          route_procs = tree.routes.map do |route|
            route_proc(route, context)
          end

          procs << if tree.children.length > 0
            if has_arbitrary_param
              Proc.new do |r|
                r.on String do |param_val|
                  route_parts.each do |route_part|
                    r.params[route_part] = param_val
                  end

                  child_procs.each do |child_proc|
                    r.instance_exec(r, &child_proc)
                  end

                  r.is do
                    route_procs.each do |route_proc|
                      r.instance_exec(r, &route_proc)
                    end

                    nil
                  end

                  nil
                end
              end
            else
              Proc.new do |r|
                r.on route_parts[0] do
                  child_procs.each do |child_proc|
                    r.instance_exec(r, &child_proc)
                  end

                  r.is do
                    route_procs.each do |route_proc|
                      r.instance_exec(r, &route_proc)
                    end

                    nil
                  end

                  nil
                end
              end
            end
          else
            Proc.new do |r|
              if has_arbitrary_param
                r.is String do |param_val|
                  route_parts.each do |route_part|
                    r.params[route_part] = param_val
                  end

                  r.is do
                    route_procs.each do |route_proc|
                      r.instance_exec(r, &route_proc)
                    end

                    nil
                  end

                  nil
                end
              else
                r.is route_parts[0] do
                  r.is do
                    route_procs.each do |route_proc|
                      r.instance_exec(r, &route_proc)
                    end

                    nil
                  end

                  nil
                end
              end
            end
          end

          Proc.new do |r|
            procs.each do |proc|
              r.instance_exec(r, &proc)
            end
          end
        end
      end

      module RequestMethods
        @@_actions_cache = {}
        @@_route_serializers_cache = {}

        def ree_routes
          if scope.opts[:ree_routes_proc]
            scope.opts[:ree_routes_proc].each do |request_proc|
              self.instance_exec(self, &request_proc)
            end
          end
          nil
        end

        private

        def get_cached_action(route)
          @@_actions_cache[route.action.object_id] ||= route.action.klass.new
        end

        def get_cached_serializer(route)
          @@_route_serializers_cache[route.serializer.object_id] ||= route.serializer.klass.new
        end
      end
    end

    register_plugin(:ree_routes, Roda::RodaPlugins::ReeRoutes)
  end
end