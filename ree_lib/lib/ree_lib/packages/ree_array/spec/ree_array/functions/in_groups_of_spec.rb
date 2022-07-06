# frozen_string_literal: true

RSpec.describe :in_groups_of do
  link :in_groups_of, from: :ree_array

  it 'perfect fit' do
    groups = []
    
    in_groups_of(("a".."i").to_a, 3) do |group|
      groups << group
    end

    expect(groups).to eq([%w(a b c), %w(d e f), %w(g h i)])
    expect(in_groups_of(("a".."i").to_a, 3)).to eq([%w(a b c), %w(d e f), %w(g h i)])
  end

  it 'with padding' do
    groups = []
    
    in_groups_of(("a".."g").to_a, 3) do |group|
      groups << group
    end

    expect(groups).to eq([%w(a b c), %w(d e f), ["g"]])
  end

  it 'with specified fill_in' do
    groups = []
    
    in_groups_of(("a".."g").to_a, 3, fill_with: 'foo') do |group|
      groups << group
    end

    expect(groups).to eq([%w(a b c), %w(d e f), ["g", "foo", "foo"]])
  end

  it 'with nil padding' do
    groups = []
    
    in_groups_of(("a".."g").to_a, 3, fill_with: nil) do |group|
      groups << group
    end

    expect(groups).to eq([%w(a b c), %w(d e f), ["g", nil, nil]])
  end
  
  it "invalid argument" do
    expect { in_groups_of([], 0)}.to raise_error(ArgumentError)
    expect { in_groups_of([], -1)}.to raise_error(ArgumentError)
  end
end