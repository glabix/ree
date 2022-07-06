# frozen_string_literal: true

class ReeI18n::AddLoadPath
  include Ree::FnDSL

  fn :add_load_path do
    link :wrap, from: :ree_array
  end

  contract(Or[String, ArrayOf[String]] => ArrayOf[String])
  def call(paths)
    I18n.load_path += wrap(paths)
  end
end