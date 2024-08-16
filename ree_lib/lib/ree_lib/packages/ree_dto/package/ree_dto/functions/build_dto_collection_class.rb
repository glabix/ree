class ReeDto::BuildDtoCollectionClass
  include Ree::FnDSL

  fn :build_dto_collection_class do
    link :camelize, from: :ree_string
    link "ree_dto/dto/dto_collection", -> { DtoCollection }
  end

  contract Class, Symbol, Any => Class
  def call(klass, collection_name, entity_contract)
    name = camelize(collection_name.to_s)

    const = Class.new(DtoCollection) do
      contract entity_contract => nil
      def add(item)
        @list ||= []
        @list.push(item)
        nil
      end

      contract entity_contract => Nilor[entity_contract]
      def remove(item)
        @list.delete(item)
      end

      alias :<< :add
      alias :push :add
      alias :remove :delete
    end

    const_name = "#{name}CollectionDto"
    klass.const_set(const_name, const)
    klass.const_get(const_name)
  end
end
