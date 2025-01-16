class BasicListener
  def initialize(dispatcher, response_builder)
    $stderr.puts "on listener init"

    @response_builder = response_builder
    dispatcher.register(self, :on_constant_read_node_enter)
  end

  def on_constant_read_node_enter(node)
    $stderr.puts "on constant node enter"
    @response_builder.push("Ree addon msg for name: #{node.name}", category: :documentation)
  end
end