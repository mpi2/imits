# encoding: utf-8

require 'test_helper'

class SearchForMiAttemptsTest < Kermits2::JsIntegrationTest

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
          sleep 1
          click_button 'Search'
          sleep 1
        end

        should 'show all data for that MI attempt' do
          mi_attempt = EsCell.find_by_name!('EPD0343_1_H06').mi_attempts.first
          mi_attempt.mouse_allele_type = 'b'
          mi_attempt.save!
          sleep 3
          click_button 'Search'
          sleep 1
          [
            'EPD0343_1_H06',
            'Myo1c',
            'Myo1ctm1a(EUCOMM)Wtsi',
            '13-09-2010',
            'MDCF',
            'WTSI',
            'Unsuitable for EMMA',
            'Micro-injection in progress',
            'Myo1ctm1b(EUCOMM)Wtsi'
          ].each do |text|
            assert(page.has_css?('div', :text => text),
              "Expected text '#{text}' in table cell 1, but did not find it")
          end
        end

        should 'show edit in form link' do
          mi = EsCell.find_by_name('EPD0343_1_H06').mi_attempts.first
          selector = selector_for_table_cell(1) + " a[href=\"/mi_attempts/#{mi.id}\"]"
          assert page.has_css?(selector)
        end

        should 'not show data for other es_cells' do
          assert page.has_no_css?('div', :text => 'EPD0127_4_E01')
        end
      end

      should 'work with a multiple es_cell names' do
        visit '/mi_attempts'
        fill_in 'q[terms]', :with => "EPD0127_4_E01\nEPD0343_1_H06"
        click_button 'Search'

        assert page.has_css? 'div', :text => 'EPD0127_4_E01'
        assert page.has_css? 'div', :text => 'EPD0343_1_H06'
        assert page.has_no_css? 'div', :text => 'EPD0029_1_G04'
      end

      should 'work if whitespace around es_cell names' do
        visit '/mi_attempts'
        fill_in 'q[terms]', :with => "  EPD0343_1_H06\t"
        click_button 'Search'

        assert page.has_css? 'div', :text => 'EPD0343_1_H06'
      end

      should 'show emma statuses' do
        visit '/mi_attempts?q[terms]=EPD0127_4_E01'

        assert page.has_css? 'div', :text => 'Suitable for EMMA'
        assert page.has_css? 'div', :text => 'Unsuitable for EMMA'
      end

      should 'show search terms when results are shown' do
        visit "/mi_attempts?q[terms]=EPD0127_4_E01%0D%0AEPD0343_1_H06"
        assert page.has_css? 'textarea[@name="q[terms]"]', :text => "EPD0127_4_E01 EPD0343_1_H06"
      end
    end

    context 'searching for mi attempts by marker symbol' do
      setup do
        create_common_test_objects
        visit '/mi_attempts'
        fill_in 'q[terms]', :with => 'Trafd1'
        click_button 'Search'
      end

      should 'work' do
        assert_match /q%5Bterms%5D=Trafd1/, current_url
        assert page.has_css? 'div', :text => 'EPD0127_4_E01'
      end

      should 'not find unmatched es_cells' do
        assert page.has_no_css?('div', :text => 'EPD0343_1_H06')
      end
    end

    context 'searching by a term and filtering by production centre' do
      setup do
        @es_cell1 = Factory.create :es_cell_EPD0343_1_H06
        @es_cell2 = Factory.create :es_cell_EPD0127_4_E01
        @es_cell3 = Factory.create :es_cell_EPD0029_1_G04

        @mi_attempt = Factory.create(:mi_attempt, :es_cell => @es_cell1,
          :production_centre_name => 'ICS')

        visit '/mi_attempts'
        fill_in 'q[terms]', :with => "myo1c\n"
        select 'ICS', :from => 'q[production_centre_name]'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css?('div', :text => @mi_attempt.es_cell.name)
      end

      should 'not show things that only match one of the terms but not the other' do
        assert_equal 2, @es_cell1.mi_attempts.size
        assert_equal 1, all('.x-grid-row').size
        assert page.has_no_css?('div.x-grid-cell-inner', :text => 'WTSI')
      end

      should 'have filtered production centre pre-selected in dropdown' do
        assert page.has_css? 'select[@name="q[production_centre_name]"] option[selected="selected"][value="ICS"]'
      end
    end

    context 'searching by a term and filtering by status' do
      setup do
        @es_cell1 = Factory.create :es_cell_EPD0343_1_H06
        @es_cell2 = Factory.create :es_cell_EPD0127_4_E01
        @es_cell3 = Factory.create :es_cell_EPD0029_1_G04

        @status = MiAttemptStatus.micro_injection_aborted.description
        @mi_attempt = Factory.create(:mi_attempt, :es_cell => @es_cell2)
        @mi_attempt.update_attributes!(:is_active => false)
        assert_equal @status, @mi_attempt.status

        mi_attempt_to_not_be_found = Factory.create(:mi_attempt, :es_cell => @es_cell1)
        mi_attempt_to_not_be_found.update_attributes!(:is_active => false)
        assert_equal @status, mi_attempt_to_not_be_found.status

        sleep 3
        visit '/mi_attempts'
        fill_in 'q[terms]', :with => "trafd1\n"
        select @status, :from => 'q[status]'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css? 'div', :text => @mi_attempt.es_cell.name
        assert page.has_css? 'div', :text => @status
      end

      should 'not show any non-matching mi attempts' do
        assert_equal 1, all('.x-grid-row').size
      end

      should 'have filtered status pre-selected in dropdown' do
        assert page.has_css? 'select[@name="q[status]"] option[selected="selected"][value="' + @status + '"]'
      end
    end

    should 'work for search with no terms' do
      visit '/mi_attempts'
      click_button 'Search'
      assert ! page.has_content?('error')
    end

    should 'display test data warning' do
      visit '/mi_attempts'
      assert page.has_content? 'DO NOT ENTER ANY PRODUCTION DATA'
    end

  end

end
