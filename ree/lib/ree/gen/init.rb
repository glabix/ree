# frozen_string_literal  = true

require 'fileutils'
require 'pathname'

module Ree
  module Gen
    class Init
      TEMPLATE_NAME        = 'init'
      INIT_PATH            = './'
      LOCAL_TEMPLATES_PATH = '.ree/templates'

      class << self
        def generate(project_path:, test: 'rspec', console: 'irb', stdout: STDOUT)
          Ree::Gen::Init.new(project_path, test, console, stdout).generate
        end
      end

      def initialize(project_path, test, console, stdout)
        @project_path      = project_path
        @test              = test
        @console           = console
        @template_detector = Ree::TemplateDetector.new(project_path)
        @stdout            = stdout
      end

      def generate
        if @project_path.nil? || @project_path.empty?
          raise Ree::Error.new("Project folder not specified. Type path to ree project, ex: 'ree init .'")
        end

        if !Dir.exist?(@project_path)
          raise Ree::Error.new("#{@project_path} doesn't exist. Initialize new ree project with existing directory")
        end

        if File.exist?(File.join(@project_path, Ree::PACKAGES_SCHEMA_FILE))
          raise Ree::Error.new("#{@project_path} has already #{Ree::PACKAGES_SCHEMA_FILE}")
        end

        generated_files = Ree::TemplateHandler.generate(
          template_name: TEMPLATE_NAME,
          project_path: @project_path,
          local_path: INIT_PATH,
          stdout: @stdout
        )

        FileUtils.mkdir_p(local_templates_path)
        
        FileUtils.cp_r(
          @template_detector.gem_template_folder('package'),
          File.dirname(@template_detector.project_template_folder('package'))
        )

        generated_files
      end

      private

      def local_templates_path
        File.join(@project_path, LOCAL_TEMPLATES_PATH)
      end
    end
  end
end
