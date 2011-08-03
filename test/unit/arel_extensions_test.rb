# encoding: utf-8

require 'test_helper'

class ArelExtensionsTest < ActiveSupport::TestCase
  context 'Arel extension' do
    context 'case_insensitive_eq' do
      should 'work' do
        p = Test::Person.create!(:name => 'Fred')
        assert_equal p, Test::Person.where(Test::Person.arel_table[:name].ci_eq('fred')).first
      end
    end
  end
end
