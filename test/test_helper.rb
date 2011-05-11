ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'shoulda'
require 'factory_girl_rails'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  def setup
    DatabaseCleaner.strategy = :transaction
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

class ActionDispatch::IntegrationTest
  include Capybara

  def setup
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
    load Rails.root + 'db/seeds.rb'
  end

  def teardown
    Capybara.reset_sessions!
    DatabaseCleaner.clean
  end

  def login
    visit '/login'
    fill_in 'Username', :with => 'zz99'
    fill_in 'Password', :with => 'password'
    click_button 'Login'
    assert_not_match(%r{^http://[^/]+/login$}, current_url)
  end

  def selector_for_table_cell(table_row)
    ".x-grid3-body .x-grid3-row:nth-child(#{table_row}) .x-grid3-cell-inner"
  end

end
