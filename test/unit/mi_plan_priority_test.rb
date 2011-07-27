# encoding: utf-8

require 'test_helper'

class MiPlanPriorityTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name
  should have_many :mi_plans
end
