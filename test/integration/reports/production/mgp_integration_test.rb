# encoding: utf-8

require 'test_helper'

class Reports::Production::MgpIntegrationTest < TarMits::IntegrationTest

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

    context '/reports/production/mgp/summary_priority' do
      should 'work' do
        visit '/reports/production/mgp'
        assert page.has_css? "a[href='/reports/production/mgp/summary_priority']"
        visit '/reports/production/mgp/summary_priority'
	assert page.has_css? "#content"
      end

      should 'have link to cached report' do
        visit '/reports/production/mgp/summary_priority'
        assert page.has_css? "a[href='/reports/production/mgp/summary_priority.csv']"
      end
    end

    context '/reports/production/mgp/languishing_sub_project' do
      should 'work' do
        visit '/reports/production/mgp'
        assert page.has_css? "a[href='/reports/production/mgp/languishing_sub_project']"
        visit '/reports/production/mgp/languishing_sub_project'
	assert page.has_css? "#content"
      end

      should 'have link to cached report' do
        visit '/reports/production/mgp/languishing_sub_project'
        assert page.has_css? "a[href='/reports/production/mgp/languishing_sub_project.csv']"
      end
    end

    context '/reports/production/mgp/languishing_priority' do
      should 'work' do
        visit '/reports/production/mgp'
        assert page.has_css? "a[href='/reports/production/mgp/languishing_priority']"
        visit '/reports/production/mgp/languishing_priority'
	assert page.has_css? "#content"
      end

      should 'have link to cached report' do
        visit '/reports/production/mgp/languishing_priority'
        assert page.has_css? "a[href='/reports/production/mgp/languishing_priority.csv']"
      end
    end

  end
end
