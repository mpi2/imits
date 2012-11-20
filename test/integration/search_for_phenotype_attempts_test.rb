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

    def create_es_cell_EPD0011_1_G18
      es_cell = Factory.create :es_cell, :name => 'EPD0011_1_G18',
              :allele => Factory.create(:allele_with_gene_gatc),
              :allele_symbol_superscript => 'tm1a(KOMP)Wtsi',
              :pipeline => TargRep::Pipeline.find_by_name!('KOMP-CSD')
      mi_attempt = Factory.create(:wtsi_mi_attempt_genotype_confirmed,
        :es_cell => es_cell,
        :colony_name => 'MBFD',
        :consortium_name => 'MGP',
        :production_centre_name => 'WTSI'
      )
      Factory.create :phenotype_attempt_status_pdc, :mi_attempt => mi_attempt

      return es_cell
    end

    context 'searching for phenotyping attempts by marker symbol' do
      setup do
        create_es_cell_EPD0011_1_G18
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
        @es_cell = create_es_cell_EPD0011_1_G18
        visit '/phenotype_attempts'
        fill_in 'q[terms]', :with => "Gatc\n"
        select 'WTSI', :from => 'q[production_centre_name]'
        click_button 'Search'
        wait_until_grid_loaded
      end

      should 'show results that match the search terms and the filter' do
        assert page.has_css?('div', :text => @es_cell.gene.marker_symbol)
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
