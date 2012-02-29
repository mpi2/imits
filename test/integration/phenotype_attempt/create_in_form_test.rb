# encoding: utf-8

require 'test_helper'

class CreateInFormTest < Kermits2::JsIntegrationTest
  context 'When creating Phenotype Attempt in form' do

    setup do
      @mi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed,
              :colony_name => 'MABC',
              :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      login
      click_link "Search & Edit MI Attempts"
      click_link "Create"
    end

    should 'save Phenotype attempt and redirect back to show page when valid data' do

      fill_in 'phenotype_attempt[colony_name]', :with => 'TEST'
      select 'DTCC', :from => 'phenotype_attempt[consortium_name]'
      select 'UCD', :from => 'phenotype_attempt[production_centre_name]'
      check('phenotype_attempt[rederivation_started]')
      fill_in 'phenotype_attempt[number_of_cre_matings_started]', :with => '99'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '9'
      click_button 'phenotype_attempt_submit'

      assert page.has_css?('.message.notice')
      assert_equal 'Phenotype attempt created', page.find('.message.notice').text
      assert_match /\/phenotype_attempts\/\d+$/, current_url

      sleep 5

      assert_equal 1, PhenotypeAttempt.count
      pt = PhenotypeAttempt.first
      assert_equal 'DTCC', pt.consortium.name
      assert_equal 'UCD', pt.production_centre.name
      assert_equal @mi_attempt.colony_name, pt.mi_attempt.colony_name
    end

  end
end
