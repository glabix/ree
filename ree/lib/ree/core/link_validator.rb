# frozen_string_literal  = true

class Ree::LinkValidator
  def initialize(packages_facade)
    @packages_facade = packages_facade
  end
  
  # Validates existance and uniqueness of linked object
  # @param [Ree::Object] object
  # @param [Ree::ObjectLink] link
  # @return [nil]
  def call(object, link)
    link_package = @packages_facade.get_package(link.package_name)
    link_object = link_package.get_object(link.object_name)

    if !link_object
      msg = <<~DOC
        object: :#{object.name}
        path: #{Ree::PathHelper.abs_object_path(object)}
        error: Unable to find  :#{link.object_name} in :#{link.package_name} package
      DOC

      raise Ree::Error.new(msg, :invalid_dsl_usage)
    end

    existing_link = link_object.links.detect do |inj|
      inj.object_name == link.object_name && inj.package_name == link.package_name
    end

    if existing_link
      msg = <<~DOC
        object: :#{object.name}
        path: #{Ree::PathHelper.abs_object_path(object)}
        error: Duplicate link :#{link.object_name}
      DOC

      raise Ree::Error.new(msg, :invalid_dsl_usage)
    end

    nil
  end
end