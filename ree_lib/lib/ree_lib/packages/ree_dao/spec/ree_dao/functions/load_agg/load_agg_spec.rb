# frozen_string_literal: true

RSpec.describe :load_agg do
  link :build_sqlite_connection, from: :ree_dao
  link :load_agg, from: :ree_dao

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_sqlite_connection({database: 'sqlite_db'})

    connection.drop_table(:organizations) if connection.table_exists?(:organizations)
    connection.drop_table(:users) if connection.table_exists?(:users)
    connection.drop_table(:user_passports) if connection.table_exists?(:user_passports)
    connection.drop_table(:books) if connection.table_exists?(:books)
    connection.drop_table(:chapters) if connection.table_exists?(:chapters)
    connection.drop_table(:authors) if connection.table_exists?(:authors)
    connection.drop_table(:reviews) if connection.table_exists?(:reviews)

    connection.create_table :organizations do
      primary_key :id

      column  :name, 'varchar(256)'
    end

    connection.create_table :users do
      primary_key :id

      column  :name, 'varchar(256)'
      column  :age, :integer
      foreign_key :organization_id, :organizations, null: false, on_delete: :cascade
    end

    connection.create_table :user_passports do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :info, 'varchar(256)'
    end

    connection.create_table :books do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :chapters do
      primary_key :id

      foreign_key :book_id, :books, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :reviews do
      primary_key :id

      foreign_key :book_id, :books, null: false, on_delete: :cascade
      column  :rating, :integer
    end

    connection.create_table :authors do
      primary_key :id

      foreign_key :book_id, :books, null: false, on_delete: :cascade
      column  :name, 'varchar(256)'
    end

    connection.disconnect
  end

  require_relative 'ree_dao_test'

  class ReeDaoTest::UsersAgg
    include ReeDao::AggregateDSL

    aggregate :users_agg do
      link :users, from: :ree_dao_test
      link :organizations, from: :ree_dao_test
      link :user_passports, from: :ree_dao_test
      link :books, from: :ree_dao_test
      link :chapters, from: :ree_dao_test
      link :authors, from: :ree_dao_test
      link :reviews, from: :ree_dao_test
      link :load_agg, from: :ree_dao
    end

    def call
      load_agg(users.by_name("John"), users) do |list|
        belongs_to :organization, list: list
        has_one :passport, foreign_key: :user_id, assoc_dao: user_passports, list: list

        has_many :books, list: list do |list|
          has_many :chapters, list: list
          has_many :reviews, list: list
        end
      end
    end
  end

  let(:users_agg) { ReeDaoTest::UsersAgg.new }
  let(:organizations) { ReeDaoTest::Organizations.new }
  let(:users) { ReeDaoTest::Users.new }
  let(:user_passports) { ReeDaoTest::UserPassports.new }
  let(:books) { ReeDaoTest::Books.new }
  let(:chapters) { ReeDaoTest::Chapters.new }
  let(:authors) { ReeDaoTest::Authors.new }
  let(:reviews) { ReeDaoTest::Reviews.new }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    passport_1 = ReeDaoTest::UserPassport.new(user_id: user_1.id, info: "some info")
    user_passports.put(passport_1)
    user_passports.put(ReeDaoTest::UserPassport.new(user_id: user_2.id, info: "another info"))

    book_1 = ReeDaoTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoTest::Book.new(user_id: user_1.id, title: "1984")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoTest::Chapter.new(book_id: book_2.id, title: "ending"))


    authors.put(ReeDaoTest::Author.new(book_id: book_1.id, name: "George Orwell"))
    reviews.put(ReeDaoTest::Review.new(book_id: book_1.id, rating: 10))
    reviews.put(ReeDaoTest::Review.new(book_id: book_1.id, rating: 7))

    # TODO: move this test to aggregate dsl spec
    res = users_agg.call()

    expect(res[0].organization).to eq(organization)
    expect(res[0].passport).to eq(passport_1)
    expect(res[0].passport.info).to eq("some info")
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    ids = [user_1, user_2].map(&:id)

    res = load_agg(ids, users)
    expect(res.count).to eq(2)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    res = load_agg(user_1.id, users)
    expect(res.count).to eq(1)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    res = load_agg(users.where(name: "John"), users)
    expect(res.count).to eq(1)
  }
end