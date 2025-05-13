# frozen_string_literal: true

RSpec.describe :build_dto do
  link :build_sqlite_connection, from: :ree_dao

  let(:connection) { build_sqlite_connection({database: 'sqlite_db'}) }

  before :all do
    Ree.enable_irb_mode
  end

  after do
    Ree.disable_irb_mode
  end

  it {
    module TestBuildDto
      include Ree::PackageDSL

      package do
        depends_on :ree_dao
        depends_on :ree_dto
      end

      class Db
        include Ree::BeanDSL

        bean :db do
          singleton
          factory :build

          link :build_sqlite_connection, from: :ree_dao
        end

        def build
          build_sqlite_connection({database: 'sqlite_db'})
        end
      end

      class Project
        include ReeDto::DSL

        build_dto do
          field :id, Nilor[Integer], default: nil
          field :is_published, Bool, default: true
        end
      end

      class ProjectsDao
        include ReeDao::DSL

        dao :projects_dao do
          link :db
        end

        schema Project do
          integer :id, null: true
          bool :is_published
        end
      end
    end

    project = TestBuildDto::Project.build(id: 1)
    expect(project.is_published).to eq(true)

    project = TestBuildDto::ProjectsDao.new.build(id: 2)
    expect(project.is_published).to eq(true)
  }
end