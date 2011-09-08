# encoding: utf-8

require 'test_helper'

class SearchForMiAttemptsTest < ActionDispatch::IntegrationTest

  should 'need a valid logged in user' do
    visit '/users/logout'

    visit '/'
    assert_match %r{/users/login$}, current_url

    visit '/mi_attempts'
    assert_match %r{/users/login$}, current_url
  end

  context 'As valid user:' do
    setup do
      visit '/users/logout'
      login
    end

    context 'searching for mi attempts by es_cell name' do

      setup do
        create_common_test_objects
      end

      context 'with a single es_cell' do
        setup do
          visit '/mi_attempts'
          fill_in 'q[terms]', :with => 'EPD0343_1_H06'
          click_button 'Search'
        end

        should 'show all data for that es_cell' do
          [
            'EPD0343_1_H06',
            'Myo1c',
            'Myo1ctm1a(EUCOMM)Wtsi',
            '13-09-2010',
            'MDCF',
            'WTSI',
            'Unsuitable for EMMA',
            'Micro-injection in progress',
          ].each do |text|
            assert(page.has_css?(selector_for_table_cell(1), :text => text),
              "Expected text '#{text}' in table cell 1, but did not find it")
          end
        end

        should 'show edit in form link' do
          mi = EsCell.find_by_name('EPD0343_1_H06').mi_attempts.first
          selector = selector_for_table_cell(1) + " a[href=\"/mi_attempts/#{mi.id}\"]"
          assert page.has_css?(selector)
        end

        should 'not show data for other es_cells' do
          assert page.has_no_css?('.x-grid3-col-es_cell__name', :text => 'EPD0127_4_E01')
        end
      end

      should 'work with a multiple es_cell names' do
        visit '/mi_attempts'
        fill_in 'search_terms', :with => "EPD0127_4_E01\nEPD0343_1_H06"
        click_button 'Search'

        assert page.has_css? '.x-grid3-cell-inner', :text => 'EPD0127_4_E01'
        assert page.has_css? '.x-grid3-cell-inner', :text => 'EPD0343_1_H06'
        assert page.has_no_css? '.x-grid3-cell-inner', :text => 'EPD0029_1_G04'
      end

      should 'work if whitespace around es_cell names' do
        visit '/'
        fill_in 'search_terms', :with => "  EPD0343_1_H06\t"
        click_button 'Search'

        assert page.has_css? selector_for_table_cell(1), :text => 'EPD0343_1_H06'
      end

      should 'show emma statuses' do
        visit '/mi_attempts?search_terms=EPD0127_4_E01'

        assert page.has_css? '.x-grid3-cell-inner', :text => 'Suitable for EMMA'
        assert page.has_css? '.x-grid3-cell-inner', :text => 'Unsuitable for EMMA'
      end

      should 'show search terms when results are shown' do
        visit '/mi_attempts?search_terms=EPD0127_4_E01%0D%0AEPD0343_1_H06'
        assert page.has_css? '#search-terms', :text => "EPD0127_4_E01 EPD0343_1_H06"
      end
    end

    context 'searching for mi attempts by marker symbol' do
      setup do
        create_common_test_objects
        visit '/mi_attempts'
        assert_false page.has_css? 'x-grid3'
        fill_in 'search_terms', :with => 'Trafd1'
        click_button 'Search'
      end

      should 'work' do
        assert_match /search_terms=Trafd1/, current_url
        assert page.has_css? selector_for_table_cell(1), :text => 'EPD0127_4_E01'
      end

      should 'not find unmatched es_cells' do
        assert page.has_no_css?('.x-grid3-cell-inner', :text => 'EPD0343_1_H06')
      end
    end

    context 'searching by a term and filtering by production centre' do
      setup do
        @es_cell1 = Factory.create :es_cell_EPD0343_1_H06
        @es_cell2 = Factory.create :es_cell_EPD0127_4_E01
        @es_cell3 = Factory.create :es_cell_EPD0029_1_G04

        @mi_attempt = Factory.create(:mi_attempt, :es_cell => @es_cell1,
          :production_centre => Centre.find_by_name!('ICS'))

        visit '/'
        fill_in 'search_terms', :with => "myo1c\n"
        select 'ICS', :from => 'production_centre_id'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css? '.x-grid3-col-es_cell__name', :text => @mi_attempt.es_cell.name
      end

      should 'not show things that only match one of the terms but not the other' do
        assert_equal 2, @es_cell1.mi_attempts.size
        assert_equal 1, all('.x-grid3-col-es_cell__name').size
        assert page.has_no_css? '.x-grid3-col-production_centre__name', :text => 'WTSI'
      end

      should 'have filtered production centre pre-selected in dropdown' do
        assert page.has_css? '#production_centre_id option[selected="selected"][value="' + Centre.find_by_name('ICS').id.to_s + '"]'
      end
    end

    context 'searching by a term and filtering by status' do
      setup do
        @es_cell1 = Factory.create :es_cell_EPD0343_1_H06
        @es_cell2 = Factory.create :es_cell_EPD0127_4_E01
        @es_cell3 = Factory.create :es_cell_EPD0029_1_G04

        @status = MiAttemptStatus.create!(:description => 'Nonsense')

        @mi_attempt = Factory.create(:mi_attempt, :es_cell => @es_cell2,
          :mi_attempt_status => @status)

        mi_attempt_to_not_be_found = Factory.create(:mi_attempt, :es_cell => @es_cell1,
          :mi_attempt_status => @status)

        sleep 3
        visit '/'
        fill_in 'search_terms', :with => "trafd1\n"
        select 'Nonsense', :from => 'mi_attempt_status_id'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css? '.x-grid3-col-es_cell__name', :text => @mi_attempt.es_cell.name
        assert page.has_css? '.x-grid3-col-mi_attempt_status__description', :text => 'Nonsense'
      end

      should 'not show any non-matching mi attempts' do
        assert_equal 1, all('.x-grid3-col-es_cell__name').size
      end

      should 'have filtered status pre-selected in dropdown' do
        assert page.has_css? "#mi_attempt_status_id option[selected='selected'][value='#{@status.id}']"
      end
    end

    should 'work for search with no terms' do
      visit '/'
      click_button 'Search'
      assert page.has_no_css? 'error'
    end

    should 'display test data warning' do
      visit '/'
      assert page.has_content? 'DO NOT ENTER ANY PRODUCTION DATA'
    end

  end

end
