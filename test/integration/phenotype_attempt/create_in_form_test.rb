# encoding: utf-8

require 'test_helper'

class CreateInFormTest < Kermits2::JsIntegrationTest
  context 'When creating Phenotype Attempt in form' do

    setup do
      @mi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :colony_name => 'MABC'
                
      login
      click_link "Search & Edit MI Attempts"
      
      click_link "Create"

    end
    
    should 'allow editing consortium or production centre' do
      assert page.has_css?('select[name="phenotype_attempt[production_centre_name]"]')
      assert page.has_css?('select[name="phenotype_attempt[consortium_name]"]')
    end

    should 'save Phenotype attempt and redirect back to show page when valid data' do

      fill_in 'phenotype_attempt_colony_name', :with => 'TEST'
      select 'EUCOMM-EUMODIC', :from => 'phenotype_attempt[consortium_name]'
      assert page.has_no_css?('phenotype_attempt[production_centre_name]')
      check('phenotype_attempt[rederivation_started]')
      fill_in 'phenotype_attempt[number_of_cre_matings_started]', :with => '99'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '9'
      click_button 'phenotype_attempt_submit'

      sleep 3

      assert_match /\/phenotype_attempts\/\d+$/, current_url
      assert_equal 'Phenotype attempt created', page.find('.message.notice').text
    end

  end
end
