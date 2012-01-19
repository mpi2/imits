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

    context '#replace_status_stamps' do
      should 'work for MiAttempt' do
        mi = Factory.create :mi_attempt_genotype_confirmed
        expected = [
          ['Micro-injection in progress', '2010-03-11 07:12:03 UTC'],
          ['Genotype confirmed', '2011-01-12 20:12:44 UTC'],
          ['Genotype confirmed', '2012-05-13 05:04:01 UTC']
        ]
        replace_status_stamps(mi, expected)

        got = mi.status_stamps.map {|i| [i.description, i.created_at.to_s]}
        assert_equal expected, got
      end

      should 'work for other' do
        plan = Factory.create :mi_plan, :status => MiPlan::Status['Assigned']
        expected = [
          ['Interest', '2011-03-11 01:01:01 UTC'],
          ['Conflict', '2011-04-12 02:02:02 UTC'],
          ['Assigned', '2011-05-13 03:03:03 UTC']
        ]
        replace_status_stamps(plan, expected)

        got = plan.status_stamps.map {|i| [i.name, i.created_at.to_s]}
        assert_equal expected, got
      end
    end

  end
end
