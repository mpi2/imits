# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < ActionDispatch::IntegrationTest

  context 'MI production reports:' do

    setup do
      create_common_test_objects
      Reports::MiProduction::Intermediate.new.cache
      visit '/users/logout'
      login
    end

    context 'detailed MI production report' do
      should 'have link to cached report' do
        visit '/reports/mi_production/detail'
        assert page.has_css? "a[href='/reports/mi_production/detail.csv']"
      end
    end

    context '/reports/mi_production/mgp_summary_subproject' do
      should 'have link to cached report' do
        visit '/reports/mi_production/mgp_summary_subproject'
	assert page.has_css? "#content"
        assert page.has_css? "a[href='/reports/mi_production/mgp_summary_subproject.csv']"
      end
    end

  end
end
