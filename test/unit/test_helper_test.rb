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
        mi = Factory.create :mi_attempt2_status_gtc, :mi_date => '2010-03-11'

        expected = [
          ['Micro-injection in progress', '2010-03-11 00:00:00 UTC'],
          ['Chimeras obtained', '2010-03-12 07:43:03 UTC'],
          ['Chimeras/Founder obtained', '2012-03-12 07:43:03 UTC'],
          ['Genotype confirmed', '2012-05-13 05:04:01 UTC']
        ]
        replace_status_stamps(mi, expected)

        got = mi.status_stamps.map {|i| [i.name, i.created_at.to_s]}
        assert_equal expected, got
      end

      should 'work for other' do
        plan = Factory.create :mi_plan
        expected = [
          ['Assigned', '2011-05-13 03:03:03 UTC']
        ]
        replace_status_stamps(plan, expected)

        got = plan.status_stamps.map {|i| [i.name, i.created_at.to_s]}
        assert_equal expected, got
      end

      should 'take only dates for status stamps' do
        plan = Factory.create :mi_plan, :number_of_es_cells_starting_qc => 1
        replace_status_stamps(plan,
           'Assigned' => '2011-05-13',
           'Assigned - ES Cell QC In Progress' => '2011-08-13')
        expected = [
          ['Assigned', '2011-05-13 00:00:00 UTC'],
          ['Assigned - ES Cell QC In Progress', '2011-08-13 00:00:00 UTC']
        ]
        got = plan.status_stamps.map {|i| [i.name, i.created_at.to_s]}
        assert_equal expected, got
      end
    end

  end
end
