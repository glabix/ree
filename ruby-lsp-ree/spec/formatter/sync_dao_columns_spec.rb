# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "RubyLsp::Ree::ReeFormatter" do
  subject{ RubyLsp::Ree::ReeFormatter.new([], {}) }

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
    expect(entity_file_content.lines[6].strip).to eq('db_field :id, Nilor[Integer], default: nil')
  end
end
