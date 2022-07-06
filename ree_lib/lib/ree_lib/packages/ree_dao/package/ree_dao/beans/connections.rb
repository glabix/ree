class ReeDao::Connections
  include Ree::BeanDSL

  bean :connections do
    singleton
    after_init :setup
  end

  def setup
    @connections = []
  end

  def add(connection)
    @connections.push(connection)
  end

  def all
    @connections
  end
end