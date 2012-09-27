require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::DocFactory' do

    context '#create' do
      should 'work when reference type is mi_attempt' do
        mi = Factory.create :mi_attempt
        mi_ref = {'type' => 'mi_attempt', 'id' => mi.id}
        docs = [{'test_doc' => true}]
        SolrUpdate::DocFactory.expects(:create_for_mi_attempt).with(mi).returns(docs)
        SolrUpdate::DocFactory.create(mi_ref)
      end
    end

    context 'when creating solr docs for mi_attempt' do

      setup do
        @es_cell = Factory.create :es_cell,
                :gene => cbx1,
                :mutation_subtype => 'conditional_ready',
                :allele_id => 663
        @mi_attempt = Factory.create :mi_attempt, :id => 43,
                :colony_background_strain => Strain.create!(:name => 'TEST STRAIN'),
                :es_cell => @es_cell
        @mi_attempt.stubs(:allele_symbol).returns('TEST ALLELE SYMBOL')

        docs = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt)
        assert_equal 1, docs.size
        @doc = docs.first
      end

      should 'set id and type' do
        assert_equal ['mi_attempt', 43], @doc.values_at('type', 'id')
      end

      should 'set product_type' do
        assert_equal 'Mouse', @doc['product_type']
      end

      should 'set mgi_accession_id' do
        assert_equal cbx1.mgi_accession_id, @doc['mgi_accession_id']
      end

      context 'allele_type' do
        should 'be set from the es_cell if mouse_allele_type is not "e"' do
          @mi_attempt.mouse_allele_type = 'a'

          @es_cell.mutation_subtype = 'conditional_ready'
          doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
          assert_equal 'Conditional Ready', doc['allele_type']

          @es_cell.mutation_subtype = 'deletion'
          doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
          assert_equal 'Deletion', doc['allele_type']
        end

        should 'be set to targeted_non_conditional if mouse_allele_type is "e" regardless of es_cell' do
          @mi_attempt.mouse_allele_type = 'e'
          @es_cell.mutation_subtype = 'conditional_ready'

          doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
          assert_equal 'Targeted Non Conditional', doc['allele_type']
        end

      end

      should 'set strain of origin' do
        assert_equal 'TEST STRAIN', @doc['strain']
      end

      should 'set allele_name' do
        assert_equal 'TEST ALLELE SYMBOL', @doc['allele_name']
      end

      should 'set allele_image_url' do
        assert_equal 'http://www.knockoutmouse.org/targ_rep/alleles/663/allele-image',
                @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal 'http://www.knockoutmouse.org/targ_rep/alleles/663/escell-clone-genbank-file',
                @doc['genbank_file_url']
      end

      context 'order_from_url and order_from_name' do
        should 'be set correctly to KOMP if consortium is JAX, DTCC or BASH and ikmc_project_id begins with VG' do
          ['JAX', 'DTCC', 'BaSH'].each do |consortium_name|
            @mi_attempt.mi_plan.consortium = Consortium.find_by_name!(consortium_name)
            @mi_attempt.es_cell.ikmc_project_id = 'VG10003'
            doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
            assert_equal 'KOMP', doc['order_from_name']
            assert_equal 'http://www.komp.org/geneinfo.php?project=VG10003', doc['order_from_url']
          end
        end

        should 'be set correctly to KOMP if consortium is JAX, DTCC or BASH and ikmc_project_id begins does NOT begin with VG' do
          ['JAX', 'DTCC', 'BaSH'].each do |consortium_name|
            @mi_attempt.mi_plan.consortium = Consortium.find_by_name!(consortium_name)
            @mi_attempt.es_cell.ikmc_project_id = '10003'
            doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
            assert_equal 'KOMP', doc['order_from_name']
            assert_equal 'http://www.komp.org/geneinfo.php?project=CSD10003', doc['order_from_url']
          end
        end

        should 'be set correctly if consortium is Phenomin, HHelmholtz GMC, Monterotondo, MRC' do
          ['Phenomin', 'Helmholtz GMC', 'Monterotondo', 'MRC'].each do |consortium_name|
            consortium = Consortium.find_by_name!(consortium_name)
            @mi_attempt.mi_plan.consortium = consortium
            doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
            assert_equal 'EMMA', doc['order_from_name']
            assert_equal "http://www.emmanet.org/mutant_types.php?keyword=#{@mi_attempt.gene.marker_symbol}", doc['order_from_url']
          end
        end

        should 'be set correctly if consortium is MGP and has a distribution centre with EMMA flag set to true exists' do
          @mi_attempt.mi_plan.consortium = Consortium.find_by_name!('MGP')
          dist_centre1 = Factory.create :mi_attempt_distribution_centre,
                  :centre => Centre.find_by_name!('WTSI'),
                  :is_distributed_by_emma => false, :mi_attempt => @mi_attempt
          dist_centre2 = Factory.create :mi_attempt_distribution_centre,
                  :centre => Centre.find_by_name!('ICS'),
                  :is_distributed_by_emma => true, :mi_attempt => @mi_attempt
          @mi_attempt.distribution_centres = [dist_centre1, dist_centre2]

          doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
          assert_equal 'EMMA', doc['order_from_name']
          assert_equal "http://www.emmanet.org/mutant_types.php?keyword=#{@mi_attempt.gene.marker_symbol}", doc['order_from_url']
        end

        should 'be set correctly if consortium is MGP and has NO distribution centre with EMMA flag set' do
          @mi_attempt.mi_plan.consortium = Consortium.find_by_name!('MGP')
          dist_centre = Factory.create :mi_attempt_distribution_centre,
                  :centre => Centre.find_by_name!('WTSI'),
                  :is_distributed_by_emma => false, :mi_attempt => @mi_attempt
          @mi_attempt.distribution_centres = [dist_centre]

          doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
          assert_equal 'WTSI', doc['order_from_name']
          assert_equal "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{@mi_attempt.gene.marker_symbol}", doc['order_from_url']
        end
      end

    end

  end
end
