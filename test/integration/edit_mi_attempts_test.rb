# encoding: utf-8

require 'test_helper'

class EditMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'Edit MI Attempt' do

    context 'Distribution Centre' do
      should 'get list of distribution centres from all centres in the DB' do
        visit '/emi_attempts?clone_names=EPD0343_1_H06'

        assert_equal 'WTSI', find('.x-grid3-body .x-grid3-row:nth-child(1) .x-grid3-col-distribution_centre_name.x-grid3-cell-inner').text
        flunk 'Selenium/Capybara do not support double click testing'
      end

      should 'work' do
        flunk 'Selenium/Capybara do not support double click testing'
      end
    end
  end

end
