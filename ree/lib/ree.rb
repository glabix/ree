# frozen_string_literal: true

require 'logger'
require 'pathname'
require_relative 'ree/version'
require 'fileutils'

module Ree
  autoload :Args, 'ree/args'
  autoload :BeanDSL, 'ree/bean_dsl'
  autoload :CLI, 'ree/cli'
  autoload :Container, 'ree/container'
  autoload :Contracts, 'ree/contracts'
  autoload :DomainError, 'ree/dsl/domain_error'
  autoload :Error, 'ree/error'
  autoload :ErrorBuilder, 'ree/dsl/error_builder'
  autoload :ErrorDsl, 'ree/dsl/error_dsl'
  autoload :FnDSL, 'ree/fn_dsl'
  autoload :Gen, 'ree/gen'
  autoload :ImportDsl, 'ree/dsl/import_dsl'
  autoload :LinkDSL, 'ree/link_dsl'
  autoload :LinkImportBuilder, 'ree/dsl/link_import_builder'
  autoload :LinkValidator, 'ree/core/link_validator'
  autoload :Object, 'ree/core/object'
  autoload :ObjectCompiler, 'ree/object_compiler'
  autoload :ObjectDsl, 'ree/dsl/object_dsl'
  autoload :ObjectError, 'ree/core/object_error'
  autoload :ObjectLink, 'ree/core/object_link'
  autoload :ObjectSchema, 'ree/core/object_schema'
  autoload :ObjectSchemaBuilder, 'ree/core/object_schema_builder'
  autoload :Package, 'ree/core/package'
  autoload :PackageDep, 'ree/core/package_dep'
  autoload :BuildPackageDsl, 'ree/dsl/build_package_dsl'
  autoload :PackageDSL, 'ree/package_dsl'
  autoload :PackageEnvVar, 'ree/core/package_env_var'
  autoload :PackageLoader, 'ree/core/package_loader'
  autoload :PackageSchema, 'ree/core/package_schema'
  autoload :PackageSchemaBuilder, 'ree/core/package_schema_builder'
  autoload :PackageSchemaLoader, 'ree/core/package_schema_loader'
  autoload :PackagesDetector, 'ree/core/packages_detector'
  autoload :PackagesFacade, 'ree/facades/packages_facade'
  autoload :PackagesSchema, 'ree/core/packages_schema'
  autoload :PackagesSchemaBuilder, 'ree/core/packages_schema_builder'
  autoload :PackagesSchemaLoader, 'ree/core/packages_schema_loader'
  autoload :PackagesSchemaLocator, 'ree/core/packages_schema_locator'
  autoload :PackagesStore, 'ree/core/packages_store'
  autoload :PathHelper, 'ree/core/path_helper'
  autoload :RenderUtils, 'ree/utils/render_utils'
  autoload :RSpecLinkDSL, 'ree/rspec_link_dsl'
  autoload :SpecRunner, 'ree/spec_runner'
  autoload :StringUtils, 'ree/utils/string_utils'
  autoload :TemplateDetector, 'ree/templates/template_detector'
  autoload :TemplateHandler, 'ree/handlers/template_handler'
  autoload :TemplateRenderer, 'ree/templates/template_renderer'

  PACKAGE = 'package'
  SCHEMAS = 'schemas'
  SCHEMA = 'schema'
  REE_SETUP = 'ree.setup.rb'
  PACKAGE_SCHEMA_FILE = 'Package.schema.json'
  PACKAGES_SCHEMA_FILE = 'Packages.schema.json'
  ROOT_DIR_MESSAGE = 'Ree.root_dir is not set. Use Ree.init(DIR) to set project dir'

  class ReeGem
    include Ree::Args

    attr_reader :name, :dir, :packages_schema_path

    def initialize(name, dir, packages_schema_path)
      check_arg(name, :name, Symbol)
      check_arg(dir, :dir, String)
      @name = name
      @dir = dir
      @packages_schema_path = packages_schema_path
    end
  end

  class << self
    include Ree::Args

    def container
      Container.instance
    end

    def logger
      @logger ||= begin
        logger = Logger.new(STDOUT)
        logger.level = Logger::WARN
        logger
      end

      @logger
    end

    # Switches Ree into irb mode that allows to declare ree objects inside IRB
    def enable_irb_mode
      @irb_mode = true
    end

    def disable_irb_mode
      @irb_mode = false
    end

    def disable_contracts
      ENV['NO_CONTRACTS'] = 'true'
    end

    def enable_contracts
      ENV['NO_CONTRACTS'] = nil
    end

    def irb_mode?
      !!@irb_mode
    end

    def set_logger_debug
      logger.level = Logger::DEBUG
    end

    # Ree will use schema files to load packages and registered objects
    def set_performance_mode
      @performance_mode = true
    end

    def set_dev_mode
      @performance_mode = false
    end

    def performance_mode?
      !!@performance_mode
    end

    # Define preload context for registered objects
    def preload_for(env)
      check_arg(env, :env, Symbol)
      @prelaod_for = env
    end

    def preload_for?(env)
      check_arg(env, :env, Symbol)
      @prelaod_for == env
    end

    def init(dir, irb: false)
      check_arg(dir, :dir, String)

      if !Dir.exists?(dir)
        raise Ree::Error.new("Dir does not exist: #{dir}", :invalid_root_dir)
      end

      @packages_schema_path = locate_packages_schema(dir)
      @root_dir = Pathname.new(@packages_schema_path).dirname.to_s

      ree_setup_path = File.join(@root_dir, REE_SETUP)

      if File.exists?(ree_setup_path)
        require(ree_setup_path)
      end

      if irb
        require('irb')
        enable_irb_mode

        FileUtils.cd(@root_dir) do
          IRB.start(@root_dir)
        end
      end

      @root_dir
    end

    # @param [Symbol] name
    # @return [Nilor[Ree::ReeGem]]
    def gem(name)
      check_arg(name, :name, Symbol)
      gems.detect { _1.name == name }
    end

    def gems
      @gems ||= []
      @gems
    end

    # @param [Symbol] name
    # @param [String] dir
    # @return [Ree::ReeGem]]
    def register_gem(gem_name, dir)
      check_arg(gem_name, :gem_name, Symbol)
      check_arg(dir, :dir, String)

      if gem(gem_name)
        raise Ree::Error.new("Ree already registered gem `#{name}`", :duplicate_gem)
      end

      if !Dir.exists?(dir)
        raise Ree::Error.new("Dir does not exist: #{dir}", :invalid_gem_dir)
      end

      dir = File.expand_path(dir)
      packages_schema_path = locate_packages_schema(dir)
      gem_dir = Pathname.new(packages_schema_path).dirname.to_s
      ree_setup_path = File.join(gem_dir, REE_SETUP)

      if File.exists?(ree_setup_path)
        require(ree_setup_path)
      end

      gem = ReeGem.new(gem_name, gem_dir, packages_schema_path)
      @gems.push(gem)

      gem
    end

    def load_package(name)
      check_arg(name, :name, Symbol)
      container.load_package(name)
    end

    def locate_packages_schema(path)
      check_arg(path, :path, String)
      Ree.logger.debug("locate_packages_schema: #{path}")
      Ree::PackagesSchemaLocator.new.call(path)
    end

    def packages_schema_path
      @packages_schema_path || (raise Ree::Error.new(ROOT_DIR_MESSAGE, :invalid_root_dir))
    end

    def root_dir
      @root_dir || (raise Ree::Error.new(ROOT_DIR_MESSAGE, :invalid_root_dir))
    end

    def write_object_schema(package_name, object_name)
      check_arg(package_name, :package_name, Symbol)
      check_arg(object_name, :object_name, Symbol)
      container.packages_facade.write_object_schema(package_name, object_name)
    end

    def generate_schemas_for_all_packages(silence = false)
      Ree.logger.debug("generate_schemas_for_all_packages") if !silence
      facade = container.packages_facade

      facade.class.write_packages_schema
      facade.load_packages_schema

      facade.packages_store.packages.each do |package|
        next if package.gem?
        puts("Generating Package.schema.json for :#{package.name} package") if !silence

        facade.load_entire_package(package.name)
        facade.write_package_schema(package.name)

        schemas_path = Ree::PathHelper.abs_package_object_schemas_path(package)

        FileUtils.rm_rf(schemas_path)
        FileUtils.mkdir_p(schemas_path)

        package.objects.each do |object|
          next if !object.schema_rpath
          write_object_schema(package.name, object.name)
        end
      end
    end

    def error_types
      @error_types ||= []
    end

    def add_error_types(*args)
      args.each do |arg|
        check_arg(arg, :error, Symbol)
      end

      @error_types = (error_types + args).uniq
    end
  end
end

require_relative 'ree/dsl/object_hooks'
require_relative 'ree/dsl/package_require'