require 'test_helper'

class PhenotypeAttempt::ViewIntegrationTest < TarMits::JsIntegrationTest
  context 'View PhenotypeAttempt in grid tests:' do

    should 'display PhenotypeAttempt data' do
      mi = Factory.create :mi_attempt2_status_gtc, :mi_plan => TestDummy.mi_plan('MGP', 'ICS')
      pa = Factory.create :phenotype_attempt_status_cec,
              :deleter_strain => DeleterStrain.find_by_name!('MGI:3046308: Hprt'),
              :number_of_cre_matings_successful => 12,
              :mi_attempt => mi
      user = Factory.create :user, :production_centre => pa.mi_plan.production_centre
      login user
      visit '/phenotype_attempts'

      wait_until_grid_loaded

      [
        'MGP',
        'ICS',
        '12',
        'MGI:3046308: Hprt'
      ].each do |text|
        assert(page.has_css?('div', :text => text),
          "Expected text '#{text}' in grid, but did not find it")
      end
    end

  end
end
