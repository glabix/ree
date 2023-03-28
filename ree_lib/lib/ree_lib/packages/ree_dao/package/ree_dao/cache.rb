module ReeDao::Cache
  @@cache = {}

  def self.init_cache(thread)
    @@cache[thread] = {}
  end

  def self.get_cache(thread = Thread.current)
    @@cache[thread]
  end

  def self.set_cache(thread = Thread.current, data)
    @@cache[thread] ||= {}
    @@cache[thread] = data
  end

  def self.delete_cache(thread)
    @@cache.delete(thread)
  end
end