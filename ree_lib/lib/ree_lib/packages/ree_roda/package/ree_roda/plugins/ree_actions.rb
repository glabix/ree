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
          route_tree_proc = build_traverse_tree_proc(routing_tree, context) # return Proc

          list << Proc.new do |r|
            route_tree_proc.call(r)
          end

          opts[:ree_actions_proc] = list
        end

        def action_proc(action, context, param, r = nil)
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
                action_result = action.action.klass.new.call(accessor, filtered_params)
  
                if action.serializer
                  serialized_result = action.serializer.klass.new.serialize(action_result)
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
  
        def build_traverse_tree_proc(tree, context, r = nil)
          Proc.new do |r|
            param_value = tree.value.start_with?(":") ? String : tree.value
            param_name = tree.value.start_with?(":") ? tree.value.gsub(":", "") : tree.value
            if tree.actions.length == 0
              if tree.children.length > 0
                r.on param_value do
                  tree.children.each do |child|
                    build_traverse_tree_proc(child, context).call(r)
                  end

                  nil
                end
              end

              nil
            else
              if tree.children.length > 0
                r.on param_value do
                  tree.children.each do |child|
                    build_traverse_tree_proc(child, context).call(r)
                  end

                  tree.actions.each do |action|
                    action_proc(action, context, param_value).call(r)
                  end
  
                  nil
                end
              else
                r.is param_value do |**param_name|
                  tree.actions.each do |action|
                    action_proc(action, context, param_value).call(r)
                  end
  
                  nil
                end
              end
            end
          end
        end
      end

      module RequestMethods
        def ree_actions
          if scope.opts[:ree_actions_proc]
            scope.opts[:ree_actions_proc].each do |request_proc|
              self.instance_exec(self, &request_proc)
            end
          end
          nil
        end
      end
    end

    register_plugin(:ree_actions, Roda::RodaPlugins::ReeActions)
  end
end