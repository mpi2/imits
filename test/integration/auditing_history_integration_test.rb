# encoding: utf-8

require 'test_helper'

class AuditingHistoryIntegrationTest < TarMits::IntegrationTest
  context 'Audit history page for' do

    setup do
      login
    end

    context 'MI attempts' do
      should 'work' do
        mi_attempt = Factory.create :mi_attempt2
        visit mi_attempt_path(mi_attempt)
        click_link 'History'
        assert_equal "Micro-injection attempt #{mi_attempt.id} History", page.find('h2').text
        click_link 'Back'
        assert_equal 'Edit Micro-injection Attempt', page.find('h2').text
      end
    end

    context 'Plan' do
      should 'work' do
        plan = Factory.create :mi_plan
        visit mi_plan_path(plan)
        click_link 'History'
        assert_equal "Plan #{plan.id} History", page.find('h2').text
        click_link 'Back'
        assert_equal 'Edit Plan', page.find('h2').text
      end
    end

    context 'Phenotype attempt' do
      should 'work' do
        phenotype_attempt = Factory.create :phenotype_attempt
        visit phenotype_attempt_path(phenotype_attempt)
        click_link 'History'
        assert_equal "Phenotype attempt #{phenotype_attempt.id} History", page.find('h2').text
        click_link 'Back'
        assert_equal 'Edit Phenotype Attempt', page.find('h2').text
      end
    end

  end
end
