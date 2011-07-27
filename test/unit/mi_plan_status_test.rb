require 'test_helper'

class MiPlanStatusTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name
  should have_many :mi_plans
end
