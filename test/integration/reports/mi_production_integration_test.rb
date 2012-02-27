# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < Kermits2::IntegrationTest

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

    context '/reports/mi_production/mgp_summary_priority' do
      should 'have link to cached report' do
        visit '/reports/mi_production/mgp_summary_priority'
	assert page.has_css? "#content"
        assert page.has_css? "a[href='/reports/mi_production/mgp_summary_priority.csv']"
      end
    end

    context '/reports/mi_production/languishing_mgp_sub_project' do
      should 'have link to cached report' do
        visit '/reports/mi_production/languishing_mgp_sub_project'
	assert page.has_css? "#content"
        assert page.has_css? "a[href='/reports/mi_production/languishing_mgp_sub_project.csv']"
      end
    end

    context '/reports/mi_production/languishing_mgp_priority' do
      should 'have link to cached report' do
        visit '/reports/mi_production/languishing_mgp_priority'
	assert page.has_css? "#content"
        assert page.has_css? "a[href='/reports/mi_production/languishing_mgp_priority.csv']"
      end
    end
  end
end
