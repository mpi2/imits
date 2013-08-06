# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::CreateInFormIntegrationTest < TarMits::JsIntegrationTest
  context 'When user is not logged in grid' do
    should 'not display create phenotype attempt column' do
      visit '/'
      click_link "Mouse Production"
      within('.x-grid') {assert has_no_content?('Create')}
    end
  end

  context 'When creating Phenotype Attempt in form' do

    setup do
      ApplicationModel.uncached do
        @mi_attempt = Factory.create :mi_attempt2_status_gtc,
                :colony_name => 'MABC',
                :es_cell => Factory.create(:es_cell, :allele => Factory.create(:allele, :gene => cbx1)),
                :mi_plan => bash_wtsi_cbx1_plan
      end

      login

      click_link "Mouse Production"
      wait_until_grid_loaded
      within('.x-grid') { click_link "Create" }
    end

    should 'save Phenotype attempt and redirect back to show page when valid data' do
      ApplicationModel.uncached { TestDummy.mi_plan('DTCC', 'UCD', @mi_attempt.gene.marker_symbol) }

      fill_in 'phenotype_attempt_colony_name', :with => 'TEST'

      check('phenotype_attempt[rederivation_started]')
      select 'MGI:3046308: Hprt', :from => 'phenotype_attempt[deleter_strain_name]'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '9'
      select 'b', :from => 'phenotype_attempt[mouse_allele_type]'
      select 'C57BL/6N', :from => 'phenotype_attempt[colony_background_strain_name]'
      click_button 'phenotype_attempt_submit'

      assert page.has_css?('.message.notice')
      assert_equal 'Phenotype attempt created', page.find('.message.notice').text
      assert_match(/\/phenotype_attempts\/\d+$/, current_url)

      ApplicationModel.uncached do
        assert_equal 1, PhenotypeAttempt.count
        pt = Public::PhenotypeAttempt.first
        assert_equal 'BaSH', pt.consortium_name
        assert_equal 'WTSI', pt.production_centre_name
        assert_equal DeleterStrain.first, pt.deleter_strain
        assert_equal 9, pt.number_of_cre_matings_successful
        assert_equal 'b', pt.mouse_allele_type
        assert_equal @mi_attempt.colony_name, pt.mi_attempt.colony_name
      end
    end

    should 'be creatable with minimal values' do
      ApplicationModel.uncached { assert_equal 0, PhenotypeAttempt.count }
      click_button 'phenotype_attempt_submit'
      assert page.has_css?('.message.notice')
      assert_equal 'Phenotype attempt created', page.find('.message.notice').text
      ApplicationModel.uncached { assert_equal 1, PhenotypeAttempt.count }
    end

  end
end
