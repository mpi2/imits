# encoding: utf-8

require 'test_helper'

class MiAttempt::AggregatedViewTest < ActiveSupport::TestCase
  context 'MiAttempt::AggregatedView' do

    should belong_to :latest_mi_attempt_status

    should 'search against the view, not the table' do
      mi = Factory.create :mi_attempt_genotype_confirmed
      mis = MiAttempt::AggregatedView.search(:latest_mi_attempt_status_description_eq => MiAttemptStatus.genotype_confirmed.description).result
      assert_equal [mi.colony_name], mis.map(&:colony_name)
    end

    should 'set root of XML output to mi-attempt, not mi-attempt-aggregated-view' do
      mi = MiAttempt::AggregatedView.find(Factory.create(:mi_attempt).id)
      assert_match '<mi-attempt>', mi.to_xml(:root => 'mi-attempt')
    end

  end
end
