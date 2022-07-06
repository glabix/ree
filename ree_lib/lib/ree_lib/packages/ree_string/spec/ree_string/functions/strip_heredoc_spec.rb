# frozen_string_literal: true

RSpec.describe :strip_heredoc do
  link :strip_heredoc, from: :ree_string

  it 'empty string' do
    expect(strip_heredoc("")).to eq("")
  end

  it 'frozen string' do
    expect(strip_heredoc("").frozen?).to eq(true)
  end

  it 'string with no lines' do
    expect(strip_heredoc("x")).to eq("x")
    expect(strip_heredoc("    x")).to eq("x")
  end

  it 'heredoc with no margin' do
    expect(strip_heredoc("foo\nbar")).to eq("foo\nbar")
    expect(strip_heredoc("foo\n  bar")).to eq("foo\n  bar")
  end

  it 'regular indented heredoc' do
    expect(
      strip_heredoc(<<-EOS)
        foo
          bar
        baz
      EOS
    ).to eq("foo\n  bar\nbaz\n")
  end

  it 'regular indented heredoc with blank lines' do
    expect(
      strip_heredoc(<<-EOS)
        foo
          bar

        baz
      EOS
    ).to eq("foo\n  bar\n\nbaz\n")
  end
end