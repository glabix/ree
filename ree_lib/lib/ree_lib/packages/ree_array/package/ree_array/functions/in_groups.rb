# frozen_string_literal: true

class ReeArray::InGroups
  include Ree::FnDSL

  fn :in_groups

  doc(<<~DOC)
    Splits or iterates over the array in +number+ of groups, padding any
    remaining slots with +fill_with+ unless it is +false+.
    
      in_groups(%w(1 2 3 4 5 6 7 8 9 10), 3, fill_with: nil) {|group| p group}
      ["1", "2", "3", "4"]
      ["5", "6", "7", nil]
      ["8", "9", "10", nil]
    
      in_groups(%w(1 2 3 4 5 6 7 8 9 10, 3, fill_with: '&nbsp;') {|group| p group}
      ["1", "2", "3", "4"]
      ["5", "6", "7", "&nbsp;"]
      ["8", "9", "10", "&nbsp;"]
    
      in_groups(%w(1 2 3 4 5 6 7), 3) {|group| p group}
      ["1", "2", "3"]
      ["4", "5"]
      ["6", "7"]
  DOC
  contract(
    ArrayOf[Any],
    Integer,
    Ksplat[fill_with?: Any],
    Optblock => Or[ArrayOf[Any], Any]
  )
  def call(array, number, **opts, &block)
    # size.div number gives minor group size;
    # size % number gives how many objects need extra accommodation;
    # each group hold either division or division + 1 items.
    division = array.size.div(number)
    modulo = array.size % number

    # create a new array avoiding dup
    groups = []
    start = 0

    number.times do |index|
      length = division + (modulo > 0 && modulo > index ? 1 : 0)
      groups << last_group = array.slice(start, length)

      if opts.has_key?(:fill_with) && modulo > 0 && length == division
        last_group << opts[:fill_with]
      end

      start += length
    end

    if block_given?
      groups.each(&block)
    else
      groups
    end
  end
end