# frozen_string_literal: true
require 'faker'
require 'benchmark'

RSpec.describe :load_agg do
  link :build_pg_connection, from: :ree_dao
  link :load_agg, from: :ree_dao

  NUM_OF_USERS = 100
  ASSOC_COUNT = 10

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_pg_connection(ReeDaoLoadAggTest::Db::DB_CONFIG)

    connection.drop_table(:organizations, cascade: true) if connection.table_exists?(:organizations)
    connection.drop_table(:users, cascade: true) if connection.table_exists?(:users)
    connection.drop_table(:user_passports, cascade: true) if connection.table_exists?(:user_passports)
    connection.drop_table(:books, cascade: true) if connection.table_exists?(:books)
    connection.drop_table(:movies, cascade: true) if connection.table_exists?(:movies)
    connection.drop_table(:videogames, cascade: true) if connection.table_exists?(:videogames)
    connection.drop_table(:hobbies, cascade: true) if connection.table_exists?(:hobbies)
    connection.drop_table(:vinyls, cascade: true) if connection.table_exists?(:vinyls)
    connection.drop_table(:pets, cascade: true) if connection.table_exists?(:pets)
    connection.drop_table(:skills, cascade: true) if connection.table_exists?(:skills)
    connection.drop_table(:dreams, cascade: true) if connection.table_exists?(:dreams)

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

    connection.create_table :movies do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :videogames do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :hobbies do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :vinyls do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :pets do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :name, 'varchar(256)'
    end

    connection.create_table :skills do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :title, 'varchar(256)'
    end

    connection.create_table :dreams do
      primary_key :id

      foreign_key :user_id, :users, null: false, on_delete: :cascade
      column  :description, 'varchar(256)'
    end

    connection.disconnect
  end

  require_relative 'ree_dao_load_agg_test'

  class ReeDaoLoadAggTest::UsersAggBenchmark
    include ReeDao::AggregateDSL

    aggregate :users_agg_benchmark do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :user_passports, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :movies, from: :ree_dao_load_agg_test
      link :videogames, from: :ree_dao_load_agg_test
      link :hobbies, from: :ree_dao_load_agg_test
      link :vinyls, from: :ree_dao_load_agg_test
      link :pets, from: :ree_dao_load_agg_test
      link :skills, from: :ree_dao_load_agg_test
      link :dreams, from: :ree_dao_load_agg_test
      link :load_agg, from: :ree_dao
    end

    def call(ids_or_scope)
      load_agg(users, ids_or_scope) do
        belongs_to :organization

        has_many :books
        has_many :movies
        has_many :videogames
        has_many :hobbies
        has_many :vinyls
        has_many :pets
        has_many :skills
        has_many :dreams

        has_one :passport, -> { {foreign_key: :user_id, scope: user_passports} }
      end
    end
  end

  class ReeDaoLoadAggTest::UsersSyncFetcher
    include Ree::FnDSL

    fn :users_sync_fetcher do
      link :users, from: :ree_dao_load_agg_test
      link :organizations, from: :ree_dao_load_agg_test
      link :user_passports, from: :ree_dao_load_agg_test
      link :books, from: :ree_dao_load_agg_test
      link :movies, from: :ree_dao_load_agg_test
      link :videogames, from: :ree_dao_load_agg_test
      link :hobbies, from: :ree_dao_load_agg_test
      link :vinyls, from: :ree_dao_load_agg_test
      link :pets, from: :ree_dao_load_agg_test
      link :skills, from: :ree_dao_load_agg_test
      link :dreams, from: :ree_dao_load_agg_test
      link :one_to_many, from: :ree_dao
      link :one_to_one, from: :ree_dao
    end

    contract(
      Or[Sequel::Dataset, ArrayOf[Integer]],
      Kwargs[
        include: ArrayOf[Symbol]
      ] => ArrayOf[ReeDaoLoadAggTest::User]
    )
    def call(ids_or_scope, include: [])
      scope = if ids_or_scope.is_a?(Array)
        return [] if ids_or_scope.empty?
        users.where(id: ids_or_scope)
      else
        ids_or_scope
      end

      list = scope.all
      return [] if list.empty?

      if include.include?(:organization)
        one_to_one(list, organizations.order(:id))
      end

      if include.include?(:books)
        one_to_many(list, books.order(:id))
      end

      if include.include?(:movies)
        one_to_many(list, movies.order(:id))
      end

      if include.include?(:videogames)
        one_to_many(list, videogames.order(:id))
      end

      if include.include?(:hobbies)
        one_to_many(list, hobbies.order(:id), assoc_setter: :set_hobbies)
      end

      if include.include?(:skills)
        one_to_many(list, skills.order(:id))
      end

      if include.include?(:vinyls)
        one_to_many(list, vinyls.order(:id))
      end

      if include.include?(:pets)
        one_to_many(list, pets.order(:id))
      end

      if include.include?(:dreams)
        one_to_many(list, dreams.order(:id))
      end

      if include.include?(:passport)
        one_to_one(list, user_passports.order(:id), reverse: true, assoc_setter: :set_passport)
      end

      if ids_or_scope.is_a?(Array)
        list.sort_by { ids_or_scope.index(_1.id) }
      else
        list
      end
    end
  end

  let(:users_agg) { ReeDaoLoadAggTest::UsersAggBenchmark.new }
  let(:users_sync_fetcher) { ReeDaoLoadAggTest::UsersSyncFetcher.new }

  let(:organizations) { ReeDaoLoadAggTest::Organizations.new }
  let(:users) { ReeDaoLoadAggTest::Users.new }
  let(:user_passports) { ReeDaoLoadAggTest::UserPassports.new }
  let(:books) { ReeDaoLoadAggTest::Books.new }
  let(:movies) { ReeDaoLoadAggTest::Movies.new }
  let(:videogames) { ReeDaoLoadAggTest::Videogames.new }
  let(:hobbies) { ReeDaoLoadAggTest::Hobbies.new }
  let(:vinyls) { ReeDaoLoadAggTest::Vinyls.new }
  let(:pets) { ReeDaoLoadAggTest::Pets.new }
  let(:skills) { ReeDaoLoadAggTest::Skills.new }
  let(:dreams) { ReeDaoLoadAggTest::Dreams.new }

  before(:each) do
    organization = ReeDaoLoadAggTest::Organization.new(name: "Test Org")
    organizations.put(organization)

    _users = []
    st_time = Time.now
    puts "Seeding #{NUM_OF_USERS} users..."
    NUM_OF_USERS.times do
      u = ReeDaoLoadAggTest::User.new(
        name: Faker::Name.name,
        age: rand(18..50),
        organization_id: organization.id
      )

      _users << u
      users.put(u)
    end

    _users.each do |user|
      ASSOC_COUNT.times do
        books.put(
          ReeDaoLoadAggTest::Book.new(
            title: Faker::Book.title,
            user_id: user.id
          )
        )
      end

      ASSOC_COUNT.times do
        movies.put(
          ReeDaoLoadAggTest::Movie.new(
            user_id: user.id,
            title: Faker::Movie.title
          )
        )
      end

      ASSOC_COUNT.times do
        videogames.put(
          ReeDaoLoadAggTest::Videogame.new(
            user_id: user.id,
            title: Faker::Game.title
          )
        )
      end

      ASSOC_COUNT.times do
        hobbies.put(
          ReeDaoLoadAggTest::Hobby.new(
            user_id: user.id,
            title: Faker::Hobby.activity
          )
        )
      end

      ASSOC_COUNT.times do
        vinyls.put(
          ReeDaoLoadAggTest::Vinyl.new(
            user_id: user.id,
            title: Faker::Music.band
          )
        )
      end

      ASSOC_COUNT.times do
        pets.put(
          ReeDaoLoadAggTest::Pet.new(
            user_id: user.id,
            name: Faker::Creature::Animal.name
          )
        )
      end

      ASSOC_COUNT.times do
        skills.put(
          ReeDaoLoadAggTest::Skill.new(
            user_id: user.id,
            title: Faker::Job.key_skill
          )
        )
      end

      ASSOC_COUNT.times do
        dreams.put(
          ReeDaoLoadAggTest::Dream.new(
            user_id: user.id,
            description: Faker::ChuckNorris.fact
          )
        )
      end

      ASSOC_COUNT.times do
        user_passports.put(
          ReeDaoLoadAggTest::UserPassport.new(
            user_id: user.id,
            info: "Passport info #{user.id}"
          )
        )
      end
    end

    puts "Seeding is complete! #{Time.now - st_time}"
  end

  it {
    res1 = nil
    res2 = nil
    res3 = nil

    benchmark_res = Benchmark.bm do |x|
      x.report("async_load_agg") do
        res1 = users_agg.call(users.all.map(&:id))
      end

      x.report("sync_load_agg ") do
        ENV['REE_DAO_SYNC_ASSOCIATIONS'] = "true"
        res2 = users_agg.call(users.all.map(&:id))
        ENV.delete('REE_DAO_SYNC_ASSOCIATIONS')
      end

      x.report("sync_fetcher  ") do
        res3 = users_sync_fetcher.call(
        users.all.map(&:id),
        include: [
          :organization,
          :books,
          :movies,
          :videogames,
          :hobbies,
          :vinyls,
          :pets,
          :skills,
          :dreams,
          :passport
        ]
      )
      end
    end

    expect(res1).to eq(res3)
    expect(res1[0].organization).to eq(res3[0].organization)
    expect(res1[0].passport).to eq(res3[0].passport)
    expect(res1[0].books).to eq(res3[0].books)
    expect(res1[0].movies).to eq(res3[0].movies)
    expect(res1[0].books).to eq(res3[0].books)
    expect(res1[0].videogames).to eq(res3[0].videogames)
    expect(res1[0].hobbies).to eq(res3[0].hobbies)
    expect(res1[0].vinyls).to eq(res3[0].vinyls)
    expect(res1[0].pets).to eq(res3[0].pets)
    expect(res1[0].skills).to eq(res3[0].skills)
    expect(res1[0].dreams).to eq(res3[0].dreams)

    expect(res2).to eq(res3)
    expect(res2[0].organization).to eq(res3[0].organization)
    expect(res2[0].books).to eq(res3[0].books)
    expect(res2[0].movies).to eq(res3[0].movies)
    expect(res2[0].videogames).to eq(res3[0].videogames)
    expect(res2[0].hobbies).to eq(res3[0].hobbies)
    expect(res2[0].vinyls).to eq(res3[0].vinyls)
    expect(res2[0].pets).to eq(res3[0].pets)
    expect(res2[0].skills).to eq(res3[0].skills)
    expect(res2[0].dreams).to eq(res3[0].dreams)

    # expect(benchmark_res[0].real).to be < benchmark_res[1].real
    # expect(benchmark_res[0].real).to be < benchmark_res[2].real
  }
end