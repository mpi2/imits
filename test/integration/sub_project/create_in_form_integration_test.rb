# encoding: utf-8

require 'test_helper'

class MiPlan::SubProject::CreateInFormIntegrationTest < Kermits2::IntegrationTest
  context 'When creating sub project in form' do

    should 'save sub project and redirect back to index page with notice message' do
      login
      visit '/sub_projects'
      fill_in :name, :with => 'INTEGRATIONTEST'
      click_button 'mi_plan_sub_project_submit'
      assert page.has_css?('.message.notice')
      assert_equal "Sub-project 'INTEGRATIONTEST' created", page.find('.message.notice').text
      page.has_css?('table td.INTEGRATIONTEST')
    end

    should 'not save sub project but should redirect back to index page with alert message' do
      login
      visit '/sub_projects'
      fill_in :name, :with => 'INTEGRATIONTEST'
      click_button 'mi_plan_sub_project_submit'
      fill_in :name, :with => 'INTEGRATIONTEST'
      click_button 'mi_plan_sub_project_submit'
      assert page.has_css?('.message.alert')
      assert_equal "Sub-project 'INTEGRATIONTEST' already exists", page.find('.message.alert').text
    end

    should 'delete sub-project and redirect back to index page with notice message' do
      login
      visit '/sub_projects'
      fill_in :name, :with => 'INTEGRATIONTEST'
      click_button 'mi_plan_sub_project_submit'
      click_button "INTEGRATIONTEST_button"
      assert page.has_css?('.message.notice')
      assert_equal "Successfully deleted sub-project 'INTEGRATIONTEST'", page.find('.message.notice').text
      !page.has_css?('table td.INTEGRATIONTEST')
    end

    should 'fail to delete sub-project with mi_plan but should redirect back to index page with alert message' do
      login
      visit '/sub_projects'
      fill_in :name, :with => 'INTEGRATIONTEST'
      click_button 'mi_plan_sub_project_submit'
      mi_plan = Factory.build :mi_plan
      mi_plan.sub_project_id = MiPlan::SubProject.find_by_name('INTEGRATIONTEST').id
      mi_plan.save
      visit '/sub_projects'
      assert !page.has_button?('INTEGRATIONTEST_button')
    end
  end
end
