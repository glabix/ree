# frozen_string_literal: true

require_relative "route_builder"
require "uri"

module ReeRoutes
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
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

      def default_warden_scope(method_name)
        @default_warden_scope = method_name
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

        if @default_warden_scope && !builder.get_route.warden_scope
          builder.warden_scope(@default_warden_scope)
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

        route = builder.get_route

        @dsl.link(route.action.name, from: route.action.package_name)

        if route.serializer
          @dsl.link(route.serializer.name, from: route.serializer.package_name)
        end

        @routes << route
        route
      end
    end
  end
end