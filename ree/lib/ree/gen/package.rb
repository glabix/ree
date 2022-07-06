# frozen_string_literal  = true

require 'fileutils'
require 'pathname'

module Ree
  module Gen
    class Package
      TEMPLATE_NAME = 'package'

      class << self
        def generate(package_name:, project_path:, local_path:, locals: {})
          Ree::Gen::Package.new(package_name, project_path, local_path, locals).create
        end
      end

      def initialize(package_name, project_path, local_path, locals = {})
        @project_path = project_path
        @package_name = package_name
        @local_path = local_path
        @locals = locals
        @schema = get_schema
      end

      def create
        if Dir.exist?(File.join(Ree.root_dir, @local_path))
          raise Ree::Error.new("Package directory #{@local_path} already exists") 
        end

        if @package_name.nil? || @package_name.empty?
          raise Ree::Error.new('Package name was not specified') 
        end

        if @schema.packages.map(&:name).include?(@package_name)
          raise Ree::Error.new('Package already exists') 
        end

        generated_files = Ree::TemplateHandler.generate(
          template_name: TEMPLATE_NAME,
          project_path: @project_path,
          local_path: @local_path,
          locals: { package_name: @package_name, local_path: @local_path }.merge(@locals)
        )

        generated_files
      end

      def get_schema
        @schema ||= begin
          Ree.init(@project_path)
          Ree.container.packages_facade.load_packages_schema
        end
      end
    end
  end
end
