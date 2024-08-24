Ree.enable_irb_mode

module ReeDaoAggTest
  include Ree::PackageDSL

  package do
    depends_on :ree_dao
    depends_on :ree_dto
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
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :title, Nilor[String], default: nil

    field :author, Any, default: nil

    collection :chapters, Any
    collection :reviews, Any
  end
end

class ReeDaoAggTest::BookDto < SimpleDelegator
end

class ReeDaoAggTest::User
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :name, String
    field :age, Integer
    field :organization_id, Integer

    field :organization, Any, default: nil
    field :passport, Any, default: nil
    field :custom_field, Any, default: nil

    collection :movies, Any
    collection :videogames, Any
    collection :hobbies, Any
    collection :vinyls, Any
    collection :pets, Any
    collection :skills, Any
    collection :dreams, Any
    collection :books, ReeDaoAggTest::Book
    collection :active_books, ReeDaoAggTest::Book
  end

  [

  ].each do |attr|
    define_method("set_#{attr}") do |*args|
      instance_variable_set("@#{attr}", *args)
    end

    define_method("#{attr}") do
      instance_variable_get("@#{attr}")
    end
  end
end

class ReeDaoAggTest::UserDto
  include ReeDto::DSL

  build_dto do
    field :id, Integer
    field :organization_id, Integer
    field :name, String
    field :full_name, String

    field :organization, Any

    collection :books, ReeDaoAggTest::BookDto
  end
end

class ReeDaoAggTest::Organization
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :name, String

    collection :users, ReeDaoAggTest::User
  end
end


class ReeDaoAggTest::UserPassport
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :info, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Movie
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :title, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Videogame
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :title, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Hobby
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :title, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Vinyl
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :title, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Pet
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :name, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Skill
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :title, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Dream
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :user_id, Integer
    field :description, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::Chapter
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :book_id, Integer
    field :title, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::ChapterDto < SimpleDelegator
end

class ReeDaoAggTest::Author
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :book_id, Integer
    field :name, Nilor[String], default: nil
  end
end

class ReeDaoAggTest::AuthorDto < SimpleDelegator
end

class ReeDaoAggTest::ReviewAuthor
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :review_id, Integer
    field :name, String, default: nil
  end
end

class ReeDaoAggTest::Review
  include ReeDto::DSL

  build_dto do
    field :id, Nilor[Integer], default: nil
    field :book_id, Integer
    field :rating, Nilor[Integer], default: nil

    field :review_author, Nilor[ReeDaoAggTest::ReviewAuthor], default: nil
  end
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

class ReeDaoAggTest::OrganizationsDao
  include ReeDao::DSL

  dao :organizations_dao do
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

  table :avtorki

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
