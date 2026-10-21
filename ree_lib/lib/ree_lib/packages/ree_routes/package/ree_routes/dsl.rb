# frozen_string_literal: true

require_relative "route_builder"
require "uri"

module ReeRoutes
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
      base.include(Ree::Inspectable)
    end

    def self.extended(base)
      base.extend(ClassMethods)
    end

    module FactoryMethod
      def build
        self.class.instance_variable_get(:@routes) || []
      end
    end

    module ClassMethods
      include Ree::Contracts::Core
      include Ree::Contracts::ArgContracts

      ADMIN_PATH_SEGMENT = "admin"

      def routes(name, &proc)
        raise ArgumentError.new("block is required") if !block_given?

        @dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :object
        )

        @dsl.singleton
        @dsl.factory(:build)
        @dsl.tags(["routes"])

        instance_exec(&proc)

        klass = @dsl.object.klass
        klass.send(:include, FactoryMethod)


        Ree.container.compile(@dsl.package, name)
      end

      def default_warden_scope(*method_names)
        @default_warden_scopes = method_names
      end

      [:get, :post, :put, :delete, :patch, :head, :options].each do |request_method|
        define_method request_method do |path, &proc|
          define_route(request_method, path, &proc)
        end
      end

      private

      contract Symbol, String, Block => ReeRoutes::Route
      def define_route(request_method, path, &proc)
        raise ArgumentError.new("routes should be called") if !@dsl
        raise ArgumentError.new("block is required") if !block_given?

        @routes ||= []

        builder = ReeRoutes::RouteBuilder.new
        builder.instance_exec(&proc)

        if @default_warden_scopes && (!builder.get_route.warden_scopes || builder.get_route.warden_scopes.empty?)
          builder.warden_scope(*@default_warden_scopes)
        end

        uri = URI.parse(path) rescue nil

        if uri.nil? || uri.path != path
          raise ArgumentError.new("invalid path provided #{path}")
        end

        if uri.query && !uri.query.empty?
          raise ArgumentError.new("route path should not include query params: #{path}")
        end

        builder.get_route.path = path
        builder.get_route.request_method = request_method

        if !builder.get_route.valid?
          raise ArgumentError.new("action, summary and auth scope should be provided for #{builder.get_route.inspect}")
        end

        if builder.get_route.visibility.nil? && admin_path?(path)
          raise ArgumentError.new(
            "admin route #{path} must declare visibility explicitly: " \
            "`visibility :internal` to keep it out of generated swagger, " \
            "or `visibility :public` if it is intentionally documented"
          )
        end

        if !builder.get_route.audit_declared? && admin_path?(path)
          raise ArgumentError.new(
            "admin route #{path} must declare audit explicitly: " \
            "`audit true` to record the call in the access trail, " \
            "or `audit false` if the route touches nothing worth recording"
          )
        end

        route = builder.get_route

        @dsl.link(route.action.name, from: route.action.package_name)

        if route.serializer
          @dsl.link(route.serializer.name, from: route.serializer.package_name)
        end

        @routes << route
        route
      end

      # Forgetting `visibility` on an admin route is invisible in review and
      # silently publishes it, so make it a boot-time failure instead.
      contract String => Bool
      def admin_path?(path)
        path.split("/").include?(ADMIN_PATH_SEGMENT)
      end
    end
  end
end
