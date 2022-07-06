# frozen_string_literal  = true

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
    result = Ree::ImportDsl.new.execute(klass, proc)

    @packages_facade.load_package_object(package_name, object_name)

    package = @packages_facade.get_package(package_name)
    object = package.get_object(object_name)
    const_list = [result] + result.constants
    
    const_list.each do |const_obj|
      if object.klass.const_defined?(const_obj.name)
        set_const(klass, object.klass.const_get(const_obj.name), const_obj)
      elsif package.module.const_defined?(const_obj.name)
        set_const(klass, package.module.const_get(const_obj.name), const_obj)
      else
        raise Ree::Error.new("'#{const_obj.name}' is not found in :#{object.name}")
      end
    end

    const_list.map(&:name)
  end

  # @param [Class] klass Object class
  # @param [Class] source_const Source class
  # @param [Proc] proc
  # @return [ArrayOf[String]] List of names of imported constants
  def build_for_const(klass, source_const, proc)
    result = Ree::ImportDsl.new.execute(klass, proc)
    mod_const = Object.const_get(source_const.to_s.split("::").first)
    const_list = [result] + result.constants

    const_list.each do |const_obj|
      if source_const.const_defined?(const_obj.name)
        set_const(klass, source_const.const_get(const_obj.name), const_obj)
      elsif mod_const.const_defined?(const_obj.name)
        set_const(klass, mod_const.const_get(const_obj.name), const_obj)
      else
        raise Ree::Error.new("'#{const_obj.name}' is not found in '#{source_const}'")
      end
    end
  end

  private

  def set_const(target_klass, ref_class, const_obj)
    if const_obj.get_as
      target_klass.send(:remove_const, const_obj.get_as.name) rescue nil
      target_klass.const_set(const_obj.get_as.name, ref_class)
    else
      target_klass.send(:remove_const, const_obj.name) rescue nil
      target_klass.const_set(const_obj.name, ref_class)
    end
  end
end