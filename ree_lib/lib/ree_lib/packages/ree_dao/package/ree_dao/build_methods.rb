module ReeDao
  module BuildMethods
    def self.extended(base)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def build(...)
        dto_class = self.opts[:schema_mapper].dto(:db_load)
        dto_class.build(...)
      end
    end
  end
end