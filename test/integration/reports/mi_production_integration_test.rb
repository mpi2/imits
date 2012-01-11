# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < ActionDispatch::IntegrationTest
  context 'MI production reports:' do

    setup do
      login
    end

    context 'detailed MI production report' do
      should 'have link to cached report' do
        visit '/reports'
        click_link 'Detailed Report'
        assert page.has_css? "a[href='/reports/mi_production/detail.csv']"
      end

    end

    context 'summaries page' do
      should 'work' do
        visit '/reports/mi_production/'
        assert page.has_css? 'h2', :text => 'MI Production Reports'
        assert page.has_css? 'a'
      end
    end

  end
end
