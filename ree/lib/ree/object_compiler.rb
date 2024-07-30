# frozen_string_literal: true

class Ree::ObjectCompiler
  def initialize(packages_facade)
    @packages_facade = packages_facade
    @link_validator = Ree::LinkValidator.new(packages_facade)
  end

  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @return [Ree::Object]
  def call(package_name, object_name)
    @packages_facade.get_loaded_package(package_name)
    object = @packages_facade.load_package_object(package_name, object_name)

    object.set_as_compiled(true)
    Ree.logger.debug("compile_object(:#{package_name}, :#{object_name}), object_id=#{object.object_id}")

    klass = object.klass
    links = object.links

    links.each do |_|
      @link_validator.call(object, _)
      pckg = @packages_facade.get_loaded_package(_.package_name)
      obj = pckg.get_object(_.object_name)
      @packages_facade.load_package_object(pckg.name, obj.name)
    end

    eval_list = []

    eval_list.push("\n# #{object.klass}")
    indent = ""

    if object.with_caller?
      eval_list.push("def get_caller = @caller")
      eval_list.push("\n")
      eval_list.push("def set_caller(c)")
      indent = inc_indent(indent)
      eval_list.push("@caller = c")
      eval_list.push("self")
      indent = dec_indent(indent)
      eval_list.push("end")
    end

    class_links = []
    object_links = []

    links.each do |_|
      pckg = @packages_facade.get_loaded_package(_.package_name)
      obj = pckg.get_object(_.object_name)

      if [:class, :both].include?(_.target || obj.target)
        class_links << _
      end

      if [:object, :both].include?(_.target || obj.target)
        object_links << _
      end
    end

    if !class_links.empty?
      class_links.each do |_|
        pckg = @packages_facade.get_loaded_package(_.package_name)
        obj = pckg.get_object(_.object_name)

        if !obj.with_caller?
          eval_list.push(indent + "@#{_.as} = #{obj.klass}.new")
        end
      end

      eval_list.push("\n")
    end

    eval_list.push("\n")

    if object.singleton
      eval_list.push(indent + "if !const_defined?(:SEMAPHORE)")
      eval_list.push(indent + "  SEMAPHORE = Mutex.new")
      eval_list.push(indent + "  private_constant :SEMAPHORE")
      eval_list.push(indent + "end")
      eval_list.push("\n")
    end

    if object.factory || object.singleton
      eval_list.push(indent + "def self.new")

      if object.singleton
        eval_list.push(indent + "  SEMAPHORE.synchronize do")
        eval_list.push(indent + "    @__instance ||= begin")

        if object.factory
          eval_list.push(indent + "      super.#{object.factory}")
        else
          eval_list.push(indent + "      super")
        end

        eval_list.push(indent + "    end")
        eval_list.push(indent + "  end")
      else
        eval_list.push(indent + "  super.#{object.factory}")
      end

      eval_list.push(indent + "end")
    end

    eval_list.push("\n")
    eval_list.push(indent + "def initialize")

    indent = inc_indent(indent)

    links.each do |_|
      @link_validator.call(object, _)
      pckg = @packages_facade.get_loaded_package(_.package_name)
      obj = pckg.get_object(_.object_name)

      @packages_facade.load_package_object(pckg.name, obj.name)

      eval_list.push(indent + "@#{_.as} = #{obj.klass}.new")
    end

    if object.after_init?
      eval_list.push(indent + "#{object.after_init}")
    end

    if object.freeze?
      eval_list.push(indent + 'freeze')
    end

    indent = dec_indent(indent)

    eval_list.push(indent + 'end')

    if !class_links.empty?
      eval_list.push("\n")
      eval_list.push("class << self")
      indent = inc_indent(indent)

      class_links.each do |_|
        pckg = @packages_facade.get_loaded_package(_.package_name)
        obj = pckg.get_object(_.object_name)
        mount_fn(eval_list, obj, indent, _)
      end

      indent = dec_indent(indent)
      eval_list.push("end")
      eval_list.push("\n")
    end

    object_links.each do |_|
      pckg = @packages_facade.get_loaded_package(_.package_name)
      obj = pckg.get_object(_.object_name)
      mount_fn(eval_list, obj, indent, _)
    end

    indent = dec_indent(indent)

    str = eval_list.join("\n")

    klass.class_eval <<-ruby_eval, __FILE__, __LINE__ + 1
      #{str}
    ruby_eval

    # compile all linked objects
    links.each do |link|
      pckg = @packages_facade.get_loaded_package(link.package_name)
      obj = pckg.get_object(link.object_name)

      if !obj.compiled?
        self.call(obj.package_name, obj.name)
      end
    end

    object
  end

  private

  def mount_fn(eval_list, obj, indent, object_link)
    if obj.fn?
      if obj.with_caller?
        eval_list.push(indent + "private def #{object_link.as}(*args, **kwargs, &block)")
        indent = inc_indent(indent)
        eval_list.push(indent + "#{obj.klass}.new.set_caller(self).call(*args, **kwargs, &block)")
        indent = dec_indent(indent)
        eval_list.push(indent + "end")
      else
        eval_list.push(indent + "private def #{object_link.as}(*args, **kwargs, &block)")
        indent = inc_indent(indent)
        eval_list.push(indent + "@#{object_link.as}.call(*args, **kwargs, &block)")
        indent = dec_indent(indent)
        eval_list.push(indent + "end")
      end
    else
      if obj.with_caller?
        eval_list.push(indent + "private def #{object_link.as}")
        indent = inc_indent(indent)
        eval_list.push(indent + "#{obj.klass}.new.set_caller(self)")
        indent = dec_indent(indent)
        eval_list.push(indent + "end")
      else
        eval_list.push(indent + "private def #{object_link.as}")
        indent = inc_indent(indent)
        eval_list.push(indent + "@#{object_link.as}")
        indent = dec_indent(indent)
        eval_list.push(indent + "end")
      end
    end
  end

  def inc_indent(indent)
    indent += "  "
  end

  def dec_indent(indent)
    indent.slice(0, indent.size - 2)
  end
end