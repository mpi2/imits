require 'test_helper'

class PhenotypeAttempt::ViewIntegrationTest < Kermits2::JsIntegrationTest
  context 'View PhenotypeAttempt in grid tests:' do

    should 'display PhenotypeAttempt data' do
      pa = Factory.create :phenotype_attempt, :number_of_cre_matings_started => 34, :number_of_cre_matings_successful => 12
      pa.save!
      user = Factory.create :user, :production_centre => pa.mi_plan.production_centre
      login user
      visit '/phenotype_attempts'
      sleep 2.5
      [
        'EUCOMM-EUMODIC',
        'ICS',
        '12',
        '34'
      ].each do |text|
        assert(page.has_css?('div', :text => text),
          "Expected text '#{text}' in grid, but did not find it")
      end
    end

  end
end
