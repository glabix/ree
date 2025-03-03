module RubyLsp
  module Ree
    class ReeRenameHandler
      include RubyLsp::Ree::ReeLspUtils

      def self.call(changes)
        old_uri = changes.detect{ _1[:type] == Constant::FileChangeType::DELETED }[:uri]
        new_uri = changes.detect{ _1[:type] == Constant::FileChangeType::CREATED }[:uri]

        $stderr.puts("old uri #{old_uri}")
        $stderr.puts("new uri #{new_uri}")
      end
    end
  end
end