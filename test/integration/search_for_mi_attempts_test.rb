require 'test_helper'

class SearchForMiAttemptsTest < ActionDispatch::IntegrationTest

  should 'need a valid logged in user' do
    visit '/logout'

    visit '/'
    assert_match %r{/login$}, current_url

    visit '/mi_attempts'
    assert_match %r{/login$}, current_url
  end

  context 'As valid user:' do
    setup do
=begin TODO
      visit '/logout'
      login
=end
    end

    context 'searching for mi attempts by clone name' do

      setup do
        create_common_test_objects
      end

      context 'with a single clone' do
        setup do
          visit '/mi_attempts'
          fill_in 'search_terms', :with => 'EPD0343_1_H06'
          click_button 'Search'
          assert_match /search_terms=EPD0343_1_H06/, current_url
        end

        should 'show all data for that clone' do
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

        should 'not show data for other clones' do
          assert page.has_no_css?('.x-grid3-col-clone__clone_name', :text => 'EPD0127_4_E01')
        end
      end

      should 'work with a multiple clone names' do
        visit '/'
        fill_in 'search_terms', :with => "EPD0127_4_E01\nEPD0343_1_H06"
        click_button 'Search'

        assert page.has_css? '.x-grid3-cell-inner', :text => 'EPD0127_4_E01'
        assert page.has_css? '.x-grid3-cell-inner', :text => 'EPD0343_1_H06'
        assert page.has_no_css? '.x-grid3-cell-inner', :text => 'EPD0029_1_G04'
      end

      should 'work if whitespace around clone names' do
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

    context 'searching for mi attempts by gene symbol' do
      setup do
        create_common_test_objects
        visit '/'
        assert_false page.has_css? 'x-grid3'
        fill_in 'search_terms', :with => 'Trafd1'
        click_button 'Search'
      end

      should 'work' do
        assert_match /search_terms=Trafd1/, current_url
        assert page.has_css? selector_for_table_cell(1), :text => 'EPD0127_4_E01'
      end

      should 'not find unmatched clones' do
        assert page.has_no_css?('.x-grid3-cell-inner', :text => 'EPD0343_1_H06')
      end
    end

    context 'searching by a term and filtering by production centre' do
      setup do
        @clone1 = Factory.create :clone_EPD0343_1_H06
        @clone2 = Factory.create :clone_EPD0127_4_E01
        @clone3 = Factory.create :clone_EPD0029_1_G04

        @mi_attempt = Factory.create(:mi_attempt, :clone => @clone1,
          :production_centre => Centre.find_by_name!('ICS'))

        visit '/'
        fill_in 'search_terms', :with => "myo1c\n"
        select 'ICS', :from => 'production_centre_id'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css? '.x-grid3-col-clone__clone_name', :text => @mi_attempt.clone.clone_name
      end

      should 'not show things that only match one of the terms but not the other' do
        assert_equal 2, @clone1.mi_attempts.size
        assert_equal 1, all('.x-grid3-col-clone__clone_name').size
        assert page.has_no_css? '.x-grid3-col-production_centre__name', :text => 'WTSI'
      end

      should 'have filtered production centre pre-selected in dropdown' do
        assert page.has_css? '#production_centre_id option[selected="selected"][value="2"]'
      end
    end

    context 'searching by a term and filtering by status' do
      setup do
        @clone1 = Factory.create :clone_EPD0343_1_H06
        @clone2 = Factory.create :clone_EPD0127_4_E01
        @clone3 = Factory.create :clone_EPD0029_1_G04

        @status = MiAttemptStatus.create!(:description => 'Nonsense')

        @mi_attempt = Factory.create(:mi_attempt, :clone => @clone2,
          :mi_attempt_status => @status)

        mi_attempt_to_not_be_found = Factory.create(:mi_attempt, :clone => @clone1,
          :mi_attempt_status => @status)

        sleep 3
        visit '/'
        fill_in 'search_terms', :with => "trafd1\n"
        select 'Nonsense', :from => 'mi_attempt_status_id'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css? '.x-grid3-col-clone__clone_name', :text => @mi_attempt.clone.clone_name
        assert page.has_css? '.x-grid3-col-mi_attempt_status__description', :text => 'Nonsense'
      end

      should 'not show any non-matching mi attempts' do
        assert_equal 1, all('.x-grid3-col-clone__clone_name').size
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

    should 'clear form when Clear button is pushed' do
      visit '/mi_attempts?search_terms=EPD0127_4_E01%0D%0AEPD0343_1_H06'
      fill_in 'search_terms', :with => 'some text'
      click_button('Clear')
      assert_blank find('#search-terms').text
    end

    should 'display test data warning' do
      visit '/'
      assert page.has_content? 'SAMPLE DATA'
    end

  end

end
