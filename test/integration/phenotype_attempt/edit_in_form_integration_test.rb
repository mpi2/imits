# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::EditInFormTest < Kermits2::JsIntegrationTest
  context 'When editing Phenotype Attempt in form' do

    setup do
      @phenotype_attempt = Factory.create :populated_phenotype_attempt
      login
      click_link 'Phenotyping'
      within('.x-grid') { click_link 'Edit in Form' }
    end

    should 'show but not allow editing es_cell or gene' do
      assert_match /Auto-generated Symbol/, page.find('.marker-symbol').text
      assert_match /Auto-generated ES Cell Name/, page.find('.es-cell-name').text
    end

    should 'show but not allow editing consortium or production centre' do
      assert_match /EUCOMM-EUMODIC/, page.find('.consortium-name').text
      assert_match /ICS/, page.find('.production-centre-name').text
      assert page.has_no_css?('select[name="phenotype_attempt[production_centre_name]"]')
      assert page.has_no_css?('select[name="phenotype_attempt[consortium_name]"]')
    end


    should 'show default values' do
      assert page.has_css? 'form.phenotype-attempt'

      assert_match /ICS-Auto-generated ES Cell Name/, page.find('input[name="phenotype_attempt[mi_attempt_colony_name]"]').value
      assert_equal "1", page.find('input[id="phenotype_attempt_rederivation_started"]').value
      assert_equal "1", page.find('input[id="phenotype_attempt_rederivation_complete"]').value
      assert_match "", page.find('select[name="phenotype_attempt[deleter_strain_name]"]').value
      assert_match /^\d\d/, page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value
    end

    should 'edit phenotype successfully and redirect back to show page' do
      fill_in 'phenotype_attempt[colony_name]', :with => 'ABCD'
      uncheck 'phenotype_attempt[rederivation_complete]'
      select 'MGI:3046308: Hprt', :from => 'phenotype_attempt[deleter_strain_name]'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '11'

      find_button('Update').click
      sleep 3

      @phenotype_attempt.reload
      visit current_path

      assert_equal "ABCD", page.find('input[name="phenotype_attempt[colony_name]"]').value
      assert_equal "true", page.find('input[id="phenotype_attempt_rederivation_started"]')["checked"]
      assert_equal nil, page.find('input[id="phenotype_attempt_rederivation_complete"]')["checked"]
      assert_match "MGI:3046308: Hprt", page.find('select[name="phenotype_attempt[deleter_strain_name]"]').value
      assert_match "11", page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value

      assert_match /\/phenotype_attempts\/#{@phenotype_attempt.id}$/, current_url
    end

  end
end
