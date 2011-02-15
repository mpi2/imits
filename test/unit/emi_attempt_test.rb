require 'test_helper'

class EmiAttemptTest < ActiveSupport::TestCase
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
    setup do
      @emi_attempt = emi_attempt('EPD0127_4_E01__1')
    end

    should '#clone_name' do
      assert_equal 'EPD0127_4_E01', @emi_attempt.clone_name
    end

    should '#gene_symbol' do
      assert_equal 'Trafd1', @emi_attempt.gene_symbol
    end

    should '#allele_name' do
      assert_equal 'Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>', @emi_attempt.allele_name
    end

    should '#proposed_mi_date' do
      assert_equal Date.parse('2008-07-29'), @emi_attempt.proposed_mi_date.to_date
    end
  end

  should '#formatted_proposed_mi_date' do
    assert_equal '29 July 2008', emi_attempt('EPD0127_4_E01__1').formatted_proposed_mi_date
  end

  should '#formatted_actual_mi_date' do
    assert_equal '30 July 2008', emi_attempt('EPD0127_4_E01__1').formatted_actual_mi_date
  end
end
