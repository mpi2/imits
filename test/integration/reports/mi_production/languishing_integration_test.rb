# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::LanguishingIntegrationTest < TarMits::IntegrationTest
  context '/reports/mi_production/languishing' do

    setup do
      login default_user
    end

    should 'work' do
      Factory.create :mi_attempt2
      Reports::MiProduction::Intermediate.new.cache
      visit '/reports/mi_production/languishing'
      assert page.has_css? '#content'
    end

    should 'have csv link' do
      Factory.create :phenotype_attempt
      Reports::MiProduction::Intermediate.new.cache
      visit '/reports/mi_production/languishing'
      click_link 'Download as CSV'
      assert page.has_content? '0 months,1 month,2 months'
    end

    context '_detail' do
      should 'work' do
        Factory.create :mi_attempt2
        Reports::MiProduction::Intermediate.new.cache
        visit '/reports/mi_production/languishing'
        click_link '1'
        visit '/reports/mi_production/languishing_detail'
        assert page.has_css? '#content'
      end

      should 'have csv link' do
        Factory.create :phenotype_attempt
        Reports::MiProduction::Intermediate.new.cache
        visit '/reports/mi_production/languishing'
        click_link '1'
        visit '/reports/mi_production/languishing_detail'
        click_link 'Download as CSV'
        assert page.has_content? 'Consortium,Sub-Project,Is Bespoke Allele,Priority'
      end
    end

    should 'show Micro-injection in progress as "Mouse production attempt"' do
      Factory.create :mi_attempt2
      Reports::MiProduction::Intermediate.new.cache
      visit '/reports/mi_production/languishing'
      assert page.has_no_content? 'Micro-injection in progress'
      assert page.has_content? 'Mouse production attempt'
    end

    should 'have working detail link for Mouse production attempt / Micro-injection in progress' do
      Factory.create :mi_attempt2
      Reports::MiProduction::Intermediate.new.cache
      visit '/reports/mi_production/languishing'
      link = page.find('.report td a')
      assert_match /^\/reports\/mi_production\/languishing_detail/, link['href']
      click_link '1'
      sleep 2
      assert page.has_css? '#content'
      assert page.has_xpath? '//tr/td[contains(text(), "Micro-injection in progress")]'
    end

    should 'show Phenotype Attempt Registered as "Intent to phenotype"' do
      Factory.create :phenotype_attempt
      Reports::MiProduction::Intermediate.new.cache
      visit '/reports/mi_production/languishing'
      assert page.has_no_content? 'Phenotype Attempt Registered'
      assert page.has_content? 'Intent to phenotype'
    end

    should 'have working detail link for Intent to phenotype / Phenotype Attempt Registered' do
      Factory.create :phenotype_attempt
      Reports::MiProduction::Intermediate.new.cache
      visit '/reports/mi_production/languishing'
      link = page.find('.report td a')
      assert_match /^\/reports\/mi_production\/languishing_detail/, link['href']
      click_link '1'
      sleep 2
      assert page.has_css? '#content'
      assert page.has_xpath? '//tr/td[contains(text(), "Phenotype Attempt Registered")]'
    end

  end
end
