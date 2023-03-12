# frozen_string_literal: true

require_relative "action_builder"
require "uri"

module ReeActions
  module DSL
    def self.included(base)
      base.extend(ClassMethods)
    end

    def self.extended(base)
      base.extend(ClassMethods)
    end

    module FactoryMethod
      def build
        self.class.instance_variable_get(:@actions) || []
      end
    end

    module ClassMethods
      include Ree::Contracts::Core
      include Ree::Contracts::ArgContracts

      def actions(name, &proc)
        raise ArgumentError.new("block is required") if !block_given?

        @dsl = Ree::ObjectDsl.new(
          Ree.container.packages_facade, name, self, :object
        )

        @dsl.singleton
        @dsl.factory(:build)
        @dsl.tags(["actions"])

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
          define_action(request_method, path, &proc)
        end
      end

      private

      contract Symbol, String, Block => ReeActions::Action
      def define_action(request_method, path, &proc)
        raise ArgumentError.new("actions should be called") if !@dsl
        raise ArgumentError.new("block is required") if !block_given?

        @actions ||= []

        builder = ReeActions::ActionBuilder.new
        builder.instance_exec(&proc)

        if @default_warden_scope && !builder.get_action.warden_scope
          builder.warden_scope(@default_warden_scope)
        end

        uri = URI.parse(path) rescue nil

        if uri.nil? || uri.path != path
          raise ArgumentError.new("invalid path provided #{path}")
        end

        if uri.query && !uri.query.empty?
          raise ArgumentError.new("action path should not include query params: #{path}")
        end

        builder.get_action.path = path
        builder.get_action.request_method = request_method

        if !builder.get_action.valid?
          raise ArgumentError.new("action, summary and auth scope should be provider for #{builder.get_action.inspect}")
        end

        action = builder.get_action

        @dsl.link(action.action.name, from: action.action.package_name)

        if action.serializer
          @dsl.link(action.serializer.name, from: action.serializer.package_name)
        end

        @actions << action
        action
      end
    end
  end
end