require_relative 'base_formatter'
require_relative "../ree_object_finder"

module RubyLsp
  module Ree
    class MissingImportsFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, uri)
        return source unless @index

        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.has_root_class?

        finder = ReeObjectFinder.new(@index)
        editor = RubyLsp::Ree::ReeSourceEditor.new(source)

        current_package = package_name_from_uri(uri)

        fn_calls = parsed_doc.parse_fn_calls
        filtered_fn_calls = filter_fn_calls(parsed_doc, fn_calls)
        objects_to_add = filtered_fn_calls.map{ |fn_call|
          ree_objects = finder.find_objects(fn_call.name.to_s)
          choose_object_to_add(ree_objects, current_package)
        }.compact

        bean_calls = parsed_doc.parse_bean_calls
        filtered_bean_calls = filter_bean_calls(parsed_doc, bean_calls)
        objects_to_add += filtered_bean_calls.map{ |bean_call|
          ree_objects = finder.find_objects(bean_call.receiver_name.to_s)
          choose_object_to_add(ree_objects, current_package)
        }.compact

        objects_to_add.uniq!{ |obj| obj.name }
        objects_to_add.reject!{ |obj| parsed_doc.includes_linked_object?(obj.name) }
        return editor.source if objects_to_add.size == 0
        
        editor.add_links(parsed_doc, objects_to_add, current_package)
        editor.source
      end

      private

      def filter_fn_calls(parsed_doc, fn_calls)
        parsed_doc.parse_instance_methods

        fn_calls.reject{ |fn_call| 
          parsed_doc.doc_instance_methods.map(&:name).include?(fn_call.name) 
        }
      end

      def filter_bean_calls(parsed_doc, bean_calls)
        bean_calls.select do |bean_call|
          if !bean_call.method_name
            true
          else
            method_obj = parsed_doc.doc_instance_methods.detect{ _1.name == bean_call.method_name }
            local_variables = method_obj.parse_local_variables.map(&:name)
            method_params = method_obj.param_names

            !local_variables.include?(bean_call.receiver_name) && !method_params.include?(bean_call.receiver_name)
          end
        end
      end

      def choose_object_to_add(ree_objects, current_package)
        return if !ree_objects || ree_objects.size == 0
        return ree_objects.first if ree_objects.size == 1

        current_package_object = ree_objects.detect{ _1.object_package == current_package }
        return current_package_object if current_package_object

        package_names = ree_objects.map(&:object_package)
        if package_names.sort == ['ree_date', 'ree_datetime'].sort
          return ree_objects.detect{ _1.object_package == 'ree_datetime' }
        end

        ree_object = ree_objects.first
        ree_object.set_package!('FILL_PACKAGE')
        ree_object
      end
    end
  end
end