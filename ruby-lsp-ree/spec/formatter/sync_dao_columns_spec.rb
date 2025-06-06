# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

  let(:entity_file_name){ sample_package_entities_dir + '/user.rb' }
 
  before :each do
    @entity_cache = store_file_cache(entity_file_name)
  end

  after :each do
    restore_file_cache(entity_file_name, @entity_cache)
  end

  it "syncs db columns from dao to entity" do
    source =  <<~RUBY
      class SamplePackage::Users
        include ReeDao::DSL

        dao :users do
          link :db, from: :sample_package_db
          link "sample_package/entities/user", -> { User }
        end

        schema User do
          integer :id, null: true
        end

        filter :by_identity, -> (id) { where(identity_id: id) }
        filter :active, -> { where(state: 'active') }
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
    entity_file_content = File.read(entity_file_name)
    expect(entity_file_content.lines[6].strip).to eq('column :id, Nilor[Integer], default: nil')
  end

  it "adds column to the empty build dto" do
    entity_file_lines = File.read(entity_file_name).lines
    entity_file_lines[5] = ''
    File.write(entity_file_name, entity_file_lines.join)

    source =  <<~RUBY
      class SamplePackage::Users
        include ReeDao::DSL

        dao :users do
          link :db, from: :sample_package_db
          link "sample_package/entities/user", -> { User }
        end

        schema User do
          integer :id, null: true
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
    entity_file_content = File.read(entity_file_name)
    expect(entity_file_content.lines[4].strip).to eq('build_dto do')
    expect(entity_file_content.lines[5].strip).to eq('column :id, Nilor[Integer], default: nil')
    expect(entity_file_content.lines[6].strip).to eq('end')
  end

  it "adds multiple columns" do
    source =  <<~RUBY
      class SamplePackage::Users
        include ReeDao::DSL

        dao :users do
          link :db, from: :sample_package_db
          link "sample_package/entities/user", -> { User }
        end

        schema User do
          integer :id, null: true
          string :name
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
    entity_file_content = File.read(entity_file_name)
    expect(entity_file_content.lines[6].strip).to eq('column :id, Nilor[Integer], default: nil')
    expect(entity_file_content.lines[7].strip).to eq('column :name, String')
  end

  it "adds hash field for pg_jsonb" do
    source =  <<~RUBY
      class SamplePackage::Users
        include ReeDao::DSL

        dao :users do
          link :db, from: :sample_package_db
          link "sample_package/entities/user", -> { User }
        end

        schema User do
          pg_jsonb :data
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
    entity_file_content = File.read(entity_file_name)
    expect(entity_file_content.lines[6].strip).to eq('column :data, Nilor[Hash], default: nil')
  end

  it "adds correct field for custom types" do
    source =  <<~RUBY
      class SamplePackage::Users
        include ReeDao::DSL

        dao :users do
          link :db, from: :sample_package_db
          link "sample_package/entities/user", -> { User }
        end

        schema User do
          user_types :user_type
        end
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
    entity_file_content = File.read(entity_file_name)
    expect(entity_file_content.lines[6].strip).to eq('column :user_type, UserTypes')
  end

  context "dao fields deduplication" do
    it "removes duplicated fields" do
      source =  <<~RUBY
        class SamplePackage::Users
          include ReeDao::DSL

          dao :users do
            link :db, from: :sample_package_db
            link "sample_package/entities/user", -> { User }
          end

          schema User do
            integer :id, null: true
            string :id
          end
        end
      RUBY

      result = subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
      expect(result.lines[7].strip).to eq('schema User do')
      expect(result.lines[8].strip).to eq('integer :id, null: true')
      expect(result.lines[9].strip).to eq('end')
    end

    it "syncs only uniq fields from dao to entity" do
      source =  <<~RUBY
        class SamplePackage::Users
          include ReeDao::DSL
  
          dao :users do
            link :db, from: :sample_package_db
            link "sample_package/entities/user", -> { User }
          end
  
          schema User do
            integer :id, null: true
            string :id, null: true
            string :phone, null: true
            integer :phone, null: true
          end
        end
      RUBY
  
      subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))

      entity_file_content = File.read(entity_file_name)
      expect(entity_file_content.lines[6].strip).to eq('column :id, Nilor[Integer], default: nil')
      expect(entity_file_content.lines[7].strip).to eq('column :phone, Nilor[String], default: nil')
      expect(entity_file_content.lines[8].strip).to eq('end')
    end
  
  end
end