# frozen_string_literal: true

RSpec.describe :persist_assoc do
  link :build_sqlite_connection, from: :ree_dao
  link :persist_assoc, from: :ree_dao

  let(:connection) { build_sqlite_connection({database: 'sqlite_db'}) }

  before :all do
    Ree.enable_irb_mode
  end

  before :each do
    [:projects, :project_users].each do |name|
      if connection.table_exists?(name)
        connection.drop_table(name)
      end
    end

    connection.create_table :projects do
      primary_key :id
    end

    connection.create_table :project_users do
      primary_key :id
      foreign_key :project_id, :projects, null: false, on_delete: :cascade
    end

    connection.disconnect
  end

  after do
    Ree.disable_irb_mode
    connection.disconnect
  end

  it {
    module TestPersistAssoc
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
        include ReeDto::EntityDSL

        properties(
          id: Nilor[Integer]
        )

        def project_users
          @project_users ||= []
        end

        def add_project_user(pu)
          project_users.push(pu)
        end
      end

      class ProjectUser
        include ReeDto::DSL

        build_dto do
          field :id, Nilor[Integer], default: nil
          field :project_id, Integer
        end
      end

      class ProjectsDao
        include ReeDao::DSL

        dao :projects_dao do
          link :db
        end

        schema Project do
          integer :id, null: true
        end
      end

      class ProjectUsersDao
        include ReeDao::DSL

        dao :project_users_dao do
          link :db
        end

        schema ProjectUser do
          integer :id, null: true
          integer :project_id
        end
      end
    end

    project = TestPersistAssoc::Project.new(id: 1)

    project.add_project_user(
      TestPersistAssoc::ProjectUser.new
    )

    project.add_project_user(
      TestPersistAssoc::ProjectUser.new
    )

    TestPersistAssoc::ProjectsDao.new.put(project)

    TestPersistAssoc::ProjectUsersDao.new.persist(
      project.project_users.first,
      project.project_users,
      project.project_users.to_a,
      set: {project_id: project.id}
    )

    expect(project.id).to be_a(Integer)
    expect(project.project_users.first.id).to be_a(Integer)
    expect(project.project_users.first.project_id).to eq(project.id)
    expect(project.project_users.last.id).to be_a(Integer)
    expect(project.project_users.last.project_id).to eq(project.id)

    # test opts
    project = TestPersistAssoc::Project.new(id: 2)

    project.add_project_user(
      TestPersistAssoc::ProjectUser.new
    )

    project.add_project_user(
      TestPersistAssoc::ProjectUser.new
    )

    TestPersistAssoc::ProjectsDao.new.put(project)

    persist_assoc(
      project,
      TestPersistAssoc::ProjectUsersDao.new,
      root_setter: :project_id=,
      child_assoc: :project_users,
    )

    expect(project.id).to be_a(Integer)
    expect(project.project_users.first.id).to be_a(Integer)
    expect(project.project_users.first.project_id).to eq(project.id)
    expect(project.project_users.last.id).to be_a(Integer)
    expect(project.project_users.last.project_id).to eq(project.id)
  }
end