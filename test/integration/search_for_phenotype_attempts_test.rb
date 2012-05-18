# encoding: utf-8

require 'test_helper'

class SearchForPhenotypeAttemptsTest < Kermits2::JsIntegrationTest

  should 'need a valid logged in user' do
    visit '/users/logout'

    visit '/'
    assert_match %r{/users/login$}, current_url

    visit '/phenotype_attempts'
    assert_match %r{/users/login$}, current_url
  end

  context 'As valid user:' do
    setup do
      visit '/users/logout'
      login
    end

    context 'searching for phenotyping attempts by marker symbol' do
      setup do
        @es_cell1 = Factory.create :es_cell_EPD0011_1_G18
        visit '/phenotype_attempts'
        fill_in 'q[terms]', :with => 'Gatc'
        click_button 'Search'
      end

      should 'work' do
        assert_match /q%5Bterms%5D=Gatc/, current_url
        assert page.has_css? 'div', :text => 'Gatc'
      end

      should 'not find unmatched phenotype attempts' do
        assert page.has_no_css?('div', :text => 'Abo')
      end
    end

    context 'searching by a term and filtering by production centre' do
      setup do
        @es_cell1 = Factory.create :es_cell_EPD0011_1_G18
        visit '/phenotype_attempts'
        fill_in 'q[terms]', :with => "Gatc\n"
        select 'WTSI', :from => 'q[production_centre_name]'
        click_button 'Search'
        sleep 3
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css?('div', :text => @es_cell1.gene.marker_symbol)
      end

      should 'have filtered production centre pre-selected in dropdown' do
        assert page.has_css? 'select[@name="q[production_centre_name]"] option[selected="selected"][value="WTSI"]'
      end
    end

    should 'work for search with no terms' do
      visit '/phenotype_attempts'
      click_button 'Search'
      assert ! page.has_content?('error')
    end

    should 'display test data warning' do
      visit '/phenotype_attempts'
      assert page.has_content? 'DO NOT ENTER ANY PRODUCTION DATA'
    end

  end

end
