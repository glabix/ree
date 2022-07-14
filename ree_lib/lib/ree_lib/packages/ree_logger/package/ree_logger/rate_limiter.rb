class ReeLogger::RateLimiter
  contract Integer, Integer => Any
  def initialize(interval, max_rate)
    @max_rate = max_rate
    @interval = interval
    @appends = []
  end

  def call(&block)
    tick = Time.now.to_i
    @appends.push(tick)
    min = tick - @interval

    loop do
      if @appends.first < min
        @appends.shift
      else
        break
      end
    end

    if @appends.size < @max_rate
      block.call
    end
  end
end