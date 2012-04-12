# encoding: utf-8

require 'test_helper'

class Reports::Production::MgpIntegrationTest < Kermits2::IntegrationTest

  context 'report' do

    setup do
      Factory.create :mi_plan
      Reports::MiProduction::Intermediate.new.cache
      login
    end

    context '/reports/production/mgp/summary_subproject' do
      should 'work' do
        visit '/reports/production/mgp'
        assert page.has_css? "a[href='/reports/production/mgp/summary_subproject']"
        visit '/reports/production/mgp/summary_subproject'
	assert page.has_css? "#content"
      end

      should 'have link to cached report' do
        visit '/reports/production/mgp/summary_subproject'
        assert page.has_css? "a[href='/reports/production/mgp/summary_subproject.csv']"
      end
    end

=begin
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
=end

  end
end
