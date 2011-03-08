# encoding: utf-8

require 'test_helper'

class MiAttemptTest < ActiveSupport::TestCase

  def default_mi_attempt
    @default_mi_attempt ||= emi_attempt('EPD0127_4_E01__1')
  end

  should 'use table "emi_attempt"' do
    assert_equal 'emi_attempt', MiAttempt.table_name
  end

  should 'belong to emi_event' do
    assert_equal emi_event('EPD0127_4_E01'), emi_attempt('EPD0127_4_E01__1').emi_event
  end

  should 'belong to clone through emi event' do
    assert_equal emi_clone('EPD0127_4_E01'), emi_attempt('EPD0127_4_E01__1').clone
  end

  context '::search (and hence the scopes by_clone names, by_gene_symbols and by_colony_names)' do

    should 'work for single clone' do
      results = MiAttempt.search(['EPD0127_4_E01'])
      assert_equal 3, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
    end

    should 'work for single clone case-insensitively' do
      results = MiAttempt.search(['epd0127_4_E01'])
      assert_equal 3, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
    end

    should 'work for multiple clones' do
      results = MiAttempt.search(['EPD0127_4_E01', 'EPD0343_1_H06'])
      assert_equal 4, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
      assert results.include? emi_attempt('EPD0343_1_H06__1')
    end

    should 'work for single gene symbol' do
      results = MiAttempt.search(['Myo1c'])
      assert_equal 1, results.size
      assert results.include? emi_attempt('EPD0343_1_H06__1')
    end

    should 'work for single gene symbol case-insensitively' do
      results = MiAttempt.search(['myo1C'])
      assert_equal 1, results.size
      assert results.include? emi_attempt('EPD0343_1_H06__1')
    end

    should 'work for multiple gene symbols' do
      results = MiAttempt.search(['Trafd1', 'Myo1c'])
      assert_equal 4, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
      assert results.include? emi_attempt('EPD0343_1_H06__1')
    end

    should 'work for single colony name' do
      results = MiAttempt.search(['MBSS'])
      assert_equal 2, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
    end

    should 'work for single colony name case-insensitively' do
      results = MiAttempt.search(['mbss'])
      assert_equal 2, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
    end

    should 'work for multiple colony names' do
      results = MiAttempt.search(['MBSS', 'WBAA'])
      assert_equal 3, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
    end

    should 'work when mixing clone names, gene symbols and colony names' do
      results = MiAttempt.search(['EPD0127_4_E01', 'Myo1c', 'MBFD'])
      assert_equal 5, results.size
      assert results.include? emi_attempt('EPD0127_4_E01__1')
      assert results.include? emi_attempt('EPD0127_4_E01__2')
      assert results.include? emi_attempt('EPD0127_4_E01__3')
      assert results.include? emi_attempt('EPD0343_1_H06__1')
      assert results.include? emi_attempt('EPD0029_1_G04__1')
    end

    should 'not have duplicates in results' do
      results = MiAttempt.search(['EPD0127_4_E01', 'Trafd1'])
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
    should 'be :suitable if emma=true and is_emma_sticky=false' do
      default_mi_attempt.emma = '1'
      default_mi_attempt.is_emma_sticky = false
      assert_equal :suitable, default_mi_attempt.emma_status
    end

    should 'be :unsuitable if emma=false and is_emma_sticky=false' do
      default_mi_attempt.emma = '0'
      default_mi_attempt.is_emma_sticky = false
      assert_equal :unsuitable, default_mi_attempt.emma_status
    end

    should 'be :suitable_sticky if emma=true and is_emma_sticky=true' do
      default_mi_attempt.emma = '1'
      default_mi_attempt.is_emma_sticky = true
      assert_equal :suitable_sticky, default_mi_attempt.emma_status
    end

    should 'be :unsuitable_sticky if emma=false and is_emma_sticky=true' do
      default_mi_attempt.emma = '0'
      default_mi_attempt.is_emma_sticky = true
      assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
    end
  end

  context '#emma_status=' do
    should 'work for suitable' do
      default_mi_attempt.emma_status = 'suitable'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['1', false], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'work for unsuitable' do
      default_mi_attempt.emma_status = 'unsuitable'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['0', false], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'work for :suitable_sticky' do
      default_mi_attempt.emma_status = 'suitable_sticky'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['1', true], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'work for :unsuitable_sticky' do
      default_mi_attempt.emma_status = 'unsuitable_sticky'
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal ['0', true], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
    end

    should 'error for anything else' do
      assert_raise(MiAttempt::EmmaStatusError) do
        default_mi_attempt.emma_status = 'invalid'
      end
    end

    should 'set cause #emma_status to return the right value after being saved' do
      default_mi_attempt.emma_status = 'unsuitable_sticky'
      default_mi_attempt.save!
      default_mi_attempt.reload

      assert_equal ['0', true], [default_mi_attempt.emma, default_mi_attempt.is_emma_sticky]
      assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
    end
  end

  should belong_to :mi_attempt_status

end
