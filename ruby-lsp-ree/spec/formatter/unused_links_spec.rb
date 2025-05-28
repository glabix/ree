# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  def stub_read_file(uri, source)
    allow(File).to receive(:read).with(uri.path.to_s).and_return(source)
  end

  context "object import links" do
    it "removes unused import link" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1
            link :some_import2
          end

          def call(arg1)
            some_import2
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import2')
      expect(result.lines[3].strip).to eq('end')
    end

    it "removes do block if last unused import link removed" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1
          end
  
          def call(arg1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result.lines[1].strip).to eq('fn :some_class')
      expect(result.lines[2].strip).to eq('')
    end  

    it "doesn't remove link if it is used as a call receiver" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import_object
          end
  
          def call(arg1)
            some_import_object.call
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end
  
    it "doesn't remove link if it is used on the top level of class" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import_fn
          end
  
          x = some_import_fn
  
          def call(arg1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "doesn't remove import link if alias is used" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import, as: :some_import2
          end

          def call(arg1)
            some_import2
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import, as: :some_import2')
      expect(result.lines[3].strip).to eq('end')
    end

    it "removes import link if usage is a symbol" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1
            link :some_import2
          end

          def call(arg1)
            some_import2
            :some_import1
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import2')
      expect(result.lines[3].strip).to eq('end')
    end

    it "removes import link if usage is a call with receiver" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1
            link :some_import2
          end

          def call(arg1)
            some_import2
            my_obj = MyObj.new
            my_obj.some_import1
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import2')
      expect(result.lines[3].strip).to eq('end')
    end
  end

  context "object links with constants import" do
    it "doesn't remove link if imported constant is used" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst }
          end
  
          def call(arg1)
            SomeConst
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end
  
    it "removes unused import link if constant is not used" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst }
            link :some_import2
          end
  
          def call(arg1)
            some_import2
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import2')
      expect(result.lines[3].strip).to eq('end')
    end
  
    it "removes import block if constant is not used but link is used" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst }
          end
  
          def call(arg1)
            some_import1
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import1')
      expect(result.lines[3].strip).to eq('end')
    end

    it "removes import link if usage is a symbol" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst }
            link :some_import2
          end

          def call(arg1)
            some_import2
            :SomeConst
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import2')
      expect(result.lines[3].strip).to eq('end')
    end

    it "doesn't remove import link if usage is an object call" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst }
            link :some_import2
          end

          def call(arg1)
            some_import2
            raise SomeConst.new
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    context "multi-constant imports" do
      it "removes unused constant from the first place" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { SomeConst1 & SomeConst2 }
            end
    
            def call(arg1)
              SomeConst2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst2 }')
        expect(result.lines[3].strip).to eq('end')
      end    

      it "removes unused constant from the last place" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { SomeConst1 & SomeConst2 }
            end
    
            def call(arg1)
              SomeConst1
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst1 }')
        expect(result.lines[3].strip).to eq('end')
      end
      
      it "removes unused constant from the middle place" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { SomeConst1 & SomeConst2 & SomeConst3 }
            end
    
            def call(arg1)
              SomeConst1
              SomeConst3
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst1 & SomeConst3 }')
        expect(result.lines[3].strip).to eq('end')
      end
    end

    context "multi-line imports" do
      it "correctly removes link for unused constant" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { 
                SomeConst
              }
              link :some_import2
            end
    
            def call(arg1)
              some_import2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import2')
        expect(result.lines[3].strip).to eq('end')
      end
  
      it "correctly removes import block constant" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { 
                SomeConst
              }
            end
    
            def call(arg1)
              some_import1
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))

        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import1')
        expect(result.lines[3].strip).to eq('end')
      end
      
      it "correctly removes unused constant from new line" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { 
                SomeConst &
                SomeConst1 &
                SomeConst2
              }
            end
    
            def call(arg1)
              SomeConst
              SomeConst2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))

        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst & SomeConst2 }')
        expect(result.lines[3].strip).to eq('end')
      end

      it "correctly removes unused constant from same line" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link :some_import1, import: -> { 
                SomeConst & SomeConst1 & SomeConst2
              }
            end
    
            def call(arg1)
              SomeConst
              SomeConst2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))

        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst & SomeConst2 }')
        expect(result.lines[3].strip).to eq('end')
      end
    end
  end

  context "file-path links with constants import" do
    it "removes unused import link for file-path imports" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link "some/file/path", -> { SomeConst }
            link :some_import
          end
  
          def call(arg1)
            some_import
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import')
      expect(result.lines[3].strip).to eq('end')
    end

    it "removes both file-path and object imports" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link "some/file/path", -> { SomeConst }
            link :some_import
          end
  
          def call(arg1)
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class')
    end

    context "multi-constant imports" do
      it "removes unused constant from the first place" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link "some/file/path", -> { SomeConst1 & SomeConst2 }
            end
    
            def call(arg1)
              SomeConst2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link "some/file/path", -> { SomeConst2 }')
        expect(result.lines[3].strip).to eq('end')
      end    

      it "removes unused constant from the last place" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link "some/file/path", -> { SomeConst1 & SomeConst2 }
            end
    
            def call(arg1)
              SomeConst1
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link "some/file/path", -> { SomeConst1 }')
        expect(result.lines[3].strip).to eq('end')
      end
      
      it "removes unused constant from the middle place" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link "some/file/path", -> { SomeConst1 & SomeConst2 & SomeConst3 }
            end
    
            def call(arg1)
              SomeConst1
              SomeConst3
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link "some/file/path", -> { SomeConst1 & SomeConst3 }')
        expect(result.lines[3].strip).to eq('end')
      end
    end
  
    context "multi-line imports" do
      it "correctly removes link for unused constant" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link "some/file/path", -> { 
                SomeConst
              }
              link :some_import2
            end
    
            def call(arg1)
              some_import2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))
    
        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link :some_import2')
        expect(result.lines[3].strip).to eq('end')
      end
      
      it "correctly removes unused constant from new line" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link "some/file/path", -> { 
                SomeConst &
                SomeConst1 &
                SomeConst2
              }
            end
    
            def call(arg1)
              SomeConst
              SomeConst2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))

        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link "some/file/path", -> { SomeConst & SomeConst2 }')
        expect(result.lines[3].strip).to eq('end')
      end

      it "correctly removes unused constant from same line" do
        source =  <<~RUBY
          class SamplePackage::SomeClass
            fn :some_class do
              link "some/file/path", -> { 
                SomeConst & SomeConst1 & SomeConst2
              }
            end
    
            def call(arg1)
              SomeConst
              SomeConst2
            end
          end
        RUBY
    
        result = subject.run_formatting(sample_file_uri, ruby_document(source))

        expect(result.lines[1].strip).to eq('fn :some_class do')
        expect(result.lines[2].strip).to eq('link "some/file/path", -> { SomeConst & SomeConst2 }')
        expect(result.lines[3].strip).to eq('end')
      end
    end
  end

  context "aliased constants" do
    it "removes unused import link" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst.as(MyConst) }
          end

          def call(arg1)
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class')
      expect(result.lines[2].strip).to eq('')
    end

    it "doesn't remove used constant" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { SomeConst.as(MyConst) }
          end

          def call(arg1)
            MyConst
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "correctly handles multiple constants with aliases" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import1, import: -> { 
              SomeConst1.as(MyConst) & SomeConst2 & 
              SomeConst3.as(UnusedConst) & SomeConst4 
            }
          end

          def call(arg1)
            MyConst
            SomeConst4
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq('link :some_import1, import: -> { SomeConst1.as(MyConst) & SomeConst4 }')
      expect(result.lines[3].strip).to eq('end')
    end
  end

  context "files with links via LinkDSL" do
    it "removes unused import link" do
      source =  <<~RUBY
        class SamplePackage::SomeEntity
          include Ree::LinkDSL

          link :some_import1
          link :some_import2

          def call(arg1)
            some_import2
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[2].strip).to eq('')
      expect(result.lines[3].strip).to eq('link :some_import2')
      expect(result.lines[4].strip).to eq('')
    end

    it "coorectly removes last link" do
      source =  <<~RUBY
        class SamplePackage::SomeEntity
          include Ree::LinkDSL

          link :some_import1

          def call(arg1)
          end
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[2].strip).to eq('')
      expect(result.lines[3].strip).to eq('')
    end

    it "removes unused import link if constant is not used" do
      source =  <<~RUBY
        class SamplePackage::SomeEntity
          include Ree::LinkDSL

          link :some_import1, import: -> { SomeConst }
          link :some_import2
  
          def call(arg1)
            some_import2
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[2].strip).to eq('')
      expect(result.lines[3].strip).to eq('link :some_import2')
      expect(result.lines[4].strip).to eq('')
    end

    it "correctly removes unused constant from new line" do
      source =  <<~RUBY
        class SamplePackage::SomeEntity
          include Ree::LinkDSL
            
          link :some_import1, import: -> { 
            SomeConst &
            SomeConst1 &
            SomeConst2
          }
  
          def call(arg1)
            SomeConst
            SomeConst2
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[2].strip).to eq('')
      expect(result.lines[3].strip).to eq('link :some_import1, import: -> { SomeConst & SomeConst2 }')
      expect(result.lines[4].strip).to eq('')
    end
  end

  context "spec files" do
    it "removes unused import link" do
      source =  <<~RUBY
        package_require("some_package/services/some_class")

        RSpec.describe SamplePackage::SomeClass, type: [:autoclean] do
          link :some_import1
          link :some_import2

          it {
            some_import2
          }
        end
      RUBY

      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[3].strip).to eq('link :some_import2')
      expect(result.lines[4].strip).to eq('')
    end

    it "removes unused import link if constant is not used" do
      source =  <<~RUBY
        package_require("some_package/services/some_class")

        RSpec.describe SamplePackage::SomeClass, type: [:autoclean] do
          link :some_import1, import: -> { SomeConst }
          link :some_import2

          it {
            some_import2
          }
        end
      RUBY
      
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[3].strip).to eq('link :some_import2')
      expect(result.lines[4].strip).to eq('')
    end

    it "correctly removes unused constant from new line" do
      source =  <<~RUBY
        package_require("some_package/services/some_class")

        RSpec.describe SamplePackage::SomeClass, type: [:autoclean] do
          link :some_import1, import: -> { 
            SomeConst &
            SomeConst1 &
            SomeConst2
          }

          it {
            SomeConst
            SomeConst2
          }
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))

      expect(result.lines[3].strip).to eq('link :some_import1, import: -> { SomeConst & SomeConst2 }')
      expect(result.lines[4].strip).to eq('')
    end
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
