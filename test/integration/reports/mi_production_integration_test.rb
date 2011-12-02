# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < ActionDispatch::IntegrationTest
  context 'MI production report' do

    setup do
      login
    end

    context '(detailed version)' do
      should 'have download link' do
        Factory.create :mi_plan
        Factory.create :mi_attempt
        Reports::MiProduction::Detail.generate_and_cache

        timestamp = '20110101120000'
        visit '/reports/mi_production'
        assert page.has_css? "a[href='/report_caches/mi_production_detail/#{timestamp}']"
      end
    end

  end
end
