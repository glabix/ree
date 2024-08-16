# frozen_string_literal: true

class ReeArray::InGroupsOf
  include Ree::FnDSL

  fn :in_groups_of

  doc(<<~DOC)
    Splits or iterates over the array in groups of size +number+,
    padding any remaining slots with +fill_with+ unless it is +false+.

      in_groups_of(%w(1 2 3 4 5 6 7 8 9 10), 3, fill_with: nil) {|group| p group}
      ["1", "2", "3"]
      ["4", "5", "6"]
      ["7", "8", "9"]
      ["10", nil, nil]

      in_groups_of(%w(1 2 3 4 5), 2, fill_with: '&nbsp;') {|group| p group}
      ["1", "2"]
      ["3", "4"]
      ["5", "&nbsp;"]

      in_groups_of(%w(1 2 3 4 5), 2) {|group| p group}
      ["1", "2"]
      ["3", "4"]
      ["5"]
  DOC
  contract(
    Or[ArrayOf[Any], Enumerable],
    Integer,
    Ksplat[fill_with?: Any],
    Optblock => Or[ArrayOf[Any], ArrayOf[ArrayOf[Any]]]
  ).throws(ArgumentError)
  def call(array, number, **opts, &block)
    if number.to_i <= 0
      raise ArgumentError,
        "Group size must be a positive integer, was #{number.inspect}"
    end

    collection = if opts.has_key?(:fill_with)
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - array.size % number) % number
      array.dup.concat(Array.new(padding, opts[:fill_with]))
    else
      array
    end

    if block_given?
      collection.each_slice(number, &block)
    else
      collection.each_slice(number).to_a
    end
  end
end