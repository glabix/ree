# frozen_string_literal: true
require 'faker'
require 'benchmark'

RSpec.describe :agg do
  link :agg, from: :ree_dao
  link :build_pg_connection, from: :ree_dao

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_pg_connection(ReeDaoAggTest::Db::DB_CONFIG)

    [
      :organizations, :users, :user_passports, :books, :chapters, :avtorki,
      :reviews, :review_authors
    ].each do |table|
      connection.drop_table(table, cascade: true) if connection.table_exists?(table)
    end

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

    connection.create_table :avtorki do
      primary_key :id

      foreign_key :book_id, :books, null: false, on_delete: :cascade
      column  :name, 'varchar(256)'
    end

    connection.disconnect
  end

  require_relative 'ree_dao_agg_test'

  class ReeDaoAggTest::AggUsers
    include ReeDao::AggregateDSL

    aggregate :agg_users do
      link :users, from: :ree_dao_agg_test, import: -> { User }
      link :organizations_dao, from: :ree_dao_agg_test
      link :user_passports, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :chapters, from: :ree_dao_agg_test
      link :authors, from: :ree_dao_agg_test
      link :reviews, from: :ree_dao_agg_test
      link :review_authors, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    agg_contract_for User
    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do |users_list|
        belongs_to :organization
        has_many :books do |books_list|
          has_one :author
          has_many :chapters

          has_many :reviews, -> { reviews_opts } do |reviews_list|
            has_one :review_author

            field :review_calculatetable_field, -> { some_method(reviews_list) }
          end

          field :book_calculatetable_field, -> { change_book_titles(books_list) }
        end

        has_one :passport, -> { passport_opts }
        has_one :custom_field, -> { custom_field_opts }

        field :user_calculatetable_field, -> { some_method(users_list) }
      end
    end

    private

    def change_book_titles(books_list)
      books_list.each do |book|
        book.title = "#{book.title.upcase} changed"
      end
    end

    def some_method(list)
      list.each { _1.some_field = :some_value if _1.respond_to?(:some_field=) }
    end

    def passport_opts
      {
        foreign_key: :user_id,
        scope: user_passports
      }
    end

    def custom_field_opts
      {
        scope: books.where(title: "1984")
      }
    end

    def reviews_opts
      { autoload_children: true }
    end
  end

  class ReeDaoAggTest::AggUsersWithDto
    include ReeDao::AggregateDSL

    aggregate :agg_users_with_dto do
      link :users, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :authors, from: :ree_dao_agg_test
      link :chapters, from: :ree_dao_agg_test
      link :organizations_dao, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        belongs_to :organization

        has_many :books, -> { books_opts } do
          has_one :author, -> { author_opts }
          has_many :chapters, -> { chapters_opts }
        end
      end
    end

    private

    def books_opts
      {
        to_dto: -> (book) { ReeDaoAggTest::BookDto.new(book) },
        setter: -> (item, child_index) {
          item.books = child_index[item.id] || []
        }
      }
    end

    def author_opts
      { to_dto: -> (author) { ReeDaoAggTest::AuthorDto.new(author) }}
    end

    def chapters_opts
      { to_dto: -> (chapter) { ReeDaoAggTest::ChapterDto.new(chapter) }}
    end
  end

  class ReeDaoAggTest::AggUsersAutoloadBooksChildren
    include ReeDao::AggregateDSL

    aggregate :agg_users_autoload_books_children do
      link :users, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :chapters, from: :ree_dao_agg_test
      link :authors, from: :ree_dao_agg_test
      link :reviews, from: :ree_dao_agg_test
      link :review_authors, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        belongs_to :organization
        has_many :books, -> { books_opts } do
          has_one :author
          has_many :chapters

          has_many :reviews do
            has_one :review_author
          end
        end
      end
    end

    private

    def books_opts
      { autoload_children: true }
    end
  end

  class ReeDaoAggTest::AggUsersAutoloadReviewsChildren
    include ReeDao::AggregateDSL

    aggregate :agg_users_autoload_reviews_children do
      link :users, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :chapters, from: :ree_dao_agg_test
      link :authors, from: :ree_dao_agg_test
      link :reviews, from: :ree_dao_agg_test
      link :review_authors, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        belongs_to :organization
        has_many :books do
          has_one :author
          has_many :chapters

          has_many :reviews, -> { { autoload_children: true } } do
            has_one :review_author
          end
        end
      end
    end

    private

    def reviews_opts
      { autoload_children: true }
    end
  end

  class ReeDaoAggTest::AggUsersBlockTest
    include ReeDao::AggregateDSL

    aggregate :agg_users_block_test do
      link :users, from: :ree_dao_agg_test
      link :organizations_dao, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        belongs_to :organization
        has_many :books, -> { books_opts }
      end
    end

    private

    def books_opts
      {
        setter: -> (item, items_index) {
          b = items_index[item.id].each { |b| b.title = "Changed" }
          item.books = b
        }
      }
    end
  end

  class ReeDaoAggTest::AggUsersScopeMethodTest
    include ReeDao::AggregateDSL

    aggregate :agg_users_scope_method_test do
      link :users, from: :ree_dao_agg_test
      link :organizations_dao, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do |agg_list|
        some_id = agg_list.first.id
        title = "1984"
        belongs_to :organization

        has_many :books, -> { books_opts(title) }
        has_many :active_books, books
      end
    end

    private

    def books_opts(title)
      { scope: books_scope(title) }
    end

    def books_scope(title)
      books.where(title: title)
    end
  end

  class ReeDaoAggTest::AggUsersOnlyDataset
    include ReeDao::AggregateDSL

    aggregate :agg_users_only_dataset do
      link :users, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        has_many :books, books.where(title: "1408")
      end
    end
  end

  class ReeDaoAggTest::AggUsersWithoutDao
    include ReeDao::AggregateDSL

    aggregate :agg_users_without_dao do
      link :users, from: :ree_dao_agg_test
      link :organizations_dao, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        has_many :something
      end
    end
  end

  class ReeDaoAggTest::AggUsersOnlyExceptKeys
    include ReeDao::AggregateDSL

    aggregate :agg_users_only_except_keys do
      link :users, from: :ree_dao_agg_test
      link :organizations_dao, from: :ree_dao_agg_test
      link :books, from: :ree_dao_agg_test
      link :agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      agg(users, ids_or_scope, **opts) do
        belongs_to :organization
        has_many :books
      end
    end
  end

  let(:agg_users) { ReeDaoAggTest::AggUsers.new }
  let(:agg_users_block) { ReeDaoAggTest::AggUsersBlockTest.new }
  let(:agg_users_scope_method) { ReeDaoAggTest::AggUsersScopeMethodTest.new }
  let(:agg_users_autoload_books_children) { ReeDaoAggTest::AggUsersAutoloadBooksChildren.new }
  let(:agg_users_autoload_reviews_children) { ReeDaoAggTest::AggUsersAutoloadReviewsChildren.new }
  let(:agg_users_without_dao) { ReeDaoAggTest::AggUsersWithoutDao.new }
  let(:agg_users_with_dto) { ReeDaoAggTest::AggUsersWithDto.new }
  let(:agg_users_only_dataset) { ReeDaoAggTest::AggUsersOnlyDataset.new }
  let(:user_agg_only_except_keys) { ReeDaoAggTest::AggUsersOnlyExceptCase.new }
  let(:organizations) { ReeDaoAggTest::OrganizationsDao.new }
  let(:users) { ReeDaoAggTest::Users.new }
  let(:user_passports) { ReeDaoAggTest::UserPassports.new }
  let(:books) { ReeDaoAggTest::Books.new }
  let(:chapters) { ReeDaoAggTest::Chapters.new }
  let(:authors) { ReeDaoAggTest::Authors.new }
  let(:reviews) { ReeDaoAggTest::Reviews.new }
  let(:review_authors) { ReeDaoAggTest::ReviewAuthors.new }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoAggTest::Organization.build(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoAggTest::User.build(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    expect {
      agg_users_without_dao.call(users.all)
    }.to raise_error(ArgumentError)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.build(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.build(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.build(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    passport_1 = ReeDaoAggTest::UserPassport.build(user_id: user_1.id, info: "some info")
    user_passports.put(passport_1)
    user_passports.put(ReeDaoAggTest::UserPassport.build(user_id: user_2.id, info: "another info"))

    book_1 = ReeDaoAggTest::Book.build(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.build(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapter = ReeDaoAggTest::Chapter.build(book_id: book_1.id, title: "beginning")
    chapters.put(chapter)
    chapters.put(ReeDaoAggTest::Chapter.build(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.build(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoAggTest::Chapter.build(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.build(book_id: book_2.id, title: "ending"))


    authors.put(ReeDaoAggTest::Author.build(book_id: book_1.id, name: "George Orwell"))
    review = ReeDaoAggTest::Review.build(book_id: book_1.id, rating: 10)
    reviews.put(review)
    reviews.put(ReeDaoAggTest::Review.build(book_id: book_1.id, rating: 7))
    review_authors.put(ReeDaoAggTest::ReviewAuthor.build(review_id: review.id, name: "John Review"))

    res = agg_users.call(
      users.all,
      only: [:books, :reviews],
      except: [:review_author]
    )

    expect(res.first.books.first.reviews.first.review_author).to eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoAggTest::Organization.build(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoAggTest::User.build(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    expect {
      agg_users_without_dao.call(users.all, only: [:books], except: [:books])
    }.to raise_error(ArgumentError, "you can't use both :only and :except for \"books\" keys")
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoAggTest::Organization.build(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.build(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.build(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoAggTest::Book.build(user_id: user_1.id, title: "1984")
    books.put(book_1)

    authors.put(ReeDaoAggTest::Author.build(book_id: book_1.id, name: "George Orwell"))
    chapters.put(ReeDaoAggTest::Chapter.build(book_id: book_1.id, title: "interlude"))

    res = agg_users_with_dto.call(
      users.all,
      to_dto: -> (user) {
        ReeDaoAggTest::UserDto.build(
          id: user.id,
          name: user.name,
          organization_id: user.organization_id,
          full_name: user.name
        )
      }
    )

    book = res.first.books.first

    expect(res.first.class).to eq(ReeDaoAggTest::UserDto)
    expect(book.class).to eq(ReeDaoAggTest::BookDto)
    expect(book.author.class).to eq(ReeDaoAggTest::AuthorDto)
    expect(book.chapters.first.class).to eq(ReeDaoAggTest::ChapterDto)
  }

  it {
    organizations.delete_all
    users.delete_all

    org = ReeDaoAggTest::Organization.build(name: "Test Org")
    organizations.put(org)

    user = ReeDaoAggTest::User.build(name: "John", age: 33, organization_id: org.id)
    users.put(user)

    book_1 = ReeDaoAggTest::Book.build(user_id: user.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.build(user_id: user.id, title: "1408")
    book_3 = ReeDaoAggTest::Book.build(user_id: user.id, title: "1408")

    books.put(book_1)
    books.put(book_2)
    books.put(book_3)

    res = agg_users_only_dataset.call(users.where(name: "John"))

    user = res[0]
    expect(user.books.map(&:title).uniq).to eq(["1408"])
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    passport_1 = ReeDaoAggTest::UserPassport.new(user_id: user_1.id, info: "some info")
    user_passports.put(passport_1)
    user_passports.put(ReeDaoAggTest::UserPassport.new(user_id: user_2.id, info: "another info"))

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapter = ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "beginning")
    chapters.put(chapter)
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "ending"))


    authors.put(ReeDaoAggTest::Author.new(book_id: book_1.id, name: "George Orwell"))
    review = ReeDaoAggTest::Review.new(book_id: book_1.id, rating: 10)
    reviews.put(review)
    reviews.put(ReeDaoAggTest::Review.new(book_id: book_1.id, rating: 7))
    review_authors.put(ReeDaoAggTest::ReviewAuthor.new(review_id: review.id, name: "John Review"))

    res = agg_users.call(
      users.all,
      chapters: -> (scope) { scope.ids(chapter.id) }
    )

    res_user = res[0]
    expect(res_user.id).to eq(user_1.id)
    expect(res_user.organization).to eq(organization)
    expect(res_user.passport).to eq(passport_1)
    expect(res_user.passport.info).to eq("some info")
    expect(res_user.books.count).to eq(2)
    expect(res_user.books.map(&:title)).to eq(["1984 changed", "1408 changed"])
    expect(res_user.books[0].author.name).to eq("George Orwell")
    expect(res_user.books[0].chapters.map(&:title)).to eq(["beginning"])
    expect(res_user.books[0].reviews[0].review_author.name).to eq("John Review")
    expect(res_user.custom_field).to_not eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    author_1 = ReeDaoAggTest::Author.new(book_id: book_1.id, name: "George Orwell")
    author_2 = ReeDaoAggTest::Author.new(book_id: book_2.id, name: "Stephen King")
    authors.put(author_1)
    authors.put(author_2)

    res = agg_users.call(
      users.all
    )

    expect(res[0].books.first.author).to_not eq(nil)

    authors.delete(author_1)
    authors.delete(author_2)

    res = agg_users.call(
      users.all
    )

    expect(res[0].books[0].author).to eq(nil)
    expect(res[0].books[1].author).to eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    res = agg_users.call(
      users.all
    )

    expect(res[0].books).to_not eq([])
    expect(res[1].books).to eq([])

    books.delete(book_1)
    books.delete(book_2)

    res = agg_users.call(
      users.all
    )

    expect(res[0].books).to eq([])
    expect(res[1].books).to eq([])
  }

  it {
    organizations.delete_all
    users.delete_all
    books.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    res = agg_users_scope_method.call(users.all)

    res_user = res[0]
    expect(res_user.id).to eq(user_1.id)
    expect(res_user.organization).to eq(organization)
    expect(res_user.books.count).to eq(1)
    expect(res_user.active_books.count).to eq(2)
  }

  it {
    organizations.delete_all
    users.delete_all
    books.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    expect {
      agg_users_scope_method.call(users.where(name: "Another names"))
    }.to_not raise_error
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "ending"))

    res = agg_users.call(
      users.all,
      only: [:books, :chapters]
    )

    u = res[0]
    expect(u.books.count).to eq(2)
    expect(u.books[0].chapters.count).to_not eq(0)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "ending"))

    res = agg_users.call(
      users.all,
      only: [:books, :chapters]
    )

    u = res[0]
    expect(u.books.count).to eq(2)
    expect(u.books[0].chapters.count).to_not eq(0)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    book = ReeDaoAggTest::Book.new(user_id: user.id, title: "1984")
    books.put(book)

    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book.id, title: "tragic ending"))

    authors.put(ReeDaoAggTest::Author.new(book_id: book.id, name: "George Orwell"))

    review = ReeDaoAggTest::Review.new(book_id: book.id, rating: 5)
    reviews.put(review)
    review_authors.put(ReeDaoAggTest::ReviewAuthor.new(review_id: review.id, name: "John"))

    res = agg_users_autoload_books_children.call(
      users.all,
      only: [:books]
    )

    u = res[0]
    expect(u.books).to_not eq(nil)
    expect(u.books[0].chapters).to_not eq(nil)
    expect(u.books[0].author).to_not eq(nil)
    expect(u.books[0].reviews).to_not eq(nil)
    expect(u.books[0].reviews[0].review_author).to eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    book = ReeDaoAggTest::Book.new(user_id: user.id, title: "1984")
    books.put(book)

    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book.id, title: "tragic ending"))

    authors.put(ReeDaoAggTest::Author.new(book_id: book.id, name: "George Orwell"))

    review = ReeDaoAggTest::Review.new(book_id: book.id, rating: 5)
    reviews.put(review)
    review_authors.put(ReeDaoAggTest::ReviewAuthor.new(review_id: review.id, name: "John"))

    res = agg_users_autoload_reviews_children.call(
      users.all,
      only: [:books, :reviews]
    )

    u = res[0]
    expect(u.books).to_not eq(nil)
    expect(u.books[0].chapters).to eq([])
    expect(u.books[0].author).to eq(nil)
    expect(u.books[0].reviews).to_not eq(nil)
    expect(u.books[0].reviews[0].review_author).to_not eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")

    books.put(book_1)

    res = agg_users_block.call(user_1.id)

    u = res[0]
    expect(u.books.map(&:title)).to eq(["Changed"])
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoAggTest::Chapter.new(book_id: book_2.id, title: "ending"))

    res = agg_users.call(
      users.all,
      except: [:organization, :passport, :custom_field]
    )

    u = res[0]
    expect(u.books.count).to eq(2)
    expect(u.passport).to eq(nil)
    expect(u.organization).to eq(nil)
    expect(u.custom_field).to eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    ids = [user_1, user_2].map(&:id)

    res = agg(users, ids)
    expect(res.count).to eq(2)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    res = agg(users, user_1.id)
    expect(res.count).to eq(1)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    res = agg(users, users.where(organization_id: organization.id))
    expect(res.count).to eq(2)
  }

  context "when sync mode enabled" do
    it {
      organization = ReeDaoAggTest::Organization.new(name: "Test Org")
      organizations.put(organization)
      user = ReeDaoAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
      users.put(user)

      allow(user).to receive(:some_field=)
      expect(user).to receive(:some_field=).with(:some_value)

      ENV['REE_DAO_SYNC_ASSOCIATIONS'] = "true"
      agg_users.([user])
      ENV.delete('REE_DAO_SYNC_ASSOCIATIONS')
    }
  end
end
