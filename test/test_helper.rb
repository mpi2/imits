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
  end

  def teardown
    DatabaseCleaner.clean
  end
end


require 'capybara/rails'
require 'capybara/dsl'

Capybara.default_driver = :selenium

class ActionDispatch::IntegrationTest
  include Capybara

  def setup
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.start
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

  def default_mi_attempt
    @default_mi_attempt ||= emi_attempt('EPD0343_1_H06__1')
  end

  def selector_for_table_cell(table_row)
    ".x-grid3-body .x-grid3-row:nth-child(#{table_row}) .x-grid3-cell-inner"
  end

end
