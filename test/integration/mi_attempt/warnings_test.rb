# encoding: utf-8

require 'test_helper'

class MiAttempt::WarningsTest < TarMits::JsIntegrationTest
  context 'Warnings for mi_attempts:' do
    setup do
      login
    end

    context 'when creating MI' do
      should 'not show them when rendering mi_attempts/new' do
        visit new_mi_attempt_path
        assert page.has_no_css?('#warnings')
      end

      should 'not show warnings when there are validation errors' do
        es_cell = Factory.create :es_cell_EPD0127_4_E01, :allele => Factory.create(:allele_with_gene_trafd1)

        visit new_mi_attempt_path
        choose_es_cell_from_list(es_cell.gene.marker_symbol, es_cell.name)
        fill_in 'mi_attempt[colony_name]', :with => es_cell.mi_attempts.first.colony_name
        click_button 'mi_attempt_submit'
        assert page.has_content? 'ES Cell Details'
        assert page.has_no_css?('#warnings')
      end

      should 'show them after posting form when there are warnings' do
        mi_attempt = Factory.create :mi_attempt2
        es_cell = Factory.create :es_cell_EPD0127_4_E01, :allele => Factory.create(:allele_with_gene_trafd1)

        visit new_mi_attempt_path
        choose_es_cell_from_list(es_cell.gene.marker_symbol, es_cell.name)
        choose_date_from_datepicker_for_input('mi_attempt[mi_date]')
        consortium_name = 'EUCOMM-EUMODIC'
        find(:xpath, '//td/div[text()="' + consortium_name + '"]').click

        mis_count = es_cell.mi_attempts.count
        click_button 'mi_attempt_submit'
        assert page.has_no_css?('#mi_attempt_submit[disabled]')
        es_cell.reload

        assert_equal mis_count, es_cell.mi_attempts.count

        assert page.has_content? 'ES Cell Details'
        assert_current_link 'Create MI Attempt'

        within('#warnings ul') do
          assert page.has_css? 'li', :text => MiAttempt::WARNING_MESSAGES[:gene_already_micro_injected]
        end
      end

      should 'let user ignore warnings and create anyway' do
        es_cell = Factory.create :es_cell_EPD0127_4_E01, :allele => Factory.create(:allele_with_gene_trafd1)

        visit new_mi_attempt_path
        choose_es_cell_from_list(es_cell.gene.marker_symbol, es_cell.name)
        choose_date_from_datepicker_for_input('mi_attempt[mi_date]')
        consortium_name = 'EUCOMM-EUMODIC'
        find(:xpath, '//td/div[text()="' + consortium_name + '"]').click

        click_button 'mi_attempt_submit'

        assert_current_link 'Create MI Attempt'

        page.find('#warnings button').click

        assert page.has_content? 'ES Cell Details'
        assert page.has_content? 'EPD0127_4_E01'
        assert_match %r{/mi_attempts/\d+}, current_url
      end
    end

    should 'not show them on edit page' do
      mi = Factory.create :mi_attempt2
      visit mi_attempt_path(mi)
      assert page.has_no_css?('#warnings')
    end

  end
end
