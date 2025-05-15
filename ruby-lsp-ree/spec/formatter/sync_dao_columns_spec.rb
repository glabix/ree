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
      end
    RUBY

    subject.run_formatting(sample_package_file_uri('dao/users'), ruby_document(source))
    entity_file_content = File.read(sample_package_entities_dir + '/user.rb')
# pp entity_file_content
    expect(entity_file_content.lines[6].strip).to eq('column :id, Nilor[Integer], default: nil')
  end

  # TODO it "adds default value" do
  # TODO it "adds column to the empty build dto" do
  # TODO it "adds multiple columns" do
end
