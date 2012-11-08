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

          pp doc

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

      should 'set allele_id' do
        assert_equal 663, @doc['allele_id']
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

      should 'set allele_id' do
        assert_equal 8563, @doc['allele_id']
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
        assert_equal 'http://www.knockoutmouse.org/targ_rep/alleles/8563/allele-image-cre',
                @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal 'http://www.knockoutmouse.org/targ_rep/alleles/8563/escell-clone-cre-genbank-file',
                @doc['genbank_file_url']
      end

      order_from_tests :phenotype_attempt
    end

    context '#set_order_from_details' do

      setup do
        es_cell = Factory.create :es_cell,
                :gene => cbx1,
                :mutation_subtype => 'conditional_ready',
                :allele_id => 663
        @mi_attempt = Factory.create :mi_attempt, :id => 43,
                :colony_background_strain => Strain.create!(:name => 'TEST STRAIN'),
                :es_cell => es_cell

#        distribution_centres_factory = :"mi_attempt_distribution_centre"

        @mi_attempt.es_cell.ikmc_project_id = 'VG10003'

#        @config = YAML.load_file("#{Rails.root}/config/dist_centre_urls.yml")

        @config ={
          "Harwell"=> {:preferred=>"http://www.mousebook.org/searchmousebook.php?query=PROJECT_ID", :default=>"www.Harwell-default.com"},
          "HMGU"=>{:preferred=>"www.HMGU.com?query=MARKER_SYMBOL", :default=>"www.HMGU-default.com"},
          "ICS"=>{:preferred=>"www.ICS.com?query=PROJECT_ID", :default=>"www.ICS-default.com"},
          "CNB"=>{:preferred=>"www.CNB.com?query=PROJECT_ID", :default=>"www.CNB-default.com"},
          "Monterotondo"=>{:preferred=>"www.Monterotondo.com?query=PROJECT_ID", :default=>"www.Monterotondo-default.com"},
          "JAX"=>{:preferred=>"", :default=>"www.JAX-default.com"},
          "WTSI"=> {:preferred=> "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for MARKER_SYMBOL", :default=>"www.WTSI-default.com"},
          "Oulu"=>{:preferred=>"www.Oulu.com?query=PROJECT_ID", :default=>"www.Oulu-default.com"},
          "UCD"=> {:preferred=>"http://www.komp.org/geneinfo.php?project=PROJECT_ID", :default=>"www.UCD-default.com"},
          "VETMEDUNI"=>{:preferred=>"", :default=>"www.VETMEDUNI-default.com"},
          "BCM"=>{:preferred=>"", :default=>"www.BCM-default.com"},
          "CNRS"=>{:preferred=>"www.CNRS.com?query=MARKER_SYMBOL", :default=>"www.CNRS-default.com"},
          "APN"=>{:preferred=>"www.APN.com?query=MARKER_SYMBOL", :default=>"www.APN-default.com"},
          "TCP"=>{:preferred=>"www.TCP.com?query=MARKER_SYMBOL", :default=>"www.TCP-default.com"},
          "MARC"=>{:preferred=>"www.MARC.com?query=MARKER_SYMBOL", :default=>"www.MARC-default.com"},
          "EMMA"=> {:preferred=>"http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL", :default=>"www.EMMA-default.com"}
        }

        mi_attempt_distribution_centre = []
        phenotype_attempt_distribution_centre = []

        @mi_attempt2 = Factory.create :mi_attempt_genotype_confirmed, :es_cell => es_cell

        @phenotype_attempt = Factory.create :phenotype_attempt_status_cec,
                :id => 86, :mi_attempt => @mi_attempt2,
                :colony_background_strain => Strain.create!(:name => 'TEST STRAIN2')

        @config.keys.each do |key|
          Centre.create! :name => key if ! Centre.find_by_name key
          dist_centre = Factory.create :mi_attempt_distribution_centre,
                  :centre => Centre.find_by_name!(key),
                  :is_distributed_by_emma => false, :mi_attempt => @mi_attempt

          dist_centre2 = Factory.create :phenotype_attempt_distribution_centre,
                  :centre => Centre.find_by_name!(key),
                  :is_distributed_by_emma => false, :phenotype_attempt => @phenotype_attempt

          mi_attempt_distribution_centre.push dist_centre
          phenotype_attempt_distribution_centre.push dist_centre2
        end

        @mi_attempt.distribution_centres = mi_attempt_distribution_centre

        @mi_attempt.reload

        #es_cell2 = Factory.create :es_cell,
        #        :gene => cbx1,
        #        :mutation_subtype => 'conditional_ready',
        #        :allele_id => 663

#        @phenotype_attempt.stubs(:allele_symbol).returns('TEST ALLELE SYMBOL2')

        @phenotype_attempt.distribution_centres.destroy_all
      #  pp phenotype_attempt_distribution_centre
        @phenotype_attempt.distribution_centres = phenotype_attempt_distribution_centre

        @phenotype_attempt.reload

      end

      def check_order_details(object)
        doc = {'test_doc' => true}

        SolrUpdate::DocFactory.set_order_from_details(object, doc, @config)

       # puts "#### mi_attempt : #{mi_attempt.distribution_centres.inspect}"
      #  puts "#### doc : #{doc.inspect}"

        hash_check = {}
        doc['orders'].each do |order|
          hash_check[order[:order_from_name]] = order[:order_from_url]
        end

        @config.keys.each do |key|
          if /PROJECT_ID/ =~ @config[key][:preferred]
            if object.es_cell.ikmc_project_id
              assert @config[key][:preferred].gsub(/PROJECT_ID/, object.es_cell.ikmc_project_id), hash_check[key]
            else
              assert @config[key][:default], hash_check[key]
            end
          elsif /MARKER_SYMBOL/ =~ @config[key][:preferred]
            if object.gene.marker_symbol
              assert @config[key][:preferred].gsub(/MARKER_SYMBOL/, object.gene.marker_symbol), hash_check[key]
            else
              assert @config[key][:default], hash_check[key]
            end
          else
            assert @config[key][:default], hash_check[key]
          end
        end

        return hash_check
      end

      should 'manage mi_attempt' do
        check_order_details(@mi_attempt)
      end

      should 'manage phenotype_attempt' do
        check_order_details(@phenotype_attempt)
      end

      should 'default if no marker' do
        #@config = {
        #  "WTSI"=> {:preferred=> "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for MARKER_SYMBOL", :default=>"http://www.example.com"},
        #}

        @mi_attempt.gene.marker_symbol = nil

        hash_check = check_order_details(@mi_attempt)

        #puts "#### hash_check['WTSI'] = #{hash_check['WTSI']}"
        #puts "#### @config['WTSI'][:default] = #{@config['WTSI'][:default]}"
        #
        #pp hash_check

        #assert hash_check['WTSI'].length > 0
        #assert @config['WTSI'][:default].length > 0
        #assert @config['WTSI'][:default] == hash_check['WTSI']

        @config.keys.each do |key|
          if /MARKER_SYMBOL/ =~ @config[key][:preferred]
            assert @config[key][:default].length > 0
            assert hash_check[key].length > 0
            assert @config[key][:default], hash_check[key]
        #    puts "#### #{@config[key][:default]} - #{hash_check[key]}"
          end
        end

      end

      should 'default if no id' do
        @mi_attempt.es_cell.ikmc_project_id = nil

        hash_check = check_order_details(@mi_attempt)

        @config.keys.each do |key|
          if /PROJECT_ID/ =~ @config[key][:preferred]
            assert @config[key][:default].length > 0
            assert hash_check[key].length > 0
            assert @config[key][:default], hash_check[key]
           # puts "#### #{@config[key][:default]} - #{hash_check[key]}"
          end
        end
      end

      should 'not fall over if it cannot find centre in config' do

        @config.delete('WTSI')
        hash_check = check_order_details(@mi_attempt)
 #       pp hash_check

        assert ! hash_check.include?('WTSI')

      end

      should 'handle emma' do

        @mi_attempt.distribution_centres.each do |distribution_centre|
          distribution_centre.is_distributed_by_emma = true
        end

        hash_check = check_order_details(@mi_attempt)
    #    pp hash_check

        assert hash_check.keys.size == 1
        assert_equal hash_check['EMMA'], @config['EMMA'][:preferred].gsub(/MARKER_SYMBOL/, @mi_attempt.gene.marker_symbol)

#        assert ! hash_check.include?('WTSI')

      end
    end

  end
end
