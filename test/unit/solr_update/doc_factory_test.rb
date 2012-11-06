require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase

  def setup_fake_unique_public_info(list_of_params)
    replacement = list_of_params.map do |params|
      {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi'}.merge(params)
    end

    @fake_unique_public_info.replace replacement
  end

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
          ['JAX', 'DTCC', 'BaSH'].each do |consortium_name|
            @test_object.mi_plan.consortium = Consortium.find_by_name!(consortium_name)
            @test_object.es_cell.ikmc_project_id = nil
            doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
            assert_equal 'KOMP', doc['order_from_name']
            assert_equal 'http://www.komp.org/', doc['order_from_url']
          end
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

      ['MGP', 'MGP Legacy'].each do |mgp_consortium|
        should "be set correctly if consortium is #{mgp_consortium} and has a distribution centre with EMMA flag set to true exists" do
          @test_object.mi_plan.update_attributes!(:consortium => Consortium.find_by_name!(mgp_consortium))
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

        should "be set correctly if consortium is #{mgp_consortium} and has NO distribution centre with EMMA flag set" do
          @test_object.mi_plan.consortium = Consortium.find_by_name!(mgp_consortium)
          dist_centre = Factory.create distribution_centres_factory,
                  :centre => Centre.find_by_name!('WTSI'),
                  :is_distributed_by_emma => false, object_type => @test_object
          @test_object.distribution_centres.destroy_all
          @test_object.distribution_centres = [dist_centre]

          doc = SolrUpdate::DocFactory.send(factory_method_name, @test_object).first
          assert_equal 'WTSI', doc['order_from_name']
          assert_equal "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{@test_object.gene.marker_symbol}", doc['order_from_url']
        end
      end # ['MGP', 'MGP Legacy'].each
    
    end
  end # order_from_tests

  context 'SolrUpdate::DocFactory' do

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

      should 'work when reference type is allele' do
        @gene = Factory.create :gene, :mgi_accession_id => 'MGI:9999999991'
        @allele = Factory.create :allele, :id => 55, :gene => @gene
        reference = {'type' => 'allele', 'id' => 55}
        test_docs = [{'test' => true}]
        SolrUpdate::DocFactory.expects(:create_for_allele).with(@allele).returns(test_docs)
        assert_equal test_docs, SolrUpdate::DocFactory.create(reference)
      end

    end

    context 'when creating solr docs for mi_attempt' do

      setup do
        @allele = Factory.create(:allele, :gene => cbx1, :mutation_type => TargRep::MutationType.find_by_name!("Conditional Ready"))
        @es_cell = Factory.create :es_cell,
                :allele => @allele,
                :mutation_subtype => 'conditional_ready'
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

      should 'set allele_id' do
        assert_equal @allele.id, @doc['allele_id']
      end

      should 'set strain of origin' do
        assert_equal 'TEST STRAIN', @doc['strain']
      end

      should 'work with mi_attempts without a colony background strain' do
        @mi_attempt.colony_background_strain = nil

        doc = SolrUpdate::DocFactory.create_for_mi_attempt(@mi_attempt).first
        assert_false doc.has_key?('strain')
      end

      should 'set allele_name' do
        assert_equal 'TEST ALLELE SYMBOL', @doc['allele_name']
      end

      should 'set allele_image_url' do
        assert_equal "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/allele-image",
                @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file",
                @doc['genbank_file_url']
      end

      order_from_tests :mi_attempt
    end

    context 'when creating solr docs for phenotype_attempt' do

      setup do
        @allele = Factory.create(:allele, :gene => cbx1)
        @es_cell = Factory.create :es_cell,
                :allele => @allele,
                :mutation_subtype => 'conditional_ready'
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

      should 'set allele_id' do
        assert_equal @allele.id, @doc['allele_id']
      end

      should 'set strain of origin' do
        assert_equal 'TEST STRAIN', @doc['strain']
      end

      should 'work with mi_attempts without a colony background strain' do
        @phenotype_attempt.colony_background_strain = nil
        doc = SolrUpdate::DocFactory.create_for_phenotype_attempt(@phenotype_attempt).first
        assert_false doc.has_key?('strain')
      end

      should 'set allele_name' do
        assert_equal 'TEST ALLELE SYMBOL', @doc['allele_name']
      end

      should 'set allele_image_url' do
        assert_equal "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/allele-image-cre",
                @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/escell-clone-cre-genbank-file",
                @doc['genbank_file_url']
      end

      order_from_tests :phenotype_attempt
    end

        context 'when creating solr docs for allele' do

      setup do
        @gene = Factory.create :gene, :mgi_accession_id => 'MGI:9999999991', :marker_symbol => 'Test1'
        @allele = Factory.create :allele, :mutation_type => TargRep::MutationType.find_by_code!('crd'), :gene => @gene
                
        @fake_unique_public_info = [
          {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi', :pipeline => 'EUCOMM'},
          {:strain => 'C57BL/6N-A<tm1Brd>/a', :allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi', :pipeline => 'EUCOMMTools'}
        ]

        es_cells = stub('es_cells')
        es_cells.stubs(:unique_public_info).returns(@fake_unique_public_info)
        @allele.stubs(:es_cells).returns(es_cells)

        @docs = SolrUpdate::DocFactory.create_for_allele(@allele)
      end

      should 'set id' do
        assert_equal [@allele.id, @allele.id], @docs.map {|d| d['id']}
      end

      should 'set type' do
        assert_equal ['allele', 'allele'], @docs.map {|d| d['type']}
      end

      should 'set product_type' do
        assert_equal ['ES Cell', 'ES Cell'], @docs.map {|d| d['product_type']}
      end

      should 'set allele_type' do
        assert_equal ['Conditional Ready', 'Conditional Ready'], @docs.map {|d| d['allele_type']}
        @allele.mutation_type = TargRep::MutationType.find_by_code!('tnc')
        @docs = SolrUpdate::DocFactory.create_for_allele(@allele)
        assert_equal ['Targeted Non Conditional', 'Targeted Non Conditional'], @docs.map {|d| d['allele_type']}
      end

      should 'set allele_id' do
        assert_equal [@allele.id, @allele.id], @docs.map {|d| d['allele_id']}
      end

      should 'set strain' do
        assert_equal ['C57BL/6N', 'C57BL/6N-A<tm1Brd>/a'], @docs.map {|d| d['strain']}
      end

      should 'set allele_name' do
        assert_equal ['Test1<sup>tm1a(EUCOMM)Wtsi</sup>', 'Test1<sup>tm2a(EUCOMM)Wtsi</sup>'],
                @docs.map {|d| d['allele_name']}
      end

      should 'set allele_image_url' do
        url = "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/allele-image"
        assert_equal [url, url], @docs.map {|d| d['allele_image_url']}
      end

      should 'set genbank_file_url' do
        url = "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file"
        assert_equal [url, url], @docs.map {|d| d['genbank_file_url']}
      end

      context 'order_from_url and order_from_name' do
        should 'be set for any of the EUCOMM pipelines' do
          expected_url = 'http://www.eummcr.org/order.php'
          expected_name = 'EUMMCR'

          setup_fake_unique_public_info [
            {:pipeline => 'EUCOMM'},
            {:pipeline => 'EUCOMMTools'},
            {:pipeline => 'EUCOMMToolsCre'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*3, @docs.map {|d| d['order_from_url']}
          assert_equal [expected_name]*3, @docs.map {|d| d['order_from_name']}
        end

        should 'work for one of the KOMP pipelines without a valid project id' do
          expected_url = 'http://www.komp.org/geneinfo.php?project=CSD123'
          expected_name = 'KOMP'

          setup_fake_unique_public_info [
            {:pipeline => 'KOMP-CSD', :ikmc_project_id => '123'},
            {:pipeline => 'KOMP-Regeneron', :ikmc_project_id => '123'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_url']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_name']}
        end

        should 'work for one of the KOMP pipelines with a valid project id' do
          expected_url = 'http://www.komp.org/geneinfo.php?project=VG10003'
          expected_name = 'KOMP'

          setup_fake_unique_public_info [
            {:ikmc_project_id => 'VG10003', :pipeline => 'KOMP-CSD'},
            {:ikmc_project_id => 'VG10003', :pipeline => 'KOMP-Regeneron'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_url']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_name']}
        end

        should 'work for one of the KOMP pipelines with NO project id' do
          expected_url = 'http://www.komp.org/'
          expected_name = 'KOMP'

          setup_fake_unique_public_info [
            {:pipeline => 'KOMP-CSD'},
            {:pipeline => 'KOMP-Regeneron'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_url']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_name']}
        end

        should 'work for mirKO or Sanger MGP pipelines' do
          expected_url = 'mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for Test1'
          expected_name = 'Wtsi'

          setup_fake_unique_public_info [
            {:pipeline => 'mirKO'},
            {:pipeline => 'Sanger MGP'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_url']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_name']}
        end

        should 'work for one of the NorCOMM pipeline' do
          expected_url = 'http://www.phenogenomics.ca/services/cmmr/escell_services.html'
          expected_name = 'NorCOMM'

          setup_fake_unique_public_info [
            {:pipeline => 'NorCOMM'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url], @docs.map{|d| d['order_from_url']}
          assert_equal [expected_name], @docs.map{|d| d['order_from_name']}
        end
      end

      should 'set order_from_url' do
        url = 'http://www.eummcr.org/order.php'
        assert_equal [url, url], @docs.map {|d| d['order_from_url']}
      end

      should 'set order_from_name' do
        assert_equal ['EUMMCR', 'EUMMCR'], @docs.map {|d| d['order_from_name']}
      end

    end


  end
end
