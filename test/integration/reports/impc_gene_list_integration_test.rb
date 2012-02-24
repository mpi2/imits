# encoding: utf-8

require 'test_helper'

class Reports::ImpcGeneListIntegrationTest < ActionDispatch::IntegrationTest

  context 'IMPC Gene List:' do
    setup do
      create_common_test_objects
      Reports::MiProduction::Intermediate.new.cache
      visit '/users/logout'
    end

    context 'IMPC Gene List csv' do
      should 'have link to cached report' do
        visit '/reports/impc_gene_list'
        assert page.has_content? "Gene,MGI Accession ID,Overall Status,IKMC Project ID"
      end
    end
  end
end
