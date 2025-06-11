# frozen_string_literal: true

class Ree::LinkImportBuilder
  def initialize(packages_facade)
    @packages_facade = packages_facade
  end

  # @param [Class] klass Object class
  # @param [Symbol] package_name
  # @param [Symbol] object_name
  # @param [Proc] proc
  # @return [ArrayOf[String]] List of names of imported constants
  def build(klass, package_name, object_name, proc)
    const_list, removed_constants = Ree::ImportDsl.new.execute(klass, proc)

    @packages_facade.load_package_object(package_name, object_name)

    package = @packages_facade.get_package(package_name)
    object = package.get_object(object_name)

    const_list.each do |const_obj|
      if object.klass.const_defined?(const_obj.name)
        set_const(klass, object.klass.const_get(const_obj.name), const_obj)
      elsif package.module.const_defined?(const_obj.name)
        set_const(klass, package.module.const_get(const_obj.name), const_obj)
      else
        raise Ree::Error.new("'#{const_obj.name}' is not found in :#{object.name}")
      end
    end

    assign_removed_constants(klass, removed_constants)

    const_list.map(&:name)
  end

  # @param [Class] klass Object class
  # @param [Class] source_const Source class
  # @param [Proc] proc
  # @return [ArrayOf[String]] List of names of imported constants
  def build_for_const(klass, source_const, proc)
    const_list, removed_constants = Ree::ImportDsl.new.execute(klass, proc)
    mod_const = Object.const_get(source_const.name.split("::").first)

    const_list.each do |const_obj|
      if source_const.const_defined?(const_obj.name)
        set_const(klass, source_const.const_get(const_obj.name), const_obj)
      elsif mod_const.const_defined?(const_obj.name)
        set_const(klass, mod_const.const_get(const_obj.name), const_obj)
      else
        raise Ree::Error.new("'#{const_obj.name}' is not found in '#{source_const}'")
      end
    end

    assign_removed_constants(klass, removed_constants)
    nil
  end

  # @param [Class] klass Object class
  # @param [Symbol] package_name
  # @param [Proc] proc
  # @return [ArrayOf[String]] List of names of imported constants
  def build_for_objects(klass, package_name, proc)
    const_list, removed_constants = Ree::ImportDsl.new.execute(klass, proc)
    package = @packages_facade.get_package(package_name)

    const_list.each do |const_obj|
      if const_obj.module_name
        object_name = Ree::StringUtils.underscore(const_obj.module_name).to_sym
      else
        object_name = Ree::StringUtils.underscore(const_obj.name).to_sym
      end

      object = package.get_object(object_name)
      @packages_facade.load_package_object(package_name, object_name) if object

      if object && object.klass && object.klass.const_defined?(const_obj.name)
        set_const(klass, object.klass.const_get(const_obj.name), const_obj)
      elsif package.module.const_defined?(const_obj.name)
        set_const(klass, package.module.const_get(const_obj.name), const_obj)
      else
        raise Ree::Error.new("'#{const_obj.name}' is not found in :#{object.try(:name)}")
      end
    end

    assign_removed_constants(klass, removed_constants)

    const_list.map(&:name)
  end

  private

  def assign_removed_constants(klass, removed_constants)
    removed_constants.each do |removed_const|
      next if klass.const_defined?(removed_const.name)
      klass.const_set(removed_const.name, removed_const.const)
    end
  end

  def set_const(target_klass, ref_class, const_obj)
    if const_obj.get_as
      target_klass.send(:remove_const, const_obj.get_as.name) rescue nil
      target_klass.const_set(const_obj.get_as.name, ref_class)

      if target_klass.const_defined?(const_obj.name) && Ree::ImportDsl::ConstantContext.has_context_ancestor?(target_klass.const_get(const_obj.name))
        target_klass.send(:remove_const, const_obj.name)
      end
    else
      target_klass.send(:remove_const, const_obj.name) rescue nil
      target_klass.const_set(const_obj.name, ref_class)
    end
  end
end