Ree.enable_irb_mode

module ReeDaoTest
  include Ree::PackageDSL

  package do
    depends_on :ree_dao
    depends_on :ree_array
    depends_on :ree_string
  end
end

class ReeDaoTest::Db
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

class ReeDaoTest::Organization
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    name: String
  )

  attr_accessor :name
end


class ReeDaoTest::User
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    name: String,
    age: Integer,
    organization_id: Integer
  )

  def set_organization(org)
    @organization = org
  end

  def organization
    @organization
  end

  def set_passport(passport)
    @passport = passport
  end

  def passport
    @passport
  end

  def set_books(books)
    @books = books
  end

  def books
    @books
  end

  attr_accessor :name, :age, :organization_id
end


class ReeDaoTest::UserPassport
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    info: Nilor[String]
  )

  attr_accessor :info, :user_id
end

class ReeDaoTest::Book
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    title: Nilor[String]
  )

  def set_chapters(chapters)
    @chapters = chapters; nil
  end

  def chapters
    @chapters
  end

  def set_author(author)
    @author = author
  end

  def author
    @author
  end

  def set_reviews(reviews)
    @reviews = reviews
  end

  def reviews
    @reviews
  end

  attr_accessor :title, :user_id
end

class ReeDaoTest::Chapter
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    book_id: Integer,
    title: Nilor[String]
  )

  attr_accessor :title, :book_id
end

class ReeDaoTest::Author
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    book_id: Integer,
    name: Nilor[String]
  )

  attr_accessor :name, :book_id
end

class ReeDaoTest::Review
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    book_id: Integer,
    rating: Nilor[Integer]
  )

  attr_accessor :rating, :book_id
end

class ReeDaoTest::Users
  include ReeDao::DSL

  dao :users do
    link :db
  end

  table :users

  schema ReeDaoTest::User do
    integer :id, null: true
    integer :organization_id
    string :name
    integer :age
  end

  filter :by_name, -> (name) { where(name: name) }
end

class ReeDaoTest::Organizations
  include ReeDao::DSL

  dao :organizations do
    link :db
  end

  table :organizations

  schema ReeDaoTest::Organization do
    integer :id, null: true
    string :name
  end

  filter :by_name, -> (name) { where(name: name) }
end

class ReeDaoTest::UserPassports
  include ReeDao::DSL

  dao :user_passports do
    link :db
  end

  table :user_passports

  schema ReeDaoTest::UserPassport do
    integer :id, null: true
    integer :user_id
    string :info
  end
end

class ReeDaoTest::Books
  include ReeDao::DSL

  dao :books do
    link :db
  end

  table :books

  schema ReeDaoTest::Book do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoTest::Chapters
  include ReeDao::DSL

  dao :chapters do
    link :db
  end

  table :chapters

  schema ReeDaoTest::Chapter do
    integer :id, null: true
    integer :book_id
    string :title
  end
end

class ReeDaoTest::Authors
  include ReeDao::DSL

  dao :authors do
    link :db
  end

  table :authors

  schema ReeDaoTest::Author do
    integer :id, null: true
    integer :book_id
    string :name
  end
end

class ReeDaoTest::Reviews
  include ReeDao::DSL

  dao :reviews do
    link :db
  end

  table :reviews

  schema ReeDaoTest::Review do
    integer :id, null: true
    integer :book_id
    integer :rating
  end
end