ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'shoulda'

class ActiveSupport::TestCase
  fixtures :emi_clone, :emi_event, :emi_attempt

  # Add more helper methods to be used by all tests here...
end
