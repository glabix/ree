# frozen_string_literal: true
require 'faker'
require 'benchmark'

RSpec.describe :load_agg do
  link :build_sqlite_connection, from: :ree_dao
  link :load_agg, from: :ree_dao

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_sqlite_connection({database: 'sqlite_db',  pool_timeout: 30, max_connections: 100})

    connection.drop_table(:organizations) if connection.table_exists?(:organizations)
    connection.drop_table(:users) if connection.table_exists?(:users)
    connection.drop_table(:user_passports) if connection.table_exists?(:user_passports)
    connection.drop_table(:books) if connection.table_exists?(:books)
    connection.drop_table(:chapters) if connection.table_exists?(:chapters)
    connection.drop_table(:authors) if connection.table_exists?(:authors)
    connection.drop_table(:reviews) if connection.table_exists?(:reviews)
    connection.drop_table(:review_authors) if connection.table_exists?(:review_authors)

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

    connection.create_table :review_authors do
      primary_key :id

      foreign_key :review_id, :reviews, null: false, on_delete: :cascade
      column :name, 'varchar(256)'
    end

    connection.create_table :authors do
      primary_key :id

      foreign_key :book_id, :books, null: false, on_delete: :cascade
      column  :name, 'varchar(256)'
    end

    connection.disconnect
  end

  require_relative 'ree_dao_load_agg_test'

  class ReeDaoLoadAggTest::UsersAgg
    include ReeDao::AggregateDSL

    aggregate :users_agg do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :user_passports, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :chapters, from: :ree_dao_load_agg_test
      link :authors, from: :ree_dao_load_agg_test
      link :reviews, from: :ree_dao_load_agg_test
      link :review_authors, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call
      load_agg(users.by_name("John"), users) do
        field :custom_field, books.where(title: "1984")
        belongs_to :organization

        has_many :books do
          has_one :author
          has_many :chapters
          
          has_many :reviews do
            has_one :review_author
          end
        end

        has_one :passport, foreign_key: :user_id, assoc_dao: user_passports
      end
    end
  end

  let(:users_agg) { ReeDaoLoadAggTest::UsersAgg.new }
  let(:organizations) { ReeDaoLoadAggTest::Organizations.new }
  let(:users) { ReeDaoLoadAggTest::Users.new }
  let(:user_passports) { ReeDaoLoadAggTest::UserPassports.new }
  let(:books) { ReeDaoLoadAggTest::Books.new }
  let(:chapters) { ReeDaoLoadAggTest::Chapters.new }
  let(:authors) { ReeDaoLoadAggTest::Authors.new }
  let(:reviews) { ReeDaoLoadAggTest::Reviews.new }
  let(:review_authors) { ReeDaoLoadAggTest::ReviewAuthors.new }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoLoadAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    passport_1 = ReeDaoLoadAggTest::UserPassport.new(user_id: user_1.id, info: "some info")
    user_passports.put(passport_1)
    user_passports.put(ReeDaoLoadAggTest::UserPassport.new(user_id: user_2.id, info: "another info"))

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "ending"))


    authors.put(ReeDaoLoadAggTest::Author.new(book_id: book_1.id, name: "George Orwell"))
    review = ReeDaoLoadAggTest::Review.new(book_id: book_1.id, rating: 10)
    reviews.put(review)
    reviews.put(ReeDaoLoadAggTest::Review.new(book_id: book_1.id, rating: 7))
    review_authors.put(ReeDaoLoadAggTest::ReviewAuthor.new(review_id: review.id, name: "John Review"))

    res = users_agg.call()

    res_user = res[0]
    expect(res_user.id).to eq(user_1.id)
    expect(res_user.organization).to eq(organization)
    expect(res_user.passport).to eq(passport_1)
    expect(res_user.passport.info).to eq("some info")
    expect(res_user.books.count).to eq(2)
    expect(res_user.books[0].author.name).to eq("George Orwell")
    expect(res_user.books[0].chapters.count).to eq(3)
    expect(res_user.books[0].reviews[0].review_author.name).to eq("John Review")
    expect(res_user.custom_field).to_not eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoLoadAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    ids = [user_1, user_2].map(&:id)

    res = load_agg(ids, users)
    expect(res.count).to eq(2)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    res = load_agg(user_1.id, users)
    expect(res.count).to eq(1)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoLoadAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    res = load_agg(users.where(organization_id: organization.id), users)
    expect(res.count).to eq(2)
  }
end