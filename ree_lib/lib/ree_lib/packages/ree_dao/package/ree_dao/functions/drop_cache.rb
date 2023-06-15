# frozen_string_literal: true

class ReeDao::DropCache
  include Ree::FnDSL

  fn :drop_cache do
    link :dao_cache
  end

  contract(None => nil)
  def call
    dao_cache.drop_thread_cache(Thread.current)
    nil
  end
end