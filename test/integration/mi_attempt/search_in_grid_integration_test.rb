# encoding: utf-8

require 'test_helper'

class MiAttempt::SearchInGridIntegrationTest < TarMits::JsIntegrationTest
  context 'Searching for MI attempts in grid' do

    context 'when not logged in grid ' do

      should 'not have an editable option' do
        visit '/'
        click_link 'Mouse Production'
        assert page.has_content?('View In Form')
      end
    end

    context 'as valid user' do
      setup do
        visit '/users/logout'
        login
      end

      should 'filter by user\'s production centre when Mouse Production page is clicked' do
        click_link 'Mouse Production'
        assert_equal default_user.production_centre.name,
                page.find('select[name="q[production_centre_name]"] option[selected=selected]').value
      end

      should 'have an editable option' do
        click_link 'Mouse Production'
        assert page.has_content?('View In Form')
      end

      context 'by es_cell name' do

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
            mi_attempt = TargRep::EsCell.find_by_name!('EPD0343_1_H06').mi_attempts.first
            mi_attempt.mouse_allele_type = 'b'
            mi_attempt.save!
            sleep 3
            click_button 'Search'
            [
              'EPD0343_1_H06',
              'Myo1c',
              'Myo1ctm1a(EUCOMM)Wtsi',
              '13-09-2010',
              'MDCF',
              'WTSI',
              'Micro-injection in progress',
              'Myo1ctm1b(EUCOMM)Wtsi'
            ].each do |text|
              assert(page.has_css?('div.x-grid-cell-inner', :text => text),
                "Expected text '#{text}' in table cell 1, but did not find it")
            end

            selector = selector_for_table_cell(1) + " a[href=\"/mi_attempts/#{mi_attempt.id}\"]"
            assert page.has_css?(selector), 'should show edit link'

            assert page.has_no_css?('div', :text => 'EPD0127_4_E01'), 'should not show data for other cells'
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

        should 'show search terms when results are shown' do
          visit "/mi_attempts?q[terms]=EPD0127_4_E01%0D%0AEPD0343_1_H06"
          assert page.has_css? 'textarea[@name="q[terms]"]'
          assert_match /EPD0127_4_E01\s+EPD0343_1_H06/, page.find('textarea[@name="q[terms]"]').text
        end
      end

      context 'by marker symbol' do
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

      context 'by a term and filtering by production centre' do
        setup do
          @es_cell1 = Factory.create :es_cell_EPD0343_1_H06
          @es_cell2 = Factory.create :es_cell_EPD0127_4_E01
          @es_cell3 = Factory.create :es_cell_EPD0029_1_G04

          @mi_attempt = Factory.create(:mi_attempt2, :es_cell => @es_cell1,
            :mi_plan => TestDummy.mi_plan('BaSH', 'ICS', :gene => @es_cell1.gene, :force_assignment => true))

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

      context 'by a term and filtering by status' do
        setup do
          @es_cell1 = Factory.create :es_cell_EPD0343_1_H06
          @es_cell2 = Factory.create :es_cell_EPD0127_4_E01
          @es_cell3 = Factory.create :es_cell_EPD0029_1_G04

          @status = MiAttempt::Status.micro_injection_aborted.name
          @mi_attempt = Factory.create(:mi_attempt2, :es_cell => @es_cell2,
            :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => @es_cell2.gene, :force_assignment => true))
          @mi_attempt.update_attributes!(:is_active => false)
          assert_equal @status, @mi_attempt.status.name

          mi_attempt_to_not_be_found = Factory.create(:mi_attempt2, :es_cell => @es_cell1,
            :mi_plan => TestDummy.mi_plan('BaSH', 'ICS', :gene => @es_cell1.gene, :force_assignment => true)
          )
          mi_attempt_to_not_be_found.update_attributes!(:is_active => false)
          assert_equal @status, mi_attempt_to_not_be_found.status.name

          sleep 3
          visit '/mi_attempts'
          fill_in 'q[terms]', :with => "trafd1\n"
          select @status, :from => 'q[status_name]'
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
          assert page.has_css? 'select[@name="q[status_name]"] option[selected="selected"][value="' + @status + '"]'
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
end
