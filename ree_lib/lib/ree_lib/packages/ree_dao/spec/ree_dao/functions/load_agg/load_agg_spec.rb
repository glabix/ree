# frozen_string_literal: true
require 'faker'
require 'benchmark'

RSpec.describe :load_agg do
  link :build_pg_connection, from: :ree_dao
  link :load_agg, from: :ree_dao

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_pg_connection(ReeDaoLoadAggTest::Db::DB_CONFIG)

    connection.drop_table(:organizations, cascade: true) if connection.table_exists?(:organizations)
    connection.drop_table(:users, cascade: true) if connection.table_exists?(:users)
    connection.drop_table(:user_passports, cascade: true) if connection.table_exists?(:user_passports)
    connection.drop_table(:books, cascade: true) if connection.table_exists?(:books)
    connection.drop_table(:chapters, cascade: true) if connection.table_exists?(:chapters)
    connection.drop_table(:authors, cascade: true) if connection.table_exists?(:authors)
    connection.drop_table(:reviews, cascade: true) if connection.table_exists?(:reviews)
    connection.drop_table(:review_authors, cascade: true) if connection.table_exists?(:review_authors)

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

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do |users_list|
        belongs_to :organization
        has_many :books do |books_list|
          has_one :author
          has_many :chapters
        
          has_many :reviews do |reviews_list|
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
      puts list.map(&:id)
      puts list.map { _1.class.name }
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
  end

  class ReeDaoLoadAggTest::UsersAggWithDto
    include ReeDao::AggregateDSL

    aggregate :users_agg_with_dto do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do
        belongs_to :organization
      end
    end
  end

  class ReeDaoLoadAggTest::UsersAggAutoloadBooksChildren
    include ReeDao::AggregateDSL

    aggregate :users_agg_autoload_books_children do
      link :users, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :chapters, from: :ree_dao_load_agg_test
      link :authors, from: :ree_dao_load_agg_test
      link :reviews, from: :ree_dao_load_agg_test
      link :review_authors, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do
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

  class ReeDaoLoadAggTest::UsersAggAutoloadReviewsChildren
    include ReeDao::AggregateDSL

    aggregate :users_agg_autoload_reviews_children do
      link :users, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :chapters, from: :ree_dao_load_agg_test
      link :authors, from: :ree_dao_load_agg_test
      link :reviews, from: :ree_dao_load_agg_test
      link :review_authors, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do
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

  class ReeDaoLoadAggTest::UsersAggBlockTest
    include ReeDao::AggregateDSL

    aggregate :users_agg_block_test do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do
        belongs_to :organization
        has_many :books, -> { books_opts }
      end
    end

    private

    def books_opts
      {
        setter: -> (item, items_index) {
          b = items_index[item.id].each { |b| b.title = "Changed" }
          item.set_books(b)
        }
      }
    end
  end

  class ReeDaoLoadAggTest::UsersAggScopeMethodTest
    include ReeDao::AggregateDSL

    aggregate :users_agg_scope_method_test do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do |agg_list|
        some_id = agg_list.first.id
        title = "1984"
        belongs_to :organization

        has_many :books, -> { books_opts(title) }
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

  class ReeDaoLoadAggTest::UsersAggOnlyDataset
    include ReeDao::AggregateDSL

    aggregate :users_agg_only_dataset do
      link :users, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do
        has_many :books, books.where(title: "1408")
      end
    end
  end

  class ReeDaoLoadAggTest::UsersAggWithoutDao
    include ReeDao::AggregateDSL

    aggregate :users_agg_without_dao do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope, **opts)
      load_agg(users, ids_or_scope, **opts) do
        has_many :something
      end
    end
  end

  let(:users_agg) { ReeDaoLoadAggTest::UsersAgg.new }
  let(:users_agg_block) { ReeDaoLoadAggTest::UsersAggBlockTest.new }
  let(:users_agg_scope_method) { ReeDaoLoadAggTest::UsersAggScopeMethodTest.new }
  let(:users_agg_autoload_books_children) { ReeDaoLoadAggTest::UsersAggAutoloadBooksChildren.new }
  let(:users_agg_autoload_reviews_children) { ReeDaoLoadAggTest::UsersAggAutoloadReviewsChildren.new }
  let(:users_agg_without_dao) { ReeDaoLoadAggTest::UsersAggWithoutDao.new }
  let(:users_agg_with_dto) { ReeDaoLoadAggTest::UsersAggWithDto.new }
  let(:users_agg_only_dataset) { ReeDaoLoadAggTest::UsersAggOnlyDataset.new }
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

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    expect {
      users_agg_without_dao.call(users.all)
    }.to raise_error(ArgumentError)
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

    res = users_agg_with_dto.call(
      users.all,
      to_dto: -> (user) {
        ReeDaoLoadAggTest::UserDto.new(
          id: user.id,
          name: user.name,
          organization_id: user.organization_id,
          full_name: user.name
        )
      }
    )

    expect(res.first.class).to eq(ReeDaoLoadAggTest::UserDto)
  }

  it {
    organizations.delete_all
    users.delete_all

    org = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(org)

    user = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: org.id)
    users.put(user)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user.id, title: "1408")
    book_3 = ReeDaoLoadAggTest::Book.new(user_id: user.id, title: "1408")

    books.put(book_1)
    books.put(book_2)
    books.put(book_3)
    
    res = users_agg_only_dataset.call(users.where(name: "John"))

    user = res[0]
    expect(user.books.map(&:title).uniq).to eq(["1408"])
  }

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

    chapter = ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "beginning")
    chapters.put(chapter)
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "ending"))


    authors.put(ReeDaoLoadAggTest::Author.new(book_id: book_1.id, name: "George Orwell"))
    review = ReeDaoLoadAggTest::Review.new(book_id: book_1.id, rating: 10)
    reviews.put(review)
    reviews.put(ReeDaoLoadAggTest::Review.new(book_id: book_1.id, rating: 7))
    review_authors.put(ReeDaoLoadAggTest::ReviewAuthor.new(review_id: review.id, name: "John Review"))

    res = users_agg.call(
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
    books.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoLoadAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    res = users_agg_scope_method.call(users.all)

    res_user = res[0]
    expect(res_user.id).to eq(user_1.id)
    expect(res_user.organization).to eq(organization)
    expect(res_user.books.count).to eq(1)
  }

  it {
    organizations.delete_all
    users.delete_all
    books.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoLoadAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    expect {
      users_agg_scope_method.call(users.where(name: "Another names"))
    }.to_not raise_error
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "ending"))

    res = users_agg.call(
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

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "ending"))

    res = users_agg.call(
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

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    book = ReeDaoLoadAggTest::Book.new(user_id: user.id, title: "1984")
    books.put(book)

    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book.id, title: "tragic ending"))

    authors.put(ReeDaoLoadAggTest::Author.new(book_id: book.id, name: "George Orwell"))

    review = ReeDaoLoadAggTest::Review.new(book_id: book.id, rating: 5)
    reviews.put(review)
    review_authors.put(ReeDaoLoadAggTest::ReviewAuthor.new(review_id: review.id, name: "John"))

    res = users_agg_autoload_books_children.call(
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

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user)

    book = ReeDaoLoadAggTest::Book.new(user_id: user.id, title: "1984")
    books.put(book)

    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book.id, title: "tragic ending"))

    authors.put(ReeDaoLoadAggTest::Author.new(book_id: book.id, name: "George Orwell"))

    review = ReeDaoLoadAggTest::Review.new(book_id: book.id, rating: 5)
    reviews.put(review)
    review_authors.put(ReeDaoLoadAggTest::ReviewAuthor.new(review_id: review.id, name: "John"))

    res = users_agg_autoload_reviews_children.call(
      users.all,
      only: [:books, :reviews]
    )

    u = res[0]
    expect(u.books).to_not eq(nil)
    expect(u.books[0].chapters).to eq(nil)
    expect(u.books[0].author).to eq(nil)
    expect(u.books[0].reviews).to_not eq(nil)
    expect(u.books[0].reviews[0].review_author).to_not eq(nil)
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")

    books.put(book_1)

    res = users_agg_block.call(user_1.id)

    u = res[0]
    expect(u.books.map(&:title)).to eq(["Changed"])
  }

  it {
    organizations.delete_all
    users.delete_all
    user_passports.delete_all
    books.delete_all
    chapters.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    book_1 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1984")
    book_2 = ReeDaoLoadAggTest::Book.new(user_id: user_1.id, title: "1408")

    books.put(book_1)
    books.put(book_2)

    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "interlude"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_1.id, title: "tragic ending"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "beginning"))
    chapters.put(ReeDaoLoadAggTest::Chapter.new(book_id: book_2.id, title: "ending"))

    res = users_agg.call(
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

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    user_2 = ReeDaoLoadAggTest::User.new(name: "Sam", age: 21, organization_id: organization.id)
    users.put(user_1)
    users.put(user_2)

    ids = [user_1, user_2].map(&:id)

    res = load_agg(users, ids)
    expect(res.count).to eq(2)
  }

  it {
    organizations.delete_all
    users.delete_all

    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    user_1 = ReeDaoLoadAggTest::User.new(name: "John", age: 33, organization_id: organization.id)
    users.put(user_1)

    res = load_agg(users, user_1.id)
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

    res = load_agg(users, users.where(organization_id: organization.id))
    expect(res.count).to eq(2)
  }
end