class ReeDao::DaoCache
  include Ree::BeanDSL

  bean :dao_cache do
    link :deep_dup, from: :ree_object

    singleton
    after_init :setup
  end

  def setup
    @threads = {}
  end

  def add_thread_cache(thread)
    @threads[get_thread_object_id(thread)] ||= {}
  end

  def drop_thread_cache(thread)
    @threads.delete(get_thread_object_id(thread))
  end

  def get(table_name, primary_key)
    add_thread_cache(current_thread)
    add_table_name(table_name)

    @threads[current_thread_object_id][table_name][primary_key] 
  end

  def set(table_name, primary_key, data)
    add_thread_cache(current_thread)
    add_table_name(table_name)
    add_primary_key(table_name, primary_key)
   
    @threads[current_thread_object_id][table_name][primary_key] = deep_dup(data)
  end

  private

  def get_thread_object_id(thread)
    thread == Thread.main ? thread.object_id : get_parent_thread(thread)
  end

  def get_parent_thread(thread)
    return thread.object_id if thread == Thread.main

    get_parent_thread(thread.parent)
  end

  def current_thread
    Thread.current
  end

  def current_thread_object_id
    get_thread_object_id(current_thread)
  end

  def add_table_name(table_name)
    if !@threads[current_thread_object_id]
      @threads[current_thread_object_id] ||= {}
    end

    @threads[current_thread_object_id][table_name] ||= {}
  end

  def add_primary_key(table_name, primary_key)
    if !@threads[current_thread_object_id]
      @threads[current_thread_object_id] ||= {}
    end

    if !@threads[current_thread_object_id][table_name]
      @threads[current_thread_object_id][table_name] ||= {}
    end

    @threads[current_thread_object_id][table_name][primary_key] ||= {}
  end
end