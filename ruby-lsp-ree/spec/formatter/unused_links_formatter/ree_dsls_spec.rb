# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  def stub_read_file(uri, source)
    allow(File).to receive(:read).with(uri.path.to_s).and_return(source)
  end

  context "files using Ree DSLs (dao)" do
    let(:ree_dao_dsl_source){
      <<~RUBY
        # frozen_string_literal: true

        package_require('ree_string/functions/underscore')

        module ReeDao::DSL
          def self.included(base)
            base.include(InstanceMethods)
          end

          def self.extended(base)
            base.include(InstanceMethods)
          end

          module InstanceMethods
            def build
              dataset_class = db.dataset_class
            end
          end
        end
      RUBY
    }

    before :each do
      dao_dsl_file_uri = URI("file:///ree_dao/package/ree_dao/dsl.rb")
      stub_read_file(dao_dsl_file_uri, ree_dao_dsl_source)
  
      with_server('') do |server, uri|
        index_class(server, 'ReeDao::DSL', dao_dsl_file_uri)
        @index = server.global_state.index 
      end

      @formatter = RubyLsp::Ree::ReeFormatter.new([], {}, @index)
    end

    it "removes unused import link" do
      source =  <<~RUBY
        class SamplePackage::SomeDao
          include ReeDao::DSL

          dao :some_dao do
            link :some_import1
          end

          def call(arg1)
          end
        end
      RUBY

      result = @formatter.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[3].strip).to eq('dao :some_dao')
      expect(result.lines[4].strip).to eq('')
    end

    it "doesn't remove import link used in dao" do
      source =  <<~RUBY
        class SamplePackage::SomeDao
          include ReeDao::DSL

          dao :some_dao do
            link :db, from: :some_db
          end

          def call(arg1)
          end
        end
      RUBY

      result = @formatter.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "doesn't remove import link from mapper" do
      source =  <<~RUBY
        class SamplePackage::SomeDtoSerializer
          include ReeMapper::DSL

          mapper :some_dto_serializer do
            link :another_serializer
          end

          build_mapper.use(:serialize) do
          end
        end 
      RUBY

      result = @formatter.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end
  end
end
