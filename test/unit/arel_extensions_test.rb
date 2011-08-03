# encoding: utf-8

require 'test_helper'

class ArelExtensionsTest < ActiveSupport::TestCase
  context 'Arel extension' do

    context 'ci_in' do
      should 'work' do
        Test::Person.create!(:name => 'Ali')
        Test::Person.create!(:name => 'Fred')
        Test::Person.create!(:name => 'Bob')

        assert_equal ['Ali', 'Bob'],
                Test::Person.where(Test::Person.arel_table[:name].ci_in(['ali', 'bob'])).map(&:name)

      end
    end

  end
end
