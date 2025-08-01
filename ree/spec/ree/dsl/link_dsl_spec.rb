# frozen_string_literal: true

RSpec.describe Ree::LinkDSL do
  Ree.enable_irb_mode

  module TestLinkDsl
    include Ree::PackageDSL

    package

    class TestFn
      include Ree::FnDSL

      fn :test_fn

      def call
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

  context "single-object links" do
    it {
      class TestClass
        include Ree::LinkDSL

        link :test_fn, from: :test_link_dsl

        def call
          test_fn
        end
      end

      expect(TestClass.new.call).to eq(1)
    }

    it {
      class TestLinkDsl::TestClass
        include Ree::LinkDSL

        link :test_fn

        def call
          test_fn
        end
      end

      expect(TestClass.new.call).to eq(1)
    }

    it {
      expect {
        class TestClass
          include Ree::LinkDSL

          link :test_fn

          def call
            test_fn
          end
        end
      }.to raise_error do |e|
        expect(e.code).to eq(:invalid_dsl_usage)
        expect(e.message).to eq("package is not provided for link :test_fn")
      end
    }

  end

  context "multi-object links" do
    it {
      class TestClass
        include Ree::LinkDSL

        link :test_fn, :test_fn2, from: :test_link_dsl

        def call
          test_fn2
        end
      end

      expect(TestClass.new.call).to eq(2)
    }

    it {
      class TestLinkDsl::TestClass
        include Ree::LinkDSL

        link :test_fn, :test_fn2

        def call
          test_fn
        end
      end

      expect(TestClass.new.call).to eq(2)
    }

    it {
      expect {
        class TestClass
          include Ree::LinkDSL

          link :test_fn, :test_fn2

          def call
            test_fn2
          end
        end
      }.to raise_error do |e|
        expect(e.code).to eq(:invalid_dsl_usage)
        expect(e.message).to eq("package is not provided for link :test_fn")
      end
    }

    it {
      expect {
        class TestClass
          include Ree::LinkDSL

          link :test_fn, :test_fn2, from: :test_link_dsl, target: :both

          def call
            test_fn2
          end
        end
      }.to raise_error do |e|
        expect(e.code).to eq(:invalid_link_option)
        expect(e.message).to eq("options [:target] are not allowed for multi-object links")
      end
    }
  end

  context "import links" do
    it {
      class TestClass
        include Ree::LinkDSL

        import :test_fn2, -> { ImportClass }, from: :test_link_dsl

        def call
          ImportClass.call
        end
      end

      expect(TestClass.new.call).to eq(3)
    }

    it {
      class TestLinkDsl::TestClass
        include Ree::LinkDSL

        import :test_fn2, -> { ImportClass2.as(ImportedClass) }

        def call
          ImportedClass.call
        end
      end

      expect(TestLinkDsl::TestClass.new.call).to eq(4)
    }

    it {
      class TestClass
        include Ree::LinkDSL

        import -> { TestFn2.as(TestFn) }, from: :test_link_dsl

        def call
          TestFn.new.call
        end
      end

      expect(TestClass.new.call).to eq(2)
    }

    it {
      class TestLinkDsl::TestClass
        include Ree::LinkDSL

        import -> { TestFn2 }

        def call
          TestFn2.new.call
        end
      end

      expect(TestLinkDsl::TestClass.new.call).to eq(2)
    }

    it {
      class TestClass
        include Ree::LinkDSL

        import -> { TestFn2::ImportClass2 & TestFn2::ImportClass.as(ImportedClass) }, from: :test_link_dsl

        def call1
          ImportClass2.call
        end

        def call2
          ImportedClass.call
        end
      end

      expect(TestClass.new.call1).to eq(4)
      expect(TestClass.new.call2).to eq(3)
    }
  end
end