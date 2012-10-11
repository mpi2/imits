# encoding: utf-8

require 'test_helper'

class StatusInterfaceTest < ActiveSupport::TestCase
  context 'StatusInterface' do

    should 'have #[] shortcut' do
      s = Test::Person::Status.create!(:name => 'Fake Status', :code => 'fake')
      assert_equal s, Test::Person::Status['Fake Status']
      assert_equal s, Test::Person::Status['fake']

      assert_raise(ActiveRecord::RecordNotFound) { Test::Person::Status['Nonexistent'] }
    end

  end
end
