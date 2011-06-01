# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'Create MI Attempt' do

    should 'require login' do
      visit '/'
      assert page.has_no_css? '#mainnav a:contains("Create")'
    end

    context 'when entering data' do
      setup do
        login
        click_link 'Create'
      end

      should 'select a distribution centre' do
        select 'WTSI', :from => 'mi_attempt_distribution_centre'
        click_button 'mi_attempt_submit'
        assert page.has_css? 'WTSI'
      end

      should 'select a production centre'

      should 'select user\'s production centre as the default'

      should 'enter numeric fields'

      should 'enter colony name'

      should 'enter emma status'

      should 'enter mi date and date_chimeras_mated'

      should 'enter QC booleans'

      should 'enter QC fields'
    end

  end
end
