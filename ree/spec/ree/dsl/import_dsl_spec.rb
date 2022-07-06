# frozen_string_literal  = true

RSpec.describe Ree::ImportDsl do
  context "first constant is not declared in the parent scope" do
    it {
      module TestModule1
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  MissingClass.as(Missing) & ExistingClass & FOO.as(FOO_CONST) & EXISTING_CONST
                }
              )
            end
          end
        end
      end

      result = TestModule1::TestClass.result
      list = [result] + result.constants

      expect(list.map(&:name)).to eq(['MissingClass', 'ExistingClass', 'FOO', 'EXISTING_CONST'])
    }
  end

  context "first constant is declared in the parent scope" do
    it {
      module TestModule2
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  ExistingClass & MissingClass.as(Missing) & EXISTING_CONST & FOO.as(FOO_CONST)
                }
              )
            end
          end
        end
      end

      result = TestModule2::TestClass.result
      list = [result] + result.constants

      expect(list.map(&:name)).to eq(['ExistingClass', 'MissingClass', 'EXISTING_CONST', 'FOO'])
    }
  end

  context "first constant is a missing constant" do
    it {
      module TestModule3
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  FOO.as(FOO_CONST) & MissingClass.as(Missing)
                }
              )
            end
          end
        end
      end

      result = TestModule3::TestClass.result
      list = [result] + result.constants

      expect(list.map(&:name)).to eq(['FOO', 'MissingClass'])
    }
  end

  context "first constant is an existing constant" do
    it {
      module TestModule4
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  EXISTING_CONST & FOO.as(FOO_CONST) & MissingClass.as(Missing)
                }
              )
            end
          end
        end
      end

      result = TestModule4::TestClass.result
      list = [result] + result.constants

      expect(list.map(&:name)).to eq(['EXISTING_CONST', 'FOO', 'MissingClass'])
    }
  end
end
