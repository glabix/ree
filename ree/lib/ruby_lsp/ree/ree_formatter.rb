class ReeFormatter
  include RubyLsp::Requests::Support::Formatter

  def initialize
    $stderr.puts("init formatter")
  end

  def run_formatting(uri, document)
    $stderr.puts("run_formating")
    source = document.source

    ast = Prism.parse(source)

    source
  end
end