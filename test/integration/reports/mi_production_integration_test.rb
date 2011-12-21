# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < ActionDispatch::IntegrationTest
  context 'MI production report' do

    setup do
      login
    end

    context '(detailed version)' do
      should 'have link to cached report' do
        visit '/reports'
        click_link 'Detailed Report'
        assert page.has_css? "a[href='/reports/mi_production_detail.csv']"
      end

    end

  end
end
