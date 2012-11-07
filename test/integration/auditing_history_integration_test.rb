# encoding: utf-8

require 'test_helper'

class AuditingHistoryIntegrationTest < Kermits2::IntegrationTest
  context 'MI attempts history page' do
    should 'work' do
      login
      mi_attempt = Factory.create :mi_attempt
      visit mi_attempt_path(mi_attempt) + '/history'
      assert_match /History of Changes/, page.find('h2').text
      assert page.has_css? 'div.report table'
    end
  end

  context 'Plan history page' do
    should 'work' do
      login
      mi_plan = Factory.create :mi_plan
      visit mi_plan_path(mi_plan) + '/history'
      assert_match /History of Changes/, page.find('h2').text
      assert page.has_css? 'div.report table'
    end
  end

  context 'Phenotype attempt history page' do
    should 'work' do
      login
      phenotype_attempt = Factory.create :phenotype_attempt
      visit phenotype_attempt_path(phenotype_attempt) + '/history'
      assert_match /History of Changes/, page.find('h2').text
      assert page.has_css? 'div.report table'
    end
  end
end
