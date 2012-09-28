require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase

  def self.order_from_tests(object_type)
    factory_method_name = :"create_for_#{object_type}"
    distribution_centres_factory = :"#{object_type}_distribution_centre"

    context 'order_from_url and order_from_name' do

      setup do
        @test_object = instance_variable_get(:"@#{object_type}")
      end

      context 'when consortium is JAX, DTCC or BASH' do
        should 'be set correctly to KOMP ikmc_project_id begins with VG' do
          ['JAX', 'DTCC', 'BaSH'].each do |consortium_name|
            @test_object.mi_plan.consortium = Consortium.find_by_name!(consortium_name)
            @test_object.es_cell.ikmc_project_id = 'VG10003'
            doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
            assert_equal 'KOMP', doc['order_from_name']
            assert_equal 'http://www.komp.org/geneinfo.php?project=VG10003', doc['order_from_url']
          end
        end

        should 'be set correctly to KOMP if ikmc_project_id begins does NOT begin with VG' do
          ['JAX', 'DTCC', 'BaSH'].each do |consortium_name|
            @test_object.mi_plan.consortium = Consortium.find_by_name!(consortium_name)
            @test_object.es_cell.ikmc_project_id = '10003'
            doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
            assert_equal 'KOMP', doc['order_from_name']
            assert_equal 'http://www.komp.org/geneinfo.php?project=CSD10003', doc['order_from_url']
          end
        end

        should 'be set correctly if ikmc_project_id does NOT exist' do
          flunk
        end
      end

      should 'be set correctly if consortium is Phenomin, HHelmholtz GMC, Monterotondo, MRC' do
        ['Phenomin', 'Helmholtz GMC', 'Monterotondo', 'MRC'].each do |consortium_name|
          consortium = Consortium.find_by_name!(consortium_name)
          @test_object.mi_plan.update_attributes!(:consortium => consortium)
          @test_object.reload

          doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
          assert_equal 'EMMA', doc['order_from_name']
          assert_equal "http://www.emmanet.org/mutant_types.php?keyword=#{@test_object.gene.marker_symbol}", doc['order_from_url']
        end
      end

      should 'be set correctly if consortium is MGP and has a distribution centre with EMMA flag set to true exists' do
        @test_object.mi_plan.update_attributes!(:consortium => Consortium.find_by_name!('MGP'))
        @test_object.distribution_centres.destroy_all

        dist_centre1 = Factory.create distribution_centres_factory,
                :centre => Centre.find_by_name!('WTSI'),
                :is_distributed_by_emma => false, object_type => @test_object
        dist_centre2 = Factory.create distribution_centres_factory,
                :centre => Centre.find_by_name!('ICS'),
                :is_distributed_by_emma => true, object_type => @test_object
        @test_object.distribution_centres = [dist_centre1, dist_centre2]

        @test_object.reload

        doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
        assert_equal 'EMMA', doc['order_from_name']
        assert_equal "http://www.emmanet.org/mutant_types.php?keyword=#{@test_object.gene.marker_symbol}", doc['order_from_url']
      end

      should 'be set correctly if consortium is MGP and has NO distribution centre with EMMA flag set' do
        @test_object.mi_plan.consortium = Consortium.find_by_name!('MGP')
        dist_centre = Factory.create distribution_centres_factory,
                :centre => Centre.find_by_name!('WTSI'),
                :is_distributed_by_emma => false, object_type => @test_object
        @test_object.distribution_centres.destroy_all
        @test_object.distribution_centres = [dist_centre]

        doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
        assert_equal 'WTSI', doc['order_from_name']
        assert_equal "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{@test_object.gene.marker_symbol}", doc['order_from_url']
      end

    end
  end # order_from_tests

  context 'SolrUpdate::DocFactory' do

    teardown do
      SolrUpdate::DocFactory.unstub(:create_for_mi_attempt)
      SolrUpdate::DocFactory.unstub(:create_for_phenotype_attempt)
    end

    context '#create' do
      should 'work when reference type is mi_attempt' do
        mi = Factory.create :mi_attempt
        mi_ref = {'type' => 'mi_attempt', 'id' => mi.id}
        docs = [{'test_doc' => true}]
        SolrUpdate::DocFactory.expects(:create_for_mi_attempt).with(mi).returns(docs)
        SolrUpdate::DocFactory.create(mi_ref)
      end

      should 'work when reference type is phenotype_attempt' do
        pa = Factory.create :phenotype_attempt
        pa_ref = {'type' => 'phenotype_attempt', 'id' => pa.id}
        docs = [{'test_doc' => true}]
        SolrUpdate::DocFactory.expects(:create_for_phenotype_attempt).with(pa).returns(docs)
        SolrUpdate::DocFactory.create(pa_ref)
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
        cbx1.update_attributes!(:mgi_accession_id => nil)
        @mi_attempt.gene.reload
        @doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
        assert_false @doc.has_key? 'mgi_accession_id'
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

      order_from_tests :mi_attempt
    end

    context 'when creating solr docs for phenotype_attempt' do

      setup do
        @es_cell = Factory.create :es_cell,
                :gene => cbx1,
                :mutation_subtype => 'conditional_ready',
                :allele_id => 8563
        @mi_attempt = Factory.create :mi_attempt_genotype_confirmed, :es_cell => @es_cell

        @phenotype_attempt = Factory.create :phenotype_attempt_status_cec,
                :id => 86, :mi_attempt => @mi_attempt,
                :colony_background_strain => Strain.create!(:name => 'TEST STRAIN')

        @phenotype_attempt.stubs(:allele_symbol).returns('TEST ALLELE SYMBOL')

        docs = SolrUpdate::DocFactory.create_for_phenotype_attempt(@phenotype_attempt)
        assert_equal 1, docs.size
        @doc = docs.first
      end

      should 'set id and type' do
        assert_equal ['phenotype_attempt', 86], @doc.values_at('type', 'id')
      end

      should 'set product_type' do
        assert_equal 'Mouse', @doc['product_type']
      end

      should 'set mgi_accession_id' do
        assert_equal cbx1.mgi_accession_id, @doc['mgi_accession_id']
        cbx1.update_attributes!(:mgi_accession_id => nil)
        @phenotype_attempt.gene.reload
        @doc = SolrUpdate::DocFactory.create_for_phenotype_attempt(@phenotype_attempt).first
        assert_false @doc.has_key? 'mgi_accession_id'
      end

      context 'allele_type' do
        should 'be Cre Excised Conditional Ready if mouse_allele_type is b' do
          @phenotype_attempt.mouse_allele_type = 'b'
          doc = SolrUpdate::DocFactory.create_for_phenotype_attempt(@phenotype_attempt).first
          assert_equal 'Cre Excised Conditional Ready', doc['allele_type']
        end

        should 'be Cre Excised Deletion if mouse_allele_type is .1' do
          @phenotype_attempt.mouse_allele_type = '.1'
          doc = SolrUpdate::DocFactory.create_for_phenotype_attempt(@phenotype_attempt).first
          assert_equal 'Cre Excised Deletion', doc['allele_type']
        end
      end

      should 'set strain of origin' do
        assert_equal 'TEST STRAIN', @doc['strain']
      end

      should 'set allele_name' do
        assert_equal 'TEST ALLELE SYMBOL', @doc['allele_name']
      end

      should 'set allele_image_url' do
        assert_equal 'http://www.knockoutmouse.org/targ_rep/alleles/8563/allele-image-cre',
                @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal 'http://www.knockoutmouse.org/targ_rep/alleles/8563/escell-clone-cre-genbank-file',
                @doc['genbank_file_url']
      end

      order_from_tests :phenotype_attempt
    end

  end
end
