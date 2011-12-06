# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < ActionDispatch::IntegrationTest
  context 'MI production report' do

    setup do
      login
    end

    context '(detailed version)' do
      should 'have link to cached report' do
        Factory.create :mi_plan

        assert_equal 0, ReportCache.count
        Reports::MiProduction::Detail.generate_and_cache
        cache = ReportCache.first
        assert cache

        cache.update_attributes!(:updated_at => '2011-12-01 23:59:59 UTC')
        visit '/reports'
        click_link 'Detailed Report'
        assert page.has_css? "a[href='/report_caches/mi_production_detail.csv?20111201235959']"
      end

      should 'not have a link when no report is cached' do
        assert_equal 0, ReportCache.count

        visit '/reports/mi_production'
        assert page.has_no_content? '/report_caches/mi_production_detail'
      end
    end

  end
end
