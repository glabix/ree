# frozen_string_literal: true

RSpec.describe :one_to_many do
  link :build_sqlite_connection, from: :ree_dao
  link :one_to_many, from: :ree_dao
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
    module TestOneToMany
      include Ree::PackageDSL

      package do
        depends_on :ree_dao
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

        def set_project_users(list)
          @project_users = list
        end

        def add_project_user(pu)
          project_users.push(pu)
        end
      end

      class ProjectUser
        include ReeDto::EntityDSL

        properties(
          id: Nilor[Integer],
          project_id: Nilor[Integer]
        )

        contract Integer => Integer
        def project_id=(id)
          @project_id = id
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

    project = TestOneToMany::Project.new(id: 1)

    project.add_project_user(
      TestOneToMany::ProjectUser.new
    )

    project.add_project_user(
      TestOneToMany::ProjectUser.new
    )

    TestOneToMany::ProjectsDao.new.put(project)
    persist_assoc(project, TestOneToMany::ProjectUsersDao.new)

    project_users_dao = TestOneToMany::ProjectUsersDao.new

    project.set_project_users([])
    one_to_many([project], project_users_dao)

    expect(project.project_users.size).to eq(2)

    project.set_project_users([])

    one_to_many(
      [project],
      project_users_dao,
      foreign_key: :project_id,
      assoc_setter: :set_project_users
    )

    expect(project.project_users.size).to eq(2)
  }
end