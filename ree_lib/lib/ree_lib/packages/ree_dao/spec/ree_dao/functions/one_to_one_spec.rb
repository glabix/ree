# frozen_string_literal: true

RSpec.describe :one_to_one do
  link :build_sqlite_connection, from: :ree_dao
  link :one_to_one, from: :ree_dao
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

    connection.alter_table :projects do
      add_foreign_key :project_user_id, :project_users, on_delete: :cascade
    end

    connection.disconnect
  end

  after do
    Ree.disable_irb_mode
    connection.disconnect
  end

  it {
    module TestOneToOne
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

        def project_user
          @project_user
        end

        def project_user_id=(id)
          @project_user_id = id
        end

        attr_reader :project_user_id

        def set_project_user(pu)
          @project_user = pu
        end

        def project_users
          [@project_user]
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
          integer :project_user_id, null: true
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

    project = TestOneToOne::Project.new(id: 1)

    project.set_project_user(
      TestOneToOne::ProjectUser.new
    )

    TestOneToOne::ProjectsDao.new.put(project)
    persist_assoc(project, TestOneToOne::ProjectUsersDao.new)

    project.project_user_id = project.project_users.first.id
    persist_assoc(project, TestOneToOne::ProjectUsersDao.new)

    project_users_dao = TestOneToOne::ProjectUsersDao.new

    project.set_project_user(nil)
    one_to_one([project], project_users_dao)

    expect(project.project_user.project_id).to eq(project.id)

    project.set_project_user(nil)

    one_to_one(
      [project],
      project_users_dao,
      reverse: true,
      foreign_key: :project_id,
      assoc_setter: :set_project_user
    )

    expect(project.project_user.project_id).to eq(project.id)

    project.set_project_user(nil)

    one_to_one(
      [project],
      project_users_dao,
      reverse: true,
      assoc_setter: :set_project_user
    )

    expect(project.project_user.project_id).to eq(project.id)
  }
end