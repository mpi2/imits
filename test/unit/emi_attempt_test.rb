# encoding: utf-8

require 'test_helper'

class EmiAttemptTest < ActiveSupport::TestCase

  def default_mi_attempt
    @default_mi_attempt ||= emi_attempt('EPD0127_4_E01__1')
  end

  should 'use table "emi_attempt"' do
    assert_equal 'emi_attempt', EmiAttempt.table_name
  end

  should 'belong to emi_event' do
    assert_equal emi_event('EPD0127_4_E01'), emi_attempt('EPD0127_4_E01__1').emi_event
  end

  should 'belong to emi clone through emi event' do
    assert_equal emi_clone('EPD0127_4_E01'), emi_attempt('EPD0127_4_E01__1').emi_clone
  end

  context '::by_clone_names' do
    should 'work for multiple clones' do
      results = EmiAttempt.by_clone_names(['EPD0127_4_E01', 'EPD0343_1_H06'])
      assert_equal 4, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
      assert results.include? emi_attempt('EPD0343_1_H06__1')
    end

    should 'work for single clones' do
      results = EmiAttempt.by_clone_names(['EPD0127_4_E01'])
      assert_equal 3, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
    end
  end

  context 'delegated methods' do
    should '#clone_name' do
      assert_equal 'EPD0127_4_E01', default_mi_attempt.clone_name
    end

    should '#gene_symbol' do
      assert_equal 'Trafd1', default_mi_attempt.gene_symbol
    end

    should '#allele_name' do
      assert_equal 'Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>', default_mi_attempt.allele_name
    end

    should '#proposed_mi_date' do
      assert_equal Date.parse('2008-07-29'), default_mi_attempt.proposed_mi_date.to_date
    end

    should '#distribution_centre to event' do
      assert_equal default_mi_attempt.distribution_centre, per_centre('ICS')
    end
  end

  should '#formatted_proposed_mi_date' do
    assert_equal '29 July 2008', emi_attempt('EPD0127_4_E01__1').formatted_proposed_mi_date
  end

  should '#formatted_actual_mi_date' do
    assert_equal '30 July 2008', emi_attempt('EPD0127_4_E01__1').formatted_actual_mi_date
  end

  context '#set_distribution_centre_by_name' do
    should 'work' do
      default_mi_attempt.set_distribution_centre_by_name 'WTSI'
      default_mi_attempt.reload
      assert_equal 'WTSI', default_mi_attempt.emi_event.distribution_centre.name
    end

    should 'not allow assignment of nonexistent centres' do
      assert_raise(ActiveRecord::RecordNotFound) do
        default_mi_attempt.set_distribution_centre_by_name 'INVLD'
      end
    end
  end

  should 'have #distribution_centre_name' do
    assert_equal 'ICS', default_mi_attempt.distribution_centre_name
  end

  context '#emma?' do
    should 'return true if emma == "1"' do
      default_mi_attempt.emma = '1'
      assert_true default_mi_attempt.emma?
    end

    should 'return false if emma == "0"' do
      default_mi_attempt.emma = '0'
      assert_false default_mi_attempt.emma?
    end

    should 'return false if emma == ""' do
      default_mi_attempt.emma = ''
      assert_false default_mi_attempt.emma?
    end
  end

  context '#emma_status' do
    should 'be :on if emma=true and is_emma_sticky=false' do
      default_mi_attempt.emma = '1'
      default_mi_attempt.is_emma_sticky = false
      assert_equal :on, default_mi_attempt.emma_status
    end

    should 'be :off if emma=false and is_emma_sticky=false' do
      default_mi_attempt.emma = '0'
      default_mi_attempt.is_emma_sticky = false
      assert_equal :off, default_mi_attempt.emma_status
    end

    should 'be :force_on if emma=true and is_emma_sticky=true' do
      default_mi_attempt.emma = '1'
      default_mi_attempt.is_emma_sticky = true
      assert_equal :force_on, default_mi_attempt.emma_status
    end

    should 'be :force_off if emma=false and is_emma_sticky=true' do
      default_mi_attempt.emma = '0'
      default_mi_attempt.is_emma_sticky = true
      assert_equal :force_off, default_mi_attempt.emma_status
    end
  end

  context '#emma_status=' do
    should 'work for on' do
      default_mi_attempt.emma_status = 'on'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['1', false], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'work for off' do
      default_mi_attempt.emma_status = 'off'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['0', false], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'work for :force_on' do
      default_mi_attempt.emma_status = 'force_on'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['1', true], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'work for :force_off' do
      default_mi_attempt.emma_status = 'force_off'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['0', true], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'error for anything else' do
      assert_raise(EmiAttempt::EmmaStatusError) do
        default_mi_attempt.emma_status = 'invalid'
      end
    end

    should 'set cause #emma_status to return the right value after being saved' do
      default_mi_attempt.emma_status = 'force_off'
      default_mi_attempt.save!
      default_mi_attempt.reload

      assert_equal ['0', true], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
      assert_equal :force_off, default_mi_attempt.emma_status
    end
  end

end
