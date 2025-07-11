# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}, ) }

  it "removes unused import link for file-path imports" do
    source =  <<~RUBY
      class SamplePackage::SomeClass
        fn :some_class do
          link 'some/file/path', -> { SomeConst }
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
          link 'some/file/path', -> { SomeConst }
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
            link 'some/file/path', -> { SomeConst1 & SomeConst2 }
          end
  
          def call(arg1)
            SomeConst2
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq("link 'some/file/path', -> { SomeConst2 }")
      expect(result.lines[3].strip).to eq('end')
    end    

    it "removes unused constant from the last place" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link 'some/file/path', -> { SomeConst1 & SomeConst2 }
          end
  
          def call(arg1)
            SomeConst1
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq("link 'some/file/path', -> { SomeConst1 }")
      expect(result.lines[3].strip).to eq('end')
    end
    
    it "removes unused constant from the middle place" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link 'some/file/path', -> { SomeConst1 & SomeConst2 & SomeConst3 }
          end
  
          def call(arg1)
            SomeConst1
            SomeConst3
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
  
      expect(result.lines[1].strip).to eq('fn :some_class do')
      expect(result.lines[2].strip).to eq("link 'some/file/path', -> { SomeConst1 & SomeConst3 }")
      expect(result.lines[3].strip).to eq('end')
    end
  end

  context "multi-line imports" do
    it "correctly removes link for unused constant" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link 'some/file/path', -> { 
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
            link 'some/file/path', -> { 
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
      expect(result.lines[2].strip).to eq("link 'some/file/path', -> { SomeConst & SomeConst2 }")
      expect(result.lines[3].strip).to eq('end')
    end

    it "correctly removes unused constant from same line" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link 'some/file/path', -> { 
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
      expect(result.lines[2].strip).to eq("link 'some/file/path', -> { SomeConst & SomeConst2 }")
      expect(result.lines[3].strip).to eq('end')
    end
  end

  context "consts in contracts" do  
    it "doesn't remove import link used in contract" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import
            link 'some/file/path', -> { SomeConst }
          end
  
          contract(SomeConst => Hash) 
          def call(arg1)
            some_import
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "doesn't remove import link used in multi-arg contract" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import
            link 'some/file/path', -> { SomeConst }
          end
  
          contract(Integer, SomeConst => Hash) 
          def call(arg1, arg2)
            some_import
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "doesn't remove import link used as return value" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import
            link 'some/file/path', -> { SomeConst }
          end
  
          contract(Integer => SomeConst) 
          def call(arg1)
            some_import
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "doesn't remove import link used as throw value" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import
            link 'some/file/path', -> { SomeConst }
          end
  
          contract(Integer => Hash).throws(NoMethodError & SomeConst) 
          def call(arg1)
            some_import
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end

    it "doesn't remove import link used in contract as nested type" do
      source =  <<~RUBY
        class SamplePackage::SomeClass
          fn :some_class do
            link :some_import
            link 'some/file/path', -> { SomeConst }
          end
  
          contract(ArrayOf[SomeConst] => Hash) 
          def call(arg1)
            some_import
          end
        end
      RUBY
  
      result = subject.run_formatting(sample_file_uri, ruby_document(source))
      expect(result).to eq(source)
    end
  end
end