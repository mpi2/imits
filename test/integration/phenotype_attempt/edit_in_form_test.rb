# encoding: utf-8

require 'test_helper'

class EditInFormTest < Kermits2::JsIntegrationTest
  context 'When editing Phenotype Attempt in form' do

    setup do
      create_common_test_objects
      @phenotype_attempt = Factory.create :populated_phenotype_attempt
      login
      visit phenotype_attempt_path(@phenotype_attempt)
    end

    should 'show but not allow editing es_cell or gene' do
      assert_match /Auto-generated Symbol/, page.find('.marker-symbol').text
      assert_match /Auto-generated ES Cell Name/, page.find('.es-cell-name').text
    end

    should 'show default values' do
      sleep 1
      
      assert_match /ICS-Auto-generated ES Cell Name/, page.find('input[name="phenotype_attempt[mi_attempt_colony_name]"]').value
      assert_equal "1", page.find('input[id="phenotype_attempt_rederivation_started"]').value
      assert_equal "1", page.find('input[id="phenotype_attempt_rederivation_complete"]').value
      assert_match /^\d\d/, page.find('input[name="phenotype_attempt[number_of_cre_matings_started]"]').value
      assert_match /^\d\d/, page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value
      assert_equal "1", page.find('input[id="phenotype_attempt_phenotyping_started"]').value
      assert_equal "1", page.find('input[id="phenotype_attempt_phenotyping_complete"]').value
    end
    
    should 'edit phenotype successfully, set updated_by and redirect back to show page' do
      fill_in 'phenotype_attempt[colony_name]', :with => 'ABCD'
      uncheck 'phenotype_attempt[rederivation_started]'
    end
    
  end
end
