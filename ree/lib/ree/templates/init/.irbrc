class Object
  def local_methods
    (instance_methods - Object.instance_methods).sort
  end
end

def link(obj_name, from:)
  obj = Ree.container.packages_facade.get_object(from, obj_name)

  define_method obj_name do |*args, **kwargs, &proc|
    obj.klass.new.call(*args, **kwargs, &proc)
  end
end