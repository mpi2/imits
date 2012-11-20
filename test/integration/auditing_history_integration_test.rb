# encoding: utf-8

require 'test_helper'

class AuditingHistoryIntegrationTest < Kermits2::IntegrationTest
  context 'Audit history page for' do

    setup do
      login
    end

    context 'MI attempts' do
      should 'work' do
        mi_attempt = Factory.create :mi_attempt, :id => 23
        visit mi_attempt_path(mi_attempt)
        click_link 'History'
        assert_equal 'Micro-injection attempt 23 History', page.find('h2').text
        click_link 'Back'
        assert_equal 'Edit Micro-injection Attempt', page.find('h2').text
      end
    end

    context 'Plan' do
      should 'work' do
        plan = Factory.create :mi_plan, :id => 346
        visit mi_plan_path(plan)
        click_link 'History'
        assert_equal 'Plan 346 History', page.find('h2').text
        click_link 'Back'
        assert_equal 'Edit Plan', page.find('h2').text
      end
    end

    context 'Phenotype attempt' do
      should 'work' do
        phenotype_attempt = Factory.create :phenotype_attempt, :id => 234
        visit phenotype_attempt_path(phenotype_attempt)
        click_link 'History'
        assert_equal 'Phenotype attempt 234 History', page.find('h2').text
        click_link 'Back'
        assert_equal 'Edit Phenotype Attempt', page.find('h2').text
      end
    end

  end
end
