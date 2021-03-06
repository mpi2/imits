# encoding: utf-8

require 'test_helper'

class Reports::ImpcGeneListIntegrationTest < TarMits::IntegrationTest
  context '/reports/impc_gene_list' do

    setup do
      create_common_test_objects
      Factory.create :mi_attempt2_status_chr
      Reports::MiProduction::Intermediate.new.cache
      Reports::ImpcGeneList.new.cache
      visit '/users/logout'
    end

    should 'be a cached report acessible without authentication' do
      visit '/reports/impc_gene_list'
      assert page.has_content? "Gene,MGI Accession ID,Overall Status,IKMC Project ID"
    end

  end
end
