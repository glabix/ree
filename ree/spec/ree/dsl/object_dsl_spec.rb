# frozen_string_literal: true

RSpec.describe Ree::ObjectDsl do
  before :all do
    Ree.enable_irb_mode
  end

  after :all do
    Ree.disable_irb_mode
  end

  Ree.enable_irb_mode

  module ObjectDslPackage
    include Ree::PackageDSL
    package
  end

  module TestObjectDsl
    include Ree::PackageDSL
    package

    class TestFn
      def self.call
        1
      end
    end

    class TestFn2
      include Ree::FnDSL

      fn :test_fn2

      class ImportClass
        def self.call
          3
        end
      end

      class ImportClass2
        def self.call
          4
        end
      end

      def call
        2
      end
    end
  end

  Ree.disable_irb_mode

  it 'does not allow to use dsl for anonymous classes' do
    expect {
      module ObjectDslPackage
        Class.new do
          include Ree::FnDSL

          fn :anonymous_class_fn
        end
      end
    }.to raise_error(Ree::Error) do |e|
      expect(e.message).to eq("Anonymous classes are not supported")
    end
  end

  it 'does not allow top level objects' do
    expect {
      class ObjectDslPackageTopLevelClass
        include Ree::FnDSL

        fn :top_level_class_fn
      end
    }.to raise_error(Ree::Error) do |e|
      expect(e.message).to eq("Object declarations should only appear for classes declared inside modules")
    end
  end

  it 'it does not allow to use dsl for deeply nested submodules' do
    expect {
      module ObjectDslPackage
        module Level2
          module Level3
            class DeeplyNestedClass
              include Ree::FnDSL

              fn :deeply_nested_class
            end
          end
        end
      end
    }.to raise_error(Ree::Error) do |e|
      expect(e.message).to eq("Objects should be declared inside parent modules or inside there submodules")
    end
  end

  it 'checks object name & corresponding class name' do
    expect {
      class ObjectDslPackage::ObjectClass
        include Ree::FnDSL

        fn :object
      end
    }.to raise_error(Ree::Error) do |e|
      expect(e.message).to eq(":object does not correspond to class name ObjectClass. Change object name to 'object_class' or change name of the class")
    end
  end

  it "allows const import from packages" do
    module ObjectDslPackage
      class ObjectClass1
        include Ree::BeanDSL

        bean :object_class1 do
          import -> { TestFn2::ImportClass2 & TestFn2::ImportClass.as(ImportedClass) }, from: :test_object_dsl        
        end

        def call1
          ImportClass2.call
        end

        def call2
          ImportedClass.call
        end
      end
    end

    expect(ObjectDslPackage::ObjectClass1.new.call1).to eq(4)
    expect(ObjectDslPackage::ObjectClass1.new.call2).to eq(3)
  end

  it "allows const import of top level const" do
    module ObjectDslPackage
      class ObjectClass7
        include Ree::BeanDSL

        bean :object_class7 do
          import -> { TestFn.as(ImportedClass) }, from: :test_object_dsl        
        end

        def call
          ImportedClass.call
        end
      end
    end

    expect(ObjectDslPackage::ObjectClass7.new.call).to eq(1)
  end

  it "allows const import from fns" do
    module ObjectDslPackage
      include Ree::PackageDSL
      package
    
      class ObjectClass2
        include Ree::BeanDSL

        bean :object_class2 do
          import :test_fn2, -> { ImportClass2.as(ImportedClass) }, from: :test_object_dsl        
        end

        def call
          ImportedClass.call
        end
      end
    end

    expect(ObjectDslPackage::ObjectClass2.new.call).to eq(4)
  end
  it "allows const import from current package fn" do
    module ObjectDslPackage
      include Ree::PackageDSL
      package
    
      class ObjectClass5
        include Ree::FnDSL

        fn :object_class5

        class ImportClass
          def self.call
            6
          end
        end
      end

      class ObjectClass6
        include Ree::BeanDSL

        bean :object_class6 do
          import :object_class5, -> { ImportClass.as(ImportedClass) }
        end

        def call
          ImportedClass.call
        end
      end
    end

    expect(ObjectDslPackage::ObjectClass6.new.call).to eq(6)
  end
end