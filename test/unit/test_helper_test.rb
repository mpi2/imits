# encoding: utf-8

require 'test_helper'

class TestHelperTest < ActiveSupport::TestCase
  context 'Test helper tests:' do

    context '#assert_should' do
      subject { Test::Person.create! :name => 'Assert Should Test' }

      should 'work' do
        assert_should validate_uniqueness_of :name
      end
    end

    context '#assert_should_not' do
      subject { Test::Person.new :name => 'Assert Should Test' }

      should 'work' do
        assert_should_not validate_numericality_of :name
      end
    end

  end
end
