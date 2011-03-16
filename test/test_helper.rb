ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'shoulda'

class ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  set_fixture_class(
    :per_centre => 'Centre',
    :emi_attempt => 'MiAttempt',
    :emi_clone => 'Clone',
    :emi_event => 'EmiEvent',
    :emi_status_dict => 'MiAttemptStatus',
    :per_person => 'User'
  )

  fixtures :per_person, :per_centre, :emi_status_dict, :emi_clone, :emi_event, :emi_attempt

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
end
