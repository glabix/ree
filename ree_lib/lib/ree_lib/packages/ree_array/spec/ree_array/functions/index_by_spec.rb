# frozen_string_literal: true

RSpec.describe :index_by do
  link :index_by, from: :ree_array

  it {
    list = [ {id: 1}, {id: 2} ]
    result = index_by(list) { _1[:id] }

    expect(result).to eq(
      {
        1 => {id: 1},
        2 => {id: 2}
      }
    )
  }

  it {
    class EnumerableArray
      include Enumerable

      def initialize
        @list = []
      end

      def each(&proc)
        @list.each &proc
      end

      def add(v)
        @list << v
      end
    end

    list = EnumerableArray.new
    list.add({id: 1})
    list.add({id: 2})

    result = index_by(list) { _1[:id] }

    expect(result).to eq(
      {
        1 => {id: 1},
        2 => {id: 2}
      }
    )
  }
end