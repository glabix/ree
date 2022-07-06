module Ree::RSpecLinkDSL
  def link(obj_name, as: nil, from:)
    obj = Ree.container.compile(from, obj_name)

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
  end
end