# encoding: utf-8

require 'test_helper'

class PhenotypeAttempt::EditInFormTest < TarMits::JsIntegrationTest

  context 'When user is not logged in' do

    setup do
      ApplicationModel.uncached do
        mi = Factory.create(:mi_attempt2_status_gtc,
          :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI'))
        @phenotype_attempt = Factory.create :phenotype_attempt_status_pdc,
                :colony_background_strain => Strain.find_by_name!('C57BL/6N'),
                :mi_attempt => mi
      end
    end

    should 'user should not be able to edit Phenotpye Attempt' do
      visit phenotype_attempt_path(@phenotype_attempt)
      assert_login_page
    end
  end

  context 'When editing Phenotype Attempt in form' do

    setup do
      ApplicationModel.uncached do
        mi = Factory.create(:mi_attempt2_status_gtc,
          :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI'))
        @phenotype_attempt = Factory.create :phenotype_attempt_status_pdc,
                :colony_background_strain => Strain.find_by_name!('C57BL/6N'),
                :mi_attempt => mi
      end
      login
      click_link 'Phenotyping'
      within('.x-grid') { click_link 'View in Form' }
    end

    should 'show but not allow editing es_cell or gene' do
      assert_match /Auto-generated Symbol/, page.find('.marker-symbol').text
      assert_match /EPD_/, page.find('.es-cell-name').text
    end

    should 'show but not allow editing consortium or production centre' do
      assert_match /BaSH/, page.find('.consortium-name').text
      assert_match /WTSI/, page.find('.production-centre-name').text
      assert page.has_no_css?('select[name="phenotype_attempt[production_centre_name]"]')
      assert page.has_no_css?('select[name="phenotype_attempt[consortium_name]"]')
    end

    should 'show default values' do
      assert page.has_css? 'form.phenotype-attempt'

      assert_match /WTSI-EPD_/, page.find('input[name="phenotype_attempt[mi_attempt_colony_name]"]').value
      assert_equal "1", page.find('input[name="phenotype_attempt[rederivation_started]"]').value
      assert_equal "1", page.find('input[name="phenotype_attempt[rederivation_complete]"]').value

      assert_match "", page.find('select[name="phenotype_attempt[deleter_strain_name]"]').value
      assert_equal '1', page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value
      assert_equal '1', page.find('input[name="phenotype_attempt[cre_excision_required]"]').value
    end

    should 'edit phenotype successfully and redirect back to show page' do
      uncheck 'phenotype_attempt[rederivation_complete]'
      select 'MGI:3046308: Hprt', :from => 'phenotype_attempt[deleter_strain_name]'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '11'

      find_button('phenotype_attempt_submit').click
      assert page.has_no_css?('#phenotype_attempt_submit[disabled]')

      ApplicationModel.uncached { @phenotype_attempt.reload }
      visit current_path

      assert_equal "true", page.find('input[id="phenotype_attempt_rederivation_started"]')["checked"]
      assert_equal nil, page.find('input[id="phenotype_attempt_rederivation_complete"]')["checked"]
      assert_match "MGI:3046308: Hprt", page.find('select[name="phenotype_attempt[deleter_strain_name]"]').value
      assert_match "11", page.find('input[name="phenotype_attempt[number_of_cre_matings_successful]"]').value

      assert_match /\/phenotype_attempts\/#{@phenotype_attempt.id}$/, current_url
    end

    should 'prevent name change if phenotyping has started' do
      fill_in 'phenotype_attempt[colony_name]', :with => 'ABCD'
      uncheck 'phenotype_attempt[rederivation_complete]'
      select 'MGI:3046308: Hprt', :from => 'phenotype_attempt[deleter_strain_name]'
      fill_in 'phenotype_attempt[number_of_cre_matings_successful]', :with => '11'

      find_button('phenotype_attempt_submit').click
      assert page.has_no_css?('#phenotype_attempt_submit[disabled]')

      sleep 20

      assert_match /Phenotype attempt colony_name can not be changed once phenotyping has started/, page.find('.errorExplanation').text
    end

    should_eventually 'render deposited material errors' do
      click_link 'Add Distribution Centre'
    end

    should 'always show distribution centre if one exists' do
      pa = nil

      ApplicationModel.uncached do
        pa = Factory.create :phenotype_attempt_status_cec
        Factory.create :phenotype_attempt_distribution_centre, :phenotype_attempt => pa
      end

      visit phenotype_attempt_path pa

      assert page.has_css? 'table[id="distribution_centres_table"]'
    end

  end
end
