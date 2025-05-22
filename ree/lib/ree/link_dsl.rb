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
        if args.size > 1
          _link_multiple_objects(*args, **kwargs)
        else
          _link_object(*args, **kwargs)
        end
      elsif args.first.is_a?(String)
        _link_file(args[0], args[1])
      else
        _raise_error("Invalid link DSL usage. Args should be Hash or String")
      end
    end

    private

    # @param [ArrayOf[Symbol]] object_names
    # @param [Hash] kwargs
    def _link_multiple_objects(object_names, **kwargs)
      check_arg(kwargs[:from], :from, Symbol) if kwargs[:from]

      if kwargs.reject{ |k, _v| k == :from }.size > 0
        raise Ree::Error.new("options #{kwargs.reject{ |k, _v| k == :from }.keys} are not allowed for multi-object links", :invalid_link_option)
      end

      object_names.each do |object_name|
        _link_object(object_name, from: kwargs[:from])
      end
    end

    # @param [Symbol] object_name
    # @param [Nilor[Symbol]] as
    # @param [Nilor[Symbol]] from
    # @param [Nilor[Proc]] import
    def _link_object(object_name, as: nil, from: nil, target: nil, import: nil)
      check_arg(object_name, :object_name, Symbol)
      check_arg(as, :as, Symbol) if as
      check_arg(from, :from, Symbol) if from
      check_arg(import, :import, Proc) if import

      if target && ![:object, :class, :both].include?(target)
        raise Ree::Error.new("target should be one of [:object, :class, :both]", :invalid_dsl_usage)
      end

      packages = Ree.container.packages_facade
      link_package_name = get_link_package_name(from, object_name)
      link_object_name = object_name
      link_as = as ? as : object_name

      if import
        Ree::LinkImportBuilder.new(packages).build(
          self, link_package_name, link_object_name, import
        )
      end

      obj = packages.load_package_object(link_package_name, link_object_name)
      target ||= obj.target

      if target == :both
        mount_obj(obj, link_as, true)
        mount_obj(obj, link_as, false)
      elsif target == :class
        mount_obj(obj, link_as, true)
      elsif target == :object
        mount_obj(obj, link_as, false)
      end
    end

    def mount_obj(obj, link_as, mount_self)
      if obj.fn?
        if obj.with_caller?
          self.class_eval %Q(
            #{mount_self ? "class << self" : ""}
            private def #{link_as}(*args, **kwargs, &block)
              #{obj.klass}.new.set_caller(self).call(*args, **kwargs, &block)
            end
            #{mount_self ? "end" : ""}
          )
        else
          self.class_eval %Q(
            #{mount_self ? "class << self" : ""}
            private def #{link_as}(*args, **kwargs, &block)
              @#{link_as} ||= #{obj.klass}.new
              @#{link_as}.call(*args, **kwargs, &block)
            end
            #{mount_self ? "end" : ""}
          )
        end
      else
        if obj.with_caller?
          self.class_eval %Q(
            #{mount_self ? "class << self" : ""}
            private def #{link_as}
              #{obj.klass}.new.set_caller(self)
            end
            #{mount_self ? "end" : ""}
          )
        else
          self.class_eval %Q(
            #{mount_self ? "class << self" : ""}
            private def #{link_as}
              @#{link_as} ||= #{obj.klass}.new
            end
            #{mount_self ? "end" : ""}
          )
        end
      end
    end

    # @param [String] path Relative package file path ('accounts/entities/user')
    # @param [Proc] proc Import constants proc
    def _link_file(path, import_proc = nil)
      check_arg(import_proc, :import, Proc) if import_proc

      list = path.split('/')
      package_name = File.basename(list[0], ".*").to_sym
      packages = Ree.container.packages_facade
      packages.load_package_entry(package_name)
      package = packages.get_package(package_name)

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

      packages.load_file(file_path, package.name)

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
        Ree::LinkImportBuilder.new(packages).build_for_const(
          self, file_const, import_proc
        )
      end

      nil
    end

    def _raise_error(text, code = :invalid_dsl_usage)
      msg = <<~DOC
        class: :#{self}
        error: #{text}
      DOC

      raise Ree::Error.new(msg, code)
    end

    def get_link_package_name(from, object_name)
      return from if from

      package_name = Ree::StringUtils.underscore(self.name.split('::').first).to_sym
      result = Ree.container.packages_facade.has_package?(package_name) ? package_name : nil

      if result.nil?
        raise Ree::Error.new("package is not provided for link :#{object_name}", :invalid_dsl_usage)
      end

      result
    end
  end
end
