class ReeDto::BuildDtoCollectionClass
  include Ree::FnDSL

  fn :build_dto_collection_class do
    link "ree_dto/dto/dto_collection", -> { DtoCollection }
  end

  contract Any => Class
  def call(entity_contract)
    Class.new(DtoCollection) do
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
    end
  end
end
