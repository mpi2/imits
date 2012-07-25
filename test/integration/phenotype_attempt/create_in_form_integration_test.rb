# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::CreateInFormIntegrationTest < Kermits2::JsIntegrationTest
  context 'When creating Phenotype Attempt in form' do

    setup do
      @mi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed,
              :colony_name => 'MABC',
              :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      login

      click_link "Mouse Production"
      wait_until_grid_loaded
      within('.x-grid') { click_link "Create" }
    end

    should 'allow editing consortium or production centre' do
      assert page.has_css?('select[name="phenotype_attempt[production_centre_name]"]')
      assert page.has_css?('select[name="phenotype_attempt[consortium_name]"]')
    end

    should 'save Phenotype attempt and redirect back to show page when valid data' do
      TestDummy.mi_plan('DTCC', 'UCD', @mi_attempt.gene.marker_symbol)

      fill_in 'phenotype_attempt_colony_name', :with => 'TEST'

      check('phenotype_attempt[rederivation_started]')
      select 'MGI:3046308: Hprt', :from => 'phenotype_attempt[deleter_strain_name]'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '9'
      select 'b', :from => 'phenotype_attempt[mouse_allele_type]'
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
      assert_equal 0, PhenotypeAttempt.count
      click_button 'phenotype_attempt_submit'
      assert page.has_css?('.message.notice')
      assert_equal 'Phenotype attempt created', page.find('.message.notice').text
      ApplicationModel.uncached { assert_equal 1, PhenotypeAttempt.count }
    end

  end
end
