class Clock::Time
  include Ree::BeanDSL

  bean :time

  contract None => Time
  def now
    Time.now
  end
end
