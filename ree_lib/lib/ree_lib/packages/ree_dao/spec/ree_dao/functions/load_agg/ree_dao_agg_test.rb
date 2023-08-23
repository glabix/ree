Ree.enable_irb_mode

module ReeDaoAggTest
  include Ree::PackageDSL

  package do
    depends_on :ree_dao
    depends_on :ree_array
    depends_on :ree_string
    depends_on :ree_hash
  end
end

class ReeDaoAggTest::Db
  include Ree::BeanDSL

  DB_CONFIG = {
    host: "localhost",
    user: "postgres",
    database: "postgres",
    password: "password",
    adapter: "postgres",
    max_connections: 100
  }.freeze

  bean :db do
    singleton
    factory :build

    link :build_pg_connection, from: :ree_dao
  end

  def build
    build_pg_connection(DB_CONFIG)
  end
end

class ReeDaoAggTest::Book
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
    @reviews = reviews; nil
  end

  def reviews
    @reviews
  end

  def title=(t)
    @title = t
  end

  attr_accessor :title, :user_id
end

class ReeDaoAggTest::BookDto < SimpleDelegator
end

class ReeDaoAggTest::User
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

  def books
    @books
  end

  def set_active_books(books)
    @active_books = books
  end

  def active_books
    @active_books
  end

  contract(ArrayOf[ReeDaoAggTest::Book] => nil)
  def set_books(books)
    @books = books; nil
  end

  [
    :organization,
    :passport,
    :movies,
    :videogames,
    :hobbies,
    :vinyls,
    :pets,
    :skills,
    :dreams,
    :custom_field
  ].each do |attr|
    define_method("set_#{attr}") do |*args|
      instance_variable_set("@#{attr}", *args)
    end

    define_method("#{attr}") do
      instance_variable_get("@#{attr}")
    end
  end

  attr_accessor :name, :age, :organization_id
end

class ReeDaoAggTest::UserDto
  include ReeDto::EntityDSL

  properties(
    id: Integer,
    organization_id: Integer,
    name: String,
    full_name: String,
  )

  def set_organization(org)
    @organization = org; nil
  end

  def organization
    @organization
  end

  def set_books(books)
    @books = books; nil
  end

  def books
    @books
  end
end

class ReeDaoAggTest::Organization
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    name: String
  )
  
  contract(Array[ReeDaoAggTest::User] => nil)
  def set_users(users)
    @users = users; nil
  end

  def users
    @users ||= []
  end

  attr_accessor :name
end


class ReeDaoAggTest::UserPassport
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    info: Nilor[String]
  )

  attr_accessor :info, :user_id
end

class ReeDaoAggTest::Movie
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    title: Nilor[String]
  )
end

class ReeDaoAggTest::Videogame
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    title: Nilor[String]
  )
end

class ReeDaoAggTest::Hobby
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    title: Nilor[String]
  )
end

class ReeDaoAggTest::Vinyl
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    title: Nilor[String]
  )
end

class ReeDaoAggTest::Pet
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    name: Nilor[String]
  )
end

class ReeDaoAggTest::Skill
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    title: Nilor[String]
  )
end

class ReeDaoAggTest::Dream
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    user_id: Integer,
    description: Nilor[String]
  )
end

class ReeDaoAggTest::Chapter
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    book_id: Integer,
    title: Nilor[String]
  )

  attr_accessor :title, :book_id
end

class ReeDaoAggTest::ChapterDto < SimpleDelegator
end

class ReeDaoAggTest::Author
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    book_id: Integer,
    name: Nilor[String]
  )

  attr_accessor :name, :book_id
end

class ReeDaoAggTest::AuthorDto < SimpleDelegator
end

class ReeDaoAggTest::Review
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    book_id: Integer,
    rating: Nilor[Integer]
  )

  def set_review_author(review_author)
    @review_author = review_author
  end

  def review_author
    @review_author
  end

  attr_accessor :rating, :book_id
end

class ReeDaoAggTest::ReviewAuthor
  include ReeDto::EntityDSL

  properties(
    id: Nilor[Integer],
    review_id: Integer,
    name: String
  )
end

class ReeDaoAggTest::Users
  include ReeDao::DSL

  dao :users do
    link :db
  end

  table :users

  schema ReeDaoAggTest::User do
    integer :id, null: true
    integer :organization_id
    string :name
    integer :age
  end

  filter :by_name, -> (name) { where(name: name) }
end

class ReeDaoAggTest::Organizations
  include ReeDao::DSL

  dao :organizations do
    link :db
  end

  table :organizations

  schema ReeDaoAggTest::Organization do
    integer :id, null: true
    string :name
  end

  filter :by_name, -> (name) { where(name: name) }
end

class ReeDaoAggTest::UserPassports
  include ReeDao::DSL

  dao :user_passports do
    link :db
  end

  table :user_passports

  schema ReeDaoAggTest::UserPassport do
    integer :id, null: true
    integer :user_id
    string :info
  end
end

class ReeDaoAggTest::Movies
  include ReeDao::DSL

  dao :movies do
    link :db
  end

  table :movies

  schema ReeDaoAggTest::Movie do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoAggTest::Videogames
  include ReeDao::DSL

  dao :videogames do
    link :db
  end

  table :videogames

  schema ReeDaoAggTest::Videogame do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoAggTest::Hobbies
  include ReeDao::DSL

  dao :hobbies do
    link :db
  end

  table :hobbies

  schema ReeDaoAggTest::Hobby do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoAggTest::Vinyls
  include ReeDao::DSL

  dao :vinyls do
    link :db
  end

  table :vinyls

  schema ReeDaoAggTest::Vinyl do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoAggTest::Pets
  include ReeDao::DSL

  dao :pets do
    link :db
  end

  table :pets

  schema ReeDaoAggTest::Pet do
    integer :id, null: true
    integer :user_id
    string :name
  end
end

class ReeDaoAggTest::Skills
  include ReeDao::DSL

  dao :skills do
    link :db
  end

  table :skills

  schema ReeDaoAggTest::Skill do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoAggTest::Dreams
  include ReeDao::DSL

  dao :dreams do
    link :db
  end

  table :dreams

  schema ReeDaoAggTest::Dream do
    integer :id, null: true
    integer :user_id
    string :description
  end
end

class ReeDaoAggTest::Books
  include ReeDao::DSL

  dao :books do
    link :db
  end

  table :books

  schema ReeDaoAggTest::Book do
    integer :id, null: true
    integer :user_id
    string :title
  end
end

class ReeDaoAggTest::Chapters
  include ReeDao::DSL

  dao :chapters do
    link :db
  end

  table :chapters

  schema ReeDaoAggTest::Chapter do
    integer :id, null: true
    integer :book_id
    string :title
  end
end

class ReeDaoAggTest::Authors
  include ReeDao::DSL

  dao :authors do
    link :db
  end

  table :authors

  schema ReeDaoAggTest::Author do
    integer :id, null: true
    integer :book_id
    string :name
  end
end

class ReeDaoAggTest::Reviews
  include ReeDao::DSL

  dao :reviews do
    link :db
  end

  table :reviews

  schema ReeDaoAggTest::Review do
    integer :id, null: true
    integer :book_id
    integer :rating
  end
end

class ReeDaoAggTest::ReviewAuthors
  include ReeDao::DSL

  dao :review_authors do
    link :db
  end

  table :review_authors

  schema ReeDaoAggTest::ReviewAuthor do
    integer :id, null: true
    integer :review_id
    string :name
  end
end