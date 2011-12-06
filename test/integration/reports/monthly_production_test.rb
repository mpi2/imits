# encoding: utf-8

require 'test_helper'

class Reports::MonthlyProductionTest < ActionDispatch::IntegrationTest

  context 'reports/mi_attempts_monthly_production' do

    context 'once logged in' do
      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the correct page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1

        Factory.create :wtsi_mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
          :consortium_name => 'MGP',
          :is_active => true,
          :is_suitable_for_emma => true,
          :total_pups_born => 10,
          :total_male_chimeras => 10

        visit '/reports/mi_attempts_monthly_production'
        assert_match '/reports/mi_attempts_monthly_production', current_url

        click_button 'Generate Report'

        assert page.has_content? "Consortium Production Centre Month Injected # Clones Injected # at Birth % at Birth # at Weaning # Genotype Confirmed % Genotype Confirmed"
        
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(1)', :text => 'Consortium')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(2)', :text => 'Production Centre')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(3)', :text => 'Month Injected')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(4)', :text => '# Clones Injected')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(5)', :text => '# at Birth')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(6)', :text => '% at Birth')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(7)', :text => '# at Weaning')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(8)', :text => '# Genotype Confirmed')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(9)', :text => '% Genotype Confirmed')
        
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(1)', :text => 'MGP')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(2)', :text => 'WTSI')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(4)', :text => '1')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(5)', :text => '1')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(6)', :text => '100')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(7)', :text => '1')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(8)', :text => '1')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(9)', :text => '100')

      end

    end

  end
end
