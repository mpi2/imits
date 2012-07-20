# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::CreateInFormTest < Kermits2::JsIntegrationTest
  context 'When creating Phenotype Attempt in form' do

    setup do
      @mi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed,
              :colony_name => 'MABC',
              :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI'
      login

      click_link "Mouse Production"
      within('.x-grid') { click_link "Create" }
    end

    should 'allow editing consortium or production centre' do
      sleep 2
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
      assert_match /\/phenotype_attempts\/\d+$/, current_url

      sleep 2

      assert_equal 1, PhenotypeAttempt.count
      phenotype_attempt = PhenotypeAttempt.find_by_colony_name!('TEST')
      assert_equal 'BaSH', phenotype_attempt.consortium.name
      assert_equal 'WTSI', phenotype_attempt.production_centre.name
      assert_equal 'MGI:3046308: Hprt', phenotype_attempt.deleter_strain.name
      assert_equal 9, phenotype_attempt.number_of_cre_matings_successful
      assert_equal 'b', phenotype_attempt.mouse_allele_type
      assert_equal @mi_attempt.colony_name, phenotype_attempt.mi_attempt.colony_name

      assert_equal phenotype_attempt.colony_name, page.find('input[name="phenotype_attempt[colony_name]"]').value
      assert page.has_content? phenotype_attempt.consortium.name
      assert page.has_content? phenotype_attempt.production_centre.name

      assert_equal phenotype_attempt.deleter_strain.name, page.find('select[name="phenotype_attempt[deleter_strain_name]"]').value
      assert_equal phenotype_attempt.number_of_cre_matings_successful.to_s, page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value
      assert_equal phenotype_attempt.mouse_allele_type, page.find('select[name="phenotype_attempt[mouse_allele_type]"]').value
    end

    should 'not save Phenotype attempt and redirect back to show page with notice when no valid plan available' do
      TestDummy.mi_plan('DTCC', 'UCD', @mi_attempt.gene.marker_symbol)

      fill_in 'phenotype_attempt_colony_name', :with => 'TEST'

      check('phenotype_attempt[rederivation_started]')
      select 'MGI:3046308: Hprt', :from => 'phenotype_attempt[deleter_strain_name]'
      select 'BaSH', :from => 'phenotype_attempt[consortium_name]'
      select 'DTCC', :from => 'phenotype_attempt[production_centre_name]'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '9'
      select 'b', :from => 'phenotype_attempt[mouse_allele_type]'
      click_button 'phenotype_attempt_submit'

      assert page.has_css?('.message.alert')
      assert_equal 'Plan cannot be found with supplied parameters. Please either create it first or check consortium_name and/or production_centre_name supplied', page.find('.message.alert').text
      assert_match /\/phenotype_attempts/, current_url

      sleep 2

      assert_equal 0, PhenotypeAttempt.count

      assert_equal 'TEST', page.find('input[name="phenotype_attempt[colony_name]"]').value
      assert_equal 'BaSH', page.find('select[name="phenotype_attempt[consortium_name]"]').value
      assert_equal 'DTCC', page.find('select[name="phenotype_attempt[production_centre_name]"]').value

      assert_equal 'MGI:3046308: Hprt', page.find('select[name="phenotype_attempt[deleter_strain_name]"]').value
      assert_equal '9', page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value
      assert_equal 'b', page.find('select[name="phenotype_attempt[mouse_allele_type]"]').value
    end

    should 'be creatable with minimal values' do
      assert_equal 0, PhenotypeAttempt.count
      click_button 'phenotype_attempt_submit'
      assert page.has_css?('.message.notice')
      assert_equal 'Phenotype attempt created', page.find('.message.notice').text

      sleep 2
      assert_equal 1, PhenotypeAttempt.count
    end

  end
end
