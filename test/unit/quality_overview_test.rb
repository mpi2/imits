# encoding: utf-8

require 'test_helper'

class QualityOverviewTest < ActiveSupport::TestCase

  context "QualityOverview" do

    setup do
      @es_cell = Factory.create :es_cell_EPD0343_1_H06, :allele => Factory.create(:allele_with_gene_myolc)
      @mi_attempt = Factory.build :mi_attempt, :es_cell => @es_cell
      @mi_attempt.es_cell.allele_symbol_superscript = 'tm2b(KOMP)Wtsi'
    end

    should 'accept the following attributes' do
      quality_overview = QualityOverview.new
      quality_overview.indicator = 'inprogress'
      quality_overview.colony_prefix = 'UCD-10009A-F9-1'
      quality_overview.pipeline = 'KOMP-Regeneron'
      quality_overview.consortium = 'DTCC-Legacy'
      quality_overview.production_centre = 'UCD'
      quality_overview.microinjection_date = '2008-02-18'
      quality_overview.marker_symbol = 'Celsr3'
      quality_overview.mutation_subtype = 'deletion'
      quality_overview.es_cell_clone = '10009A-F9'
      quality_overview.confirm_locus_targeted = '1'
      quality_overview.confirm_structure_targeted_allele = '1'
      quality_overview.confirm_downstream_lox_p_site = '1'
      quality_overview.confirm_no_additional_vector_insertions = '1'
      quality_overview.es_dist_qc = 'distribution_qc_five_prime_sr_pcr'
      quality_overview.es_user_qc = 'user_qc_karyotype'
      quality_overview.mouse_qc = 'qc_lacz_sr_pcr'

      assert quality_overview.instance_variables.include?(:@indicator)
      assert quality_overview.instance_variables.include?(:@colony_prefix)
      assert quality_overview.instance_variables.include?(:@pipeline)
      assert quality_overview.instance_variables.include?(:@consortium)
      assert quality_overview.instance_variables.include?(:@production_centre)
      assert quality_overview.instance_variables.include?(:@microinjection_date)
      assert quality_overview.instance_variables.include?(:@marker_symbol)
      assert quality_overview.instance_variables.include?(:@mutation_subtype)
      assert quality_overview.instance_variables.include?(:@es_cell_clone)
      assert quality_overview.instance_variables.include?(:@confirm_locus_targeted)
      assert quality_overview.instance_variables.include?(:@confirm_downstream_lox_p_site)
      assert quality_overview.instance_variables.include?(:@confirm_no_additional_vector_insertions)
      assert quality_overview.instance_variables.include?(:@es_dist_qc)
      assert quality_overview.instance_variables.include?(:@es_user_qc)
      assert quality_overview.instance_variables.include?(:@mouse_qc)

      assert_equal 'inprogress', quality_overview.indicator
      assert_equal 'UCD-10009A-F9-1', quality_overview.colony_prefix
      assert_equal 'KOMP-Regeneron', quality_overview.pipeline
      assert_equal 'DTCC-Legacy', quality_overview.consortium
      assert_equal 'UCD', quality_overview.production_centre
      assert_equal '2008-02-18', quality_overview.microinjection_date
      assert_equal 'Celsr3', quality_overview.marker_symbol
      assert_equal 'deletion', quality_overview.mutation_subtype
      assert_equal '10009A-F9', quality_overview.es_cell_clone
      assert_equal '1', quality_overview.confirm_locus_targeted
      assert_equal '1', quality_overview.confirm_structure_targeted_allele
      assert_equal '1', quality_overview.confirm_downstream_lox_p_site
      assert_equal '1', quality_overview.confirm_no_additional_vector_insertions
      assert_equal 'distribution_qc_five_prime_sr_pcr', quality_overview.es_dist_qc
      assert_equal 'user_qc_karyotype', quality_overview.es_user_qc
      assert_equal 'qc_lacz_sr_pcr', quality_overview.mouse_qc

    end

  end

end
