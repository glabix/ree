class Roda
  module RodaPlugins
    module ReeActions
      def self.load_dependencies(app, opts = {})
        package_require("ree_roda/services/build_routing_tree")
        package_require("ree_roda/services/build_swagger_from_actions")
        package_require("ree_json/functions/to_json")
        package_require("ree_hash/functions/transform_values")
        package_require("ree_object/functions/not_blank")

        app.plugin :all_verbs
      end

      def self.configure(app, opts = {})
        app.opts[:ree_actions_before] = opts[:before] if opts[:before]
      end

      module ClassMethods
        def ree_actions(actions, swagger_title: "", swagger_description: "",
                        swagger_version: "", swagger_url: "", api_url: "")
          @ree_actions ||= []
          @ree_actions += actions

          opts[:ree_actions_swagger_title] = swagger_title
          opts[:ree_actions_swagger_description] = swagger_description
          opts[:ree_actions_swagger_version] = swagger_version
          opts[:ree_actions_swagger_url] = swagger_url
          opts[:ree_actions_api_url] = api_url

          opts[:ree_actions_swagger] = ReeRoda::BuildSwaggerFromActions.new.call(
            @ree_actions,
            opts[:ree_actions_swagger_title],
            opts[:ree_actions_swagger_description],
            opts[:ree_actions_swagger_version],
            opts[:ree_actions_api_url]
          )

          build_actions_proc
          nil
        end

        private

        def build_actions_proc
          list = []
          context = self

          return list if @ree_actions.nil? || @ree_actions.empty?

          if context.opts[:ree_actions_swagger_url]
            list << Proc.new do |r|
              r.get context.opts[:ree_actions_swagger_url] do
                r.json do
                  response.status = 200
                  ReeJson::ToJson.new.call(context.opts[:ree_actions_swagger])
                end
              end
            end
          end

          routing_tree = ReeRoda::BuildRoutingTree.new.call(@ree_actions)
          route_tree_proc = build_traverse_tree_proc(routing_tree, context)

          list << Proc.new do |r|
            r.instance_exec(r, &route_tree_proc)
          end

          opts[:ree_actions_proc] = list
        end

        def action_proc(action, context)
          Proc.new do |r|
            r.send(action.request_method) do
              r.send(action.respond_to) do
                r.env["warden"].authenticate!(scope: action.warden_scope)

                if context.opts[:ree_actions_before]
                  r.instance_exec(@_request, action.warden_scope, &r.scope.opts[:ree_actions_before])
                end

                # TODO: implement me when migration to roda DSL happens
                # if action.before; end

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

                accessor = r.env["warden"].user(action.warden_scope)
                action_result = get_cached_action(action).call(accessor, filtered_params)

                if action.serializer
                  serialized_result = get_cached_serializer(action).serialize(action_result)
                else
                  serialized_result = {}
                end

                case action.request_method
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
          end
        end

        def build_traverse_tree_proc(tree, context)
          has_arbitrary_param = tree.value.start_with?(":")
          route_part = has_arbitrary_param ? tree.value.gsub(":", "") : tree.value
          procs = []

          child_procs = tree.children.map do |child|
            build_traverse_tree_proc(child, context)
          end

          action_procs = tree.actions.map do |action|
            action_proc(action, context)
          end

          procs << if tree.children.length > 0
            if has_arbitrary_param
              Proc.new do |r|
                r.on String do |param_val|
                  r.params[route_part] = param_val

                  child_procs.each do |child_proc|
                    r.instance_exec(r, &child_proc)
                  end

                  action_procs.each do |action_proc|
                    r.instance_exec(r, &action_proc)
                  end

                  nil
                end
              end
            else
              Proc.new do |r|
                r.on route_part do
                  child_procs.each do |child_proc|
                    r.instance_exec(r, &child_proc)
                  end

                  action_procs.each do |action_proc|
                    r.instance_exec(r, &action_proc)
                  end

                  nil
                end
              end
            end
          else
            Proc.new do |r|
              if has_arbitrary_param
                r.is String do |param_val|
                  r.params[route_part] = param_val

                  action_procs.each do |action_proc|
                    r.instance_exec(r, &action_proc)
                  end

                  nil
                end
              else
                r.is route_part do
                  action_procs.each do |action_proc|
                    r.instance_exec(r, &action_proc)
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
        @@_action_serializers_cache = {}

        def ree_actions
          if scope.opts[:ree_actions_proc]
            scope.opts[:ree_actions_proc].each do |request_proc|
              self.instance_exec(self, &request_proc)
            end
          end
          nil
        end

        private

        def get_cached_action(action)
          @@_actions_cache[action.action.object_id] ||= action.action.klass.new
        end

        def get_cached_serializer(action)
          @@_action_serializers_cache[action.serializer.object_id] ||= action.serializer.klass.new
        end
      end
    end

    register_plugin(:ree_actions, Roda::RodaPlugins::ReeActions)
  end
end