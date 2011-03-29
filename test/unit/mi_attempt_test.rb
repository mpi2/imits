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

  context '::search scope' do

    should 'return all results when not given any search terms' do
      results = MiAttempt.search([])
      assert_equal MiAttempt.count, results.size
    end

    should 'return all results when only blank lines are in search terms' do
      results = MiAttempt.search(["", "\t", "    "])
      assert_equal MiAttempt.count, results.size
    end

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

    should 'be orderable' do
      results = MiAttempt.search(['EPD0127_4_E01', 'Trafd1']).order('emi_clones.clone_name DESC')
    end
  end

  should 'have scope ::sort_by_clone_name' do
    got = MiAttempt.sort_by_clone_name(:desc).collect(&:clone_name)
    expected = [
      'EPD0343_1_H06',
      'EPD0127_4_E01',
      'EPD0127_4_E01',
      'EPD0127_4_E01',
      'EPD0029_1_G04',
    ]
    assert_equal expected, got
  end

  should 'have scope ::sort_by_gene_symbol' do
    got = MiAttempt.sort_by_gene_symbol(:desc).collect(&:gene_symbol)
    expected = ["Trafd1", "Trafd1", "Trafd1", "Myo1c", "Gatc"]
    assert_equal expected, got
  end

  should 'have scope ::sort_by_allele_name' do
    got = MiAttempt.sort_by_allele_name(:desc).collect(&:allele_name)
    expected = [
      "Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>",
      "Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>",
      "Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>",
      "Myo1c<sup>tm1a(EUCOMM)Wtsi</sup>",
      "Gatc<sup>tm1a(KOMP)Wtsi</sup>"
    ]

    assert_equal expected, got
  end

  should 'have scope ::sort_by_mi_attempt_status' do
    got = MiAttempt.sort_by_mi_attempt_status(:asc).collect(&:mi_attempt_status).collect(&:name)
    expected = [
      "Genotype Confirmed",
      "Genotype Confirmed",
      "Genotype Confirmed",
      "Micro-injected",
      "Micro-injected"
    ]

    assert_equal expected, got
  end

  should 'have scope ::sort_by_distribution_centre_name' do
    got = MiAttempt.sort_by_distribution_centre_name(:desc).collect(&:distribution_centre_name)
    assert_equal ['WTSI', 'WTSI', 'ICS', 'ICS', 'ICS'], got
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
      assert_true default_mi_attempt.set_distribution_centre_by_name('WTSI', 'zz99')
      default_mi_attempt.reload
      assert_equal 'WTSI', default_mi_attempt.emi_event.distribution_centre.name
      assert_equal 'zz99', default_mi_attempt.emi_event.edited_by
    end

    should 'not allow assignment of nonexistent centres' do
      assert_raise(ActiveRecord::RecordNotFound) do
        default_mi_attempt.set_distribution_centre_by_name 'INVLD', nil
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

  context 'auditing' do
    setup do
      assert_equal Time.parse('2010-09-22 00:00:00 Z'), default_mi_attempt.edit_date, "Test cannot continue - edit_date must be before NOW to make sure it is set correctly on edit"
      assert_not_equal 'jb27', default_mi_attempt.edited_by
      default_mi_attempt.update_attributes!(:emma_status => 'unsuitable_sticky')
      default_mi_attempt.reload
    end

    should 'set edit_date to time of editing' do
      assert_in_delta Time.now, default_mi_attempt.edit_date, 60.seconds
    end
  end

  context 'before save filter' do
    should 'fill in total_chimeras before save' do
      default_mi_attempt.number_male_chimeras = 5
      default_mi_attempt.number_female_chimeras = 4
      default_mi_attempt.save!
      default_mi_attempt.reload
      assert_equal 9, default_mi_attempt.total_chimeras
    end
  end

  context 'before validation filter' do
    setup do
      default_mi_attempt.num_blasts = '12.12 string'
      default_mi_attempt.num_transferred = 13.13
      default_mi_attempt.total_f1_mice = 14.14
      default_mi_attempt.valid?
    end

    should 'integerify num_blasts' do
      assert_equal 12, default_mi_attempt.num_blasts
    end

    should 'integerify num_transferred' do
      assert_equal 13, default_mi_attempt.num_transferred
    end

    should 'integerify total_f1_mice' do
      assert_equal 14, default_mi_attempt.total_f1_mice
    end
  end

end
