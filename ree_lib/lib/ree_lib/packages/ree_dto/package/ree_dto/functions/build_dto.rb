# frozen_string_literal: true

class ReeDto::BuildDto
  include Ree::FnDSL

  fn :build_dto do
    target :class
    with_caller
    link :build_dto_collection_class
    link "ree_dto/dto/dto_instance_methods", -> { DtoInstanceMethods }
    link "ree_dto/dto/dto_class_methods", -> { DtoClassMethods }
    link "ree_dto/dto/dto_builder", -> { DtoBuilder }
  end

  contract(Block => nil)
  def call(&proc)
    klass = get_caller
    klass.include DtoInstanceMethods
    klass.extend DtoClassMethods

    builder = DtoBuilder.new(self)
    builder.instance_exec(&proc)

    klass.send(:set_fields, builder.fields)
    klass.send(:set_collections, builder.collections)

    builder.fields.each do |field|
      klass.define_method field.name do
        get_value(field.name)
      end

      if field.setter
        klass.define_method :"#{field.name}=" do |val|
          set_value(field.name, val)
        end
      end
    end

    builder.collections.each do |collection|
      col_class = build_dto_collection_class(collection.contract)
      col_class.class_exec(&collection.filter_proc)

      klass.define_method collection.name do
        @collections ||= {}

        @collections[collection.name] ||= col_class.new(
          collection.name, collection.contract, klass
        )
      end
    end

    nil
  end
end