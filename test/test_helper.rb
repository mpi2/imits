ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'shoulda'

module TestFixtures
  def self.included(mod)
    mod.set_fixture_class(
      :per_centre => 'Centre',
      :emi_attempt => 'MiAttempt',
      :emi_clone => 'Clone',
      :emi_event => 'EmiEvent',
      :emi_status_dict => 'MiAttemptStatus',
      :per_person => 'Person'
    )

    mod.fixtures :per_person, :per_centre, :emi_status_dict, :emi_clone, :emi_event, :emi_attempt
  end
end

class ActiveSupport::TestCase
  include TestFixtures

  # Add more helper methods to be used by all tests here...
end



require 'capybara/rails'
require 'capybara/dsl'

Capybara.default_driver = :selenium

class ActionDispatch::IntegrationTest
  include TestFixtures
  include Capybara
end
