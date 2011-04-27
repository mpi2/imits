# encoding: utf-8

require 'test_helper'

class Old::MiAttemptTest < ActiveSupport::TestCase
  context 'Old::MiAttempt' do

    def default_clone
      @default_clone ||= Old::Clone.find 83470.0
    end

    def default_emi_event
      @default_emi_event ||= Old::EmiEvent.find 6561
    end

    def default_mi_attempt
      @default_mi_attempt ||= Old::MiAttempt.find 11029.0
    end

    def alternative_mi_attempt
      @alternative_mi_attempt ||= Old::MiAttempt.find(11783.0)
    end

    should 'be read only by default' do
      assert_equal true, default_mi_attempt.readonly?
    end

    should 'use table "emi_attempt"' do
      assert_equal 'emi_attempt', Old::MiAttempt.table_name
    end

    should 'belong to emi_event' do
      assert_equal default_emi_event, default_mi_attempt.emi_event
    end

    should 'belong to clone through emi event' do
      assert_equal default_clone, default_mi_attempt.clone
    end

    context '::search scope' do

      should 'return all results when not given any search terms' do
        results = Old::MiAttempt.search([])
        assert_equal Old::MiAttempt.count, results.size
      end

      should 'return all results when only blank lines are in search terms' do
        results = Old::MiAttempt.search(["", "\t", "    "])
        assert_equal Old::MiAttempt.count, results.size
      end

      should 'work for single clone' do
        results = Old::MiAttempt.search(['EPD0127_4_E01'])
        assert_equal 5, results.size
        assert results.include? default_mi_attempt
      end

      should 'work for single clone case-insensitively' do
        results = Old::MiAttempt.search(['epd0127_4_E01'])
        assert_equal 5, results.size
        assert results.include? default_mi_attempt
      end

      should 'work for multiple clones' do
        results = Old::MiAttempt.search(['EPD0127_4_E01', 'EPD0343_1_H06'])
        assert_equal 7, results.size
        assert results.include? default_mi_attempt
        assert results.include? alternative_mi_attempt
      end

      should 'work for single gene symbol' do
        results = Old::MiAttempt.search(['Myo1c'])
        assert_equal 2, results.size
        assert results.include? alternative_mi_attempt
      end

      should 'work for single gene symbol case-insensitively' do
        results = Old::MiAttempt.search(['myo1C'])
        assert_equal 2, results.size
        assert results.include? alternative_mi_attempt
      end

      should 'work for multiple gene symbols' do
        results = Old::MiAttempt.search(['Trafd1', 'Myo1c'])
        assert_equal 7, results.size
        assert results.include? default_mi_attempt
        assert results.include? alternative_mi_attempt
      end

      should 'work for single colony name' do
        results = Old::MiAttempt.search(['MBSS'])
        assert_equal 2, results.size
        assert results.include? default_mi_attempt
      end

      should 'work for single colony name case-insensitively' do
        results = Old::MiAttempt.search(['mbss'])
        assert_equal 2, results.size
        assert results.include? default_mi_attempt
      end

      should 'work for multiple colony names' do
        results = Old::MiAttempt.search(['MBSS', 'WBAA'])
        assert_equal 3, results.size
        assert results.include? default_mi_attempt
      end

      should 'work when mixing clone names, gene symbols and colony names' do
        results = Old::MiAttempt.search(['EPD0127_4_E01', 'Myo1c', 'MBFD'])
        assert_equal 8, results.size
        assert results.include? default_mi_attempt
        assert results.include? alternative_mi_attempt
        assert results.include? Old::MiAttempt.find 5409.0
      end

      should 'not have duplicates in results' do
        results = Old::MiAttempt.search(['EPD0127_4_E01', 'Trafd1'])
        assert_equal 5, results.size
        assert results.include? default_mi_attempt
      end

      should 'be orderable' do
        results = Old::MiAttempt.search(['EPD0127_4_E01', 'Trafd1']).order('emi_clones.clone_name DESC')
      end
    end

    should 'have scope ::sort_by_clone_name' do
      got = Old::MiAttempt.sort_by_clone_name(:desc).take(5).collect(&:clone_name)
      assert_equal got.sort.reverse, got
    end

    should 'have scope ::sort_by_gene_symbol' do
      got = Old::MiAttempt.sort_by_gene_symbol(:desc).take(10).collect(&:gene_symbol)
      assert_equal got.sort.reverse, got
    end

    should 'have scope ::sort_by_allele_name' do
      got = Old::MiAttempt.find_by_sql(Old::MiAttempt.sort_by_allele_name(:desc).skip(400).take(10).to_sql).collect(&:allele_name)
      assert_equal got.sort.reverse, got
    end

    should 'have scope ::sort_by_mi_attempt_status' do
      got = Old::MiAttempt.sort_by_mi_attempt_status(:asc).collect(&:mi_attempt_status).collect(&:name)
      assert_equal got.sort, got
    end

    should 'have scope ::sort_by_distribution_centre_name' do
      got = Old::MiAttempt.sort_by_distribution_centre_name(:desc).collect(&:distribution_centre_name)
      assert_equal got.sort.reverse, got
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
        assert_equal Old::Centre.find_by_name('CNB'), default_mi_attempt.distribution_centre
      end
    end

    should 'have #distribution_centre_name' do
      assert_equal 'CNB', default_mi_attempt.distribution_centre_name
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

    should belong_to :mi_attempt_status

  end
end
