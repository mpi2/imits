# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityTest < ActionDispatch::IntegrationTest

  DEBUG = false

  context 'Reports::MiProduction::SummaryMonthByMonthActivity' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production'
      assert_login_page
    end

    context 'once logged in' do

    setup do
      visit '/users/logout'
      login
    end

    should 'allow users to visit the page & see entries & click cell' do

      2.times do
        es_cell = Factory.create :es_cell
        mi = Factory.create :mi_attempt, :es_cell => es_cell,
                :consortium_name => 'BaSH', :production_centre_name => 'WTSI'
        replace_status_stamps(mi, 'Micro-injection in progress' => '2011-08-01')
        mi = Factory.create :mi_attempt, :es_cell => es_cell,
                :consortium_name => 'BaSH', :production_centre_name => 'WTSI'
        replace_status_stamps(mi, 'Micro-injection in progress' => '2011-08-01')
      end

      visit '/reports/mi_production/summary_month_by_month_activity?komp2=true'
      assert_match '/reports/mi_production/summary_month_by_month_activity?komp2=true', current_url

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

end
