# frozen_string_literal: true

module Ree::LinkDSL
  def self.included(base)
    validate(base)
    base.extend(ClassMethods)
  end

  def self.extended(base)
    validate(base)
    base.extend(ClassMethods)
  end

  def self.validate(base)
    if !base.is_a?(Class)
      raise ArgumentError, "Ree::LinkDSL should be included to named classed only"
    end

    if self.name.nil?
      raise ArgumentError, "LinkDSL does not support anonymous classes"
    end
  end

  module ClassMethods
    include Ree::Args

    def link(*args, **kwargs)
      if args.first.is_a?(Symbol)
        _link_object(*args, **kwargs)
      elsif args.first.is_a?(String)
        _link_file(args[0], args[1])
      else
        _raise_error("Invalid link DSL usage. Args should be Hash or String")
      end
    end

    private

    # @param [Symbol] object_name
    # @param [Nilor[Symbol]] as
    # @param [Nilor[Symbol]] from
    # @param [Nilor[Proc]] import
    def _link_object(object_name, as: nil, from: nil, import: nil)
      check_arg(object_name, :object_name, Symbol)
      check_arg(as, :as, Symbol) if as
      check_arg(from, :from, Symbol) if from
      check_arg(import, :import, Proc) if import

      package_name = Ree::StringUtils.underscore(self.name.split('::').first).to_sym
      link_package_name = from.nil? ? package_name : from
      link_object_name = object_name
      link_as = as ? as : object_name

      _check_package_dependency_added(link_package_name, package_name)

      if import
        Ree::LinkImportBuilder
          .new(Ree.container.packages_facade)
          .build(
            self,
            link_package_name,
            link_object_name,
            import
          )
      end

      obj = Ree
        .container
        .packages_facade
        .load_package_object(link_package_name, link_object_name)

      if obj.fn?
        self.class_eval %Q(
          private def _#{link_as}
            @#{link_as} ||= #{obj.klass}.new
          end

          private def #{link_as}(*args, **kwargs, &block)
            _#{link_as}.call(*args, **kwargs, &block)
          end
        )
      else
        self.class_eval %Q(
          private def #{link_as}
            @#{link_as} ||= #{obj.klass}.new
          end
        )
      end
    end

    # @param [String] path Relative package file path ('accounts/entities/user')
    # @param [Proc] proc Import constants proc
    def _link_file(path, import_proc = nil)
      check_arg(import_proc, :import, Proc) if import_proc

      list = path.split('/')
      package_name = File.basename(list[0], ".*").to_sym
      current_package_name = Ree::StringUtils.underscore(self.name.split('::').first).to_sym

      _check_package_dependency_added(package_name, current_package_name)

      Ree.container.packages_facade.load_package_entry(package_name)
      package = Ree.container.packages_facade.get_package(package_name)

      file_path = File.join(
        Ree::PathHelper.abs_package_dir(package),
        Ree::PACKAGE, path
      )

      if !File.exist?(file_path)
        file_path = "#{file_path}.rb"

        if !File.exist?(file_path)
          _raise_error("Unable to link '#{path}'. File not found #{file_path}")
        end
      end

      Ree.container.packages_facade.load_file(file_path, package.name)

      const_list = path.split('/').map { |_| Ree::StringUtils.camelize(_) }
      const_short = [const_list[0], const_list.last].join("::")
      const_long = const_list.join("::")

      file_const = if Object.const_defined?(const_long)
        Object.const_get(const_long)
      elsif Object.const_defined?(const_short)
        Object.const_get(const_short)
      else
        _raise_error("Unable to link '#{path}'. #{const_long} or #{const_short} was not defined in #{file_path}")
      end

      if import_proc
        Ree::LinkImportBuilder
          .new(Ree.container.packages_facade)
          .build_for_const(
            self,
            file_const,
            import_proc
          )
      end

      nil
    end

    def _raise_error(text, code = :invalid_dsl_usage)
      msg = <<~DOC
        object: :#{@object.name}
        path: #{Ree::PathHelper.abs_object_path(@object)}
        error: #{text}
      DOC

      raise Ree::Error.new(msg, code)
    end

    def _check_package_dependency_added(package_name, current_package_name)
      return if package_name == current_package_name

      facade = Ree.container.packages_facade
      facade.load_package_entry(package_name)
      facade.load_package_entry(current_package_name)

      current_package = facade.get_package(current_package_name)

      dep_package = current_package.deps.detect do |d|
        d.name == package_name
      end

      if dep_package.nil?
        raise Ree::Error.new(
          "Package :#{package_name} is not added as dependency for :#{current_package_name} package\npackage path: #{File.join(Ree.root_dir, current_package.entry_rpath)}\nclass:#{self.name}",
          :invalid_dsl_usage
        )
      end
    end
  end
end
