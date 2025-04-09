# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([]) }

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
  # TODO it "removes unused import link for file-path imports" do
  # TODO it "removes unused import arg for file-path imports" do
  # TODO it "removes unused constant for file-path multi-constant import" do
  # TODO it "removes unused constant from import if not used" do    
  end

  context "file with DSLs" do
    # TODO it "removes unused import link from DSL-using object" do    
  end

  context "spec files" do
    # TODO it "removes unused import link from spec" do
  end
end
