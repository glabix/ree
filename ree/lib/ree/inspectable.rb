require "json"
require "objspace"

module Ree::Inspectable
  def inspect
    object_internals_json = ObjectSpace.dump(self)
    address = JSON.parse(object_internals_json)["address"]
    "#<#{self.class.name}:#{address}>"
  end
end