# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityAllCentresTest < TarMits::IntegrationTest

  DEBUG = true

  context '/reports/mi_production/summary_month_by_month_activity_all_centres_*' do

    setup do
      visit '/users/logout'
      login
    end

    should 'allow users to visit the page & see entries & click cell for komp2' do
      plan1 = TestDummy.mi_plan('BaSH', 'WTSI')
      plan1.update_attributes!(:number_of_es_cells_starting_qc => 1)
      plan2 = TestDummy.mi_plan('BaSH', 'WTSI')
      plan2.update_attributes!(:number_of_es_cells_starting_qc => 1)
      #Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache

      visit '/reports/mi_production/summary_month_by_month_activity_all_centres_komp2'

      assert page.has_content? 'KOMP2 Summary Month by Month'
      assert page.has_content? 'Download as CSV'

      save_and_open_page if DEBUG

      click_link "2"

      assert page.has_content? 'Details'
      assert page.has_content? 'Download as CSV'

      save_and_open_page if DEBUG
      sleep(10.seconds) if DEBUG
    end

  end

end
