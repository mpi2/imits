ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'shoulda'
require 'factory_girl_rails'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  def database_strategy; :transaction; end

  def setup
    DatabaseCleaner.strategy = self.database_strategy
    DatabaseCleaner.start
    load Rails.root + 'db/seeds.rb'
    InMemoryPerson.destroy_all
  end

  def teardown
    DatabaseCleaner.clean
  end

  def create_common_test_objects
    Factory.create(:clone_EPD0127_4_E01)
    Factory.create(:clone_EPD0343_1_H06)
    Factory.create(:clone_EPD0029_1_G04)
  end

  def default_user
    @default_user ||= Factory.create :user, :email => 'test@example.com', :password => 'password'
  end

  def assert_should(matcher)
    assert_accepts matcher, subject
  end

  def assert_should_not(matcher)
    assert_rejects matcher, subject
  end

  fixtures :all
end

require 'capybara/rails'
require 'capybara/dsl'

Capybara.default_driver = :selenium

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  include Capybara::DSL

  def database_strategy; :deletion; end

  def teardown
    Capybara.reset_sessions!
    super
  end

  def login(email = nil)
    if email.nil?
      email = default_user.email
    end
    visit '/users/login'
    fill_in 'Email', :with => email
    fill_in 'Password', :with => 'password'
    click_button 'Login'
    assert_not_match(%r{^http://[^/]+/users/login$}, current_url)
  end

  def assert_login_page
    assert_match(%r{^http://[^/]+/users/login$}, current_url)
  end

  def selector_for_table_cell(table_row)
    ".x-grid3-body .x-grid3-row:nth-child(#{table_row}) .x-grid3-cell-inner"
  end

end

class ActionController::TestCase
  include Devise::TestHelpers

  def parse_xml_from_response
    return Nokogiri::XML(response.body)
  end

  def parse_json_from_response
    return JSON.parse(response.body)
  end
end

class Kermits2::StrainsTestCase < ActiveSupport::TestCase
  def self.strain_tests_for(strains_class)
    table_name = strains_class.name.demodulize.tableize

    context strains_class.name do
      should have_db_column(:id).with_options(:null => false)
      should have_db_index(:id).unique(true)
      should belong_to :strain

      should 'be populated with correct data' do
        names = strains_class.joins(:strain).order(:id).map {|i| i.strain.name}
        assert_equal names.sort, File.read(Rails.root + "config/strains/#{table_name}.txt").split("\n").sort
      end

      should 'delegate #name to Strain' do
        sid = strains_class.find(:first)
        assert_equal sid.name, sid.strain.name
      end

      context '::find_by_name' do
        should 'find the row with given strain name' do
          strains_object = strains_class.first
          strain_name = Strain.find(strains_object.id).name
          assert_equal strains_object, strains_class.find_by_name(strain_name)
        end

        should 'return nil if said strain does not exist' do
          assert_nil strains_class.find_by_name('Nonexistent')
        end

        should 'return nil if said strain is not of the right type' do
          Strain.create!(:name => 'Not of any type')
          assert_nil strains_class.find_by_name('Not of any type')
        end
      end

      context '::find_by_name!' do
        should 'find the row with given strain name' do
          strains_object = strains_class.first
          strain_name = Strain.find(strains_object.id).name
          assert_equal strains_object, strains_class.find_by_name!(strain_name)
        end

        should 'raise if said name does not exist' do
          assert_raise(ActiveRecord::RecordNotFound) do
            strains_class.find_by_name!('Nonexistent')
          end
        end
      end

    end

  end

end

IN_MEMORY_MODEL_CONNECTION_PARAMS = {:adapter => 'sqlite3', :database => ':memory:', :verbosity => false}

class InMemoryPerson < ActiveRecord::Base
  self.establish_connection IN_MEMORY_MODEL_CONNECTION_PARAMS

  self.connection.create_table :in_memory_people, :force => true do |t|
    t.text :name
  end

  validates :name, :uniqueness => true
end
