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

  def assert_strain_types(strain_class, strain_file)
    names = strain_class.joins(:strain).order(:id).map {|i| i.strain.name}
    assert_equal names.sort, File.read(Rails.root + "config/strains/#{strain_file}.txt").split("\n").sort
  end

  fixtures :all
end

require 'capybara/rails'
require 'capybara/dsl'

Capybara.default_driver = :selenium

class ActionDispatch::IntegrationTest < ActiveSupport::TestCase
  include Capybara

  def database_strategy; :deletion; end

  def teardown
    Capybara.reset_sessions!
    super
  end

  def login(email = nil)
    if email.nil?
      @login_default_user ||= Factory.create :user
      email = @login_default_user.email
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

class InMemoryPerson < ActiveRecord::Base
  self.establish_connection({:adapter => 'sqlite3', :database => ':memory:', :verbosity => false})

  self.connection.create_table 'in_memory_people', :force => true do |t|
    t.text 'name'
  end
end
