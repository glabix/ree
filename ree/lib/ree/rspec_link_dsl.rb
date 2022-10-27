module Ree::RSpecLinkDSL
  def link(obj_name, import_proc = nil, as: nil, from: nil)
    if obj_name.is_a?(Symbol)
      obj = link_object(from, obj_name)

      if obj.nil?
        raise Ree::Error.new("object :#{obj_name} was not found for package :#{from}")
      end

      as ||= obj_name

      define_method as do |*args, **kwargs, &proc|
        if obj.object?
          obj.klass.new
        else
          obj.klass.new.call(*args, **kwargs, &proc)
        end
      end
    elsif obj_name.is_a?(String)
      const_list = link_file(from, obj_name, import_proc)
      const_list.each do |const|
        Object.const_set(const.name, self.const_get(const.name))
      end
    else
      raise Ree::Error.new("Invalid link DSL usage. Args should be Hash or String")
    end  
  end

  private

  def link_object(from_package_name, obj_name)
    Ree.container.compile(from_package_name, obj_name)
  end

  def link_file(from_package_name, path, import_proc)
    Ree.container.packages_facade.load_package_entry(from_package_name)
    package = Ree.container.packages_facade.get_package(from_package_name)

    file_path = File.join(
        Ree::PathHelper.abs_package_dir(package),
        Ree::PACKAGE, path
    )
    Ree.container.packages_facade.load_file(file_path, package.name)

    const_list = path.split('/').map { |_| Ree::StringUtils.camelize(_) }
    const_short = [const_list[0], const_list.last].join("::")
    const_long = const_list.join("::")

    file_const = if Object.const_defined?(const_long)
      Object.const_get(const_long)
    elsif Object.const_defined?(const_short)
      Object.const_get(const_short)
    else
      raise Ree::Error.new("Unable to link '#{path}'. #{const_long} or #{const_short} was not defined in #{file_path}")
    end

    const_list = Ree::LinkImportBuilder
      .new(Ree.container.packages_facade)
      .build_for_const(self, file_const, import_proc)
  end
end