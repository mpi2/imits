require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase

  def setup_fake_unique_public_info(list_of_params)
    replacement = list_of_params.map do |params|
      {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi'}.merge(params)
    end

    @fake_unique_public_info.replace replacement
  end

  context 'SolrUpdate::DocFactory' do

    context '#create' do
      should 'work when reference type is mi_attempt' do
        mi = Factory.create :mi_attempt2
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
        @mi_attempt = Factory.create :mi_attempt2, :id => 43,
        :colony_background_strain => Strain.create!(:name => 'TEST STRAIN'),
        :es_cell => @es_cell,
        :mi_plan => bash_wtsi_cbx1_plan
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
        assert_equal "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/allele-image",
        @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file",
        @doc['genbank_file_url']
      end
    end

    context 'when creating solr docs for phenotype_attempt' do

      setup do
        @allele = Factory.create(:allele, :gene => cbx1)
        @es_cell = Factory.create :es_cell,
        :allele => @allele,
        :mutation_subtype => 'conditional_ready'

        @mi_attempt = Factory.create :mi_attempt2_status_gtc,
        :es_cell => @es_cell,
        :mi_plan => bash_wtsi_cbx1_plan

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
          assert_equal 'Cre-excised deletion (tm1b)', doc['allele_type']
        end

        should 'be Cre Excised Deletion if mouse_allele_type is .1' do
          @phenotype_attempt.mouse_allele_type = '.1'
          doc = SolrUpdate::DocFactory.create_for_phenotype_attempt(@phenotype_attempt).first
          assert_equal 'Cre-excised deletion (tm1.1)', doc['allele_type']
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
        assert_equal "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/allele-image-cre",
        @doc['allele_image_url']
      end

      should 'set genbank_file_url' do
        assert_equal "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/escell-clone-cre-genbank-file",
        @doc['genbank_file_url']
      end
    end

    context 'when creating solr docs for allele' do

      setup do
        @gene = Factory.create :gene, :mgi_accession_id => 'MGI:9999999991', :marker_symbol => 'Test1'
        @allele = Factory.create :allele, :mutation_type => TargRep::MutationType.find_by_code!('crd'), :gene => @gene

        @fake_unique_public_info = [
          {:strain => 'C57BL/6N', :mgi_allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi', :pipeline => 'EUCOMM'},
          {:strain => 'C57BL/6N-A<tm1Brd>/a', :mgi_allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi', :pipeline => 'EUCOMMTools'}
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
        url = "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/allele-image"
        assert_equal [url, url], @docs.map {|d| d['allele_image_url']}
      end

      should 'set genbank_file_url' do
        url = "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file"
        assert_equal [url, url], @docs.map {|d| d['genbank_file_url']}
      end

      should 'set simple_allele_image_url' do
        url = "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/allele-image?simple=true"
        assert_equal [url, url], @docs.map {|d| d['simple_allele_image_url']}
      end

      context 'order_from_urls and order_from_names' do
        should 'be set for any of the EUCOMM pipelines' do
          expected_url = ['http://www.eummcr.org/order.php']
          expected_name = ['EUMMCR']

          setup_fake_unique_public_info [
            {:pipeline => 'EUCOMM'},
            {:pipeline => 'EUCOMMTools'},
            {:pipeline => 'EUCOMMToolsCre'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*3, @docs.map {|d| d['order_from_urls']}
          assert_equal [expected_name]*3, @docs.map {|d| d['order_from_names']}
        end

        should 'work for one of the KOMP pipelines without a valid project id' do
          expected_url = ['http://www.komp.org/geneinfo.php?project=CSD123']
          expected_name = ['KOMP']

          setup_fake_unique_public_info [
            {:pipeline => 'KOMP-CSD', :ikmc_project_id => '123'},
            {:pipeline => 'KOMP-Regeneron', :ikmc_project_id => '123'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for one of the KOMP pipelines with a valid project id' do
          expected_url = ['http://www.komp.org/geneinfo.php?project=VG10003']
          expected_name = ['KOMP']

          setup_fake_unique_public_info [
            {:ikmc_project_id => 'VG10003', :pipeline => 'KOMP-CSD'},
            {:ikmc_project_id => 'VG10003', :pipeline => 'KOMP-Regeneron'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for one of the KOMP pipelines with NO project id' do
          expected_url = ['http://www.komp.org/']
          expected_name = ['KOMP']

          setup_fake_unique_public_info [
            {:pipeline => 'KOMP-CSD'},
            {:pipeline => 'KOMP-Regeneron'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for mirKO or Sanger MGP pipelines' do
          expected_url = ['mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for Test1']
          expected_name = ['Wtsi']

          setup_fake_unique_public_info [
            {:pipeline => 'mirKO'},
            {:pipeline => 'Sanger MGP'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for one of the NorCOMM pipeline' do
          expected_url = ['http://www.phenogenomics.ca/services/cmmr/escell_services.html']
          expected_name = ['NorCOMM']

          setup_fake_unique_public_info [
            {:pipeline => 'NorCOMM'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url], @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name], @docs.map{|d| d['order_from_names']}
        end
      end

      should 'set order_from_url' do
        url = ['http://www.eummcr.org/order.php']
        assert_equal [url, url], @docs.map {|d| d['order_from_urls']}
      end

      should 'set order_from_name' do
        assert_equal [['EUMMCR'], ['EUMMCR']], @docs.map {|d| d['order_from_names']}
      end
    end

    context '#set_order_from_details' do

      setup do

        allele = Factory.create(:allele, :gene => cbx1)

        es_cell = Factory.create :es_cell,
        :allele => allele,
        :mutation_subtype => 'conditional_ready'

        @mi_attempt = Factory.create :mi_attempt2, :id => 43,
        :colony_background_strain => Strain.create!(:name => 'TEST STRAIN'),
        :es_cell => es_cell,
        :mi_plan => bash_wtsi_cbx1_plan

        @mi_attempt.es_cell.ikmc_project_id = 'VG10003'

        @config ={
          "Harwell"=> {:preferred=>"http://www.mousebook.org/searchmousebook.php?query=PROJECT_ID", :default=>"www.Harwell-default.com"},
          "HMGU"=>{:preferred=>"www.HMGU.com?query=MARKER_SYMBOL", :default=>"www.HMGU-default.com"},
          "ICS"=>{:preferred=>"www.ICS.com?query=PROJECT_ID", :default=>"www.ICS-default.com"},
          "CNB"=>{:preferred=>"www.CNB.com?query=PROJECT_ID", :default=>"www.CNB-default.com"},
          "Monterotondo"=>{:preferred=>"www.Monterotondo.com?query=PROJECT_ID", :default=>"www.Monterotondo-default.com"},
          "JAX"=>{:preferred=>"www.JAX.com/whatever", :default=>"www.JAX-default.com"},
          "WTSI"=> {:preferred=> "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for MARKER_SYMBOL", :default=>"www.WTSI-default.com"},
          "Oulu"=>{:preferred=>"www.Oulu.com?query=PROJECT_ID", :default=>"www.Oulu-default.com"},
          "VETMEDUNI"=>{:preferred=>"www.VETMEDUNI.com/stuff", :default=>"www.VETMEDUNI-default.com"},
          "BCM"=>{:preferred=>"www.BCM.com/something", :default=>"www.BCM-default.com"},
          "CNRS"=>{:preferred=>"www.CNRS.com?query=MARKER_SYMBOL", :default=>"www.CNRS-default.com"},
          "APN"=>{:preferred=>"www.APN.com?query=MARKER_SYMBOL", :default=>"www.APN-default.com"},
          "TCP"=>{:preferred=>"www.TCP.com?query=MARKER_SYMBOL", :default=>"www.TCP-default.com"},
          "MARC"=>{:preferred=>"www.MARC.com?query=MARKER_SYMBOL", :default=>"www.MARC-default.com"},
          "EMMA"=> {:preferred=>"http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL", :default=>"www.EMMA-default.com"},
          "KOMP"=>{:preferred=>"whatever.com/PROJECT_ID", :default=>"www.something.com"},
        }

        mi_attempt_distribution_centre = []
        phenotype_attempt_distribution_centre = []

        @mi_attempt2 = Factory.create :mi_attempt2_status_gtc, :es_cell => es_cell, :mi_plan => bash_wtsi_cbx1_plan

        @phenotype_attempt = Factory.create :phenotype_attempt_status_cec,
        :id => 86, :mi_attempt => @mi_attempt2,
        :colony_background_strain => Strain.create!(:name => 'TEST STRAIN2')

        @config.keys.each do |key|
          next if key == 'EMMA'
          next if key == 'KOMP'
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

        @phenotype_attempt.distribution_centres.destroy_all
        @phenotype_attempt.distribution_centres = phenotype_attempt_distribution_centre

        @phenotype_attempt.reload
      end

      def check_order_details(object)
        doc = {'test_doc' => true}

        SolrUpdate::DocFactory.set_order_from_details(object, doc, @config)

        hash_check = {}
        counter = 0
        assert_equal doc['order_from_names'].size, doc['order_from_urls'].size
        doc['order_from_names'].each do |order_from_names|
          hash_check[order_from_names] = doc['order_from_urls'][counter]
          counter += 1
        end

        @config.keys.each do |key|
          next if key == 'EMMA'
          next if key == 'KOMP'
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
        @mi_attempt.gene.marker_symbol = nil

        hash_check = check_order_details(@mi_attempt)

        @config.keys.each do |key|
          next if key == 'EMMA'
          next if key == 'KOMP'
          if /MARKER_SYMBOL/ =~ @config[key][:preferred]
            assert @config[key][:default].length > 0
            assert hash_check[key].length > 0
            assert @config[key][:default], hash_check[key]
          end
        end

      end

      should 'default if no project id' do
        @mi_attempt.es_cell.ikmc_project_id = nil

        hash_check = check_order_details(@mi_attempt)

        @config.keys.each do |key|
          next if key == 'EMMA'
          next if key == 'KOMP'
          if /PROJECT_ID/ =~ @config[key][:preferred]
            assert @config[key][:default].length > 0
            assert hash_check[key].length > 0
            assert @config[key][:default], hash_check[key]
          end
        end
      end

      should 'not fall over if it cannot find centre in config' do
        @config.delete('WTSI')
        hash_check = check_order_details(@mi_attempt)
        assert ! hash_check.include?('WTSI')
      end

      should 'handle emma' do
        @mi_attempt.distribution_centres.each do |distribution_centre|
          distribution_centre.is_distributed_by_emma = true
        end

        hash_check = check_order_details(@mi_attempt)

        assert hash_check.keys.size == 1
        assert_equal hash_check['EMMA'], @config['EMMA'][:preferred].gsub(/MARKER_SYMBOL/, @mi_attempt.gene.marker_symbol)
      end

      should 'manage expired dates' do
        @mi_attempt.distribution_centres.each do |distribution_centre|
          distribution_centre.end_date = Time.now - 1.day
        end

        hash_check = check_order_details(@mi_attempt)
        assert_equal 0, hash_check.keys.size
      end

      should 'manage future end dates' do
        @mi_attempt.distribution_centres.each do |distribution_centre|
          distribution_centre.end_date = Time.now + 1.day
        end

        hash_check = check_order_details(@mi_attempt)
        assert_equal @config.keys.size-2, hash_check.keys.size
      end

      should 'manage null dates' do
        @mi_attempt.distribution_centres.each do |distribution_centre|
          distribution_centre.start_date = nil
          distribution_centre.end_date = nil
        end

        hash_check = check_order_details(@mi_attempt)
        assert_equal @config.keys.size-2, hash_check.keys.size
      end

      should 'manage empty config file fields (i.e. config file centres have an entry but that entry is set to empty string)' do
        config = @config

        @config = {
          "Harwell"=> {:preferred=>"http://www.mousebook.org/searchmousebook.php?query=PROJECT_ID", :default=>"www.Harwell-default.com"},
          "HMGU"=>{:preferred=>"", :default=>"www.HMGU-default.com"},
          "EMMA"=> {:preferred=>"http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL", :default=>"www.EMMA-default.com"},
          "KOMP"=>{:preferred=>"whatever.com/PROJECT_ID", :default=>"www.something.com"}
        }

        hash_check = check_order_details(@mi_attempt)
        assert_equal 1, hash_check.keys.size

        @config = config
      end

      should 'manage both empty config file fields (i.e. config file centres have an entry but that entry is set to empty string)' do
        config = @config

        @config = {
          "Harwell"=> {:preferred=>"", :default=>""},
          "HMGU"=>{:preferred=>"", :default=>""},
          "KOMP"=>{:preferred=>"whatever.com/PROJECT_ID", :default=>"www.KOMP-default.com"},
          "EMMA"=> {:preferred=>"http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL", :default=>"www.EMMA-default.com"}
        }

        hash_check = check_order_details(@mi_attempt)

        assert_equal 0, hash_check.keys.size

        @config = config
      end

      should 'flip to KOMP if UCD found' do
        config = @config

        @config = {
          "KOMP"=>{:preferred=>"whatever.com/PROJECT_ID", :default=>"www.something.com"},
          "EMMA"=> {:preferred=>"http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL", :default=>"www.EMMA-default.com"}
        }

        allele = Factory.create(:allele, :gene => cbx1)

        es_cell = Factory.create :es_cell,
        :allele => allele,
        :mutation_subtype => 'conditional_ready',
        :ikmc_project_id => 'VG10003'

        mi_attempt = Factory.create :mi_attempt2, :id => 433,
        :colony_background_strain => Strain.create!(:name => 'TEST STRAIN 2'),
        :es_cell => es_cell, :mi_plan => bash_wtsi_cbx1_plan

        dist_centre = Factory.create :mi_attempt_distribution_centre,
        :centre => Centre.find_by_name!('UCD'),
        :is_distributed_by_emma => false, :mi_attempt => mi_attempt

        mi_attempt.distribution_centres = [dist_centre]

        hash_check = check_order_details(mi_attempt)

        assert_equal 1, hash_check.keys.size
        assert @config["KOMP"][:preferred].gsub(/PROJECT_ID/, mi_attempt.es_cell.ikmc_project_id), hash_check["KOMP"]

        @config = config
      end

      should 'raise exception if config doesn\'t contain KOMP' do
        config = @config
        @config = {
          "EMMA"=> {:preferred=>"http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL", :default=>"www.EMMA-default.com"}
        }

        assert_raise RuntimeError do
          check_order_details(@mi_attempt)
        end

        @config = config
      end

      should 'raise exception if config doesn\'t contain EMMA' do
        config = @config
        @config = {
          "KOMP"=>{:preferred=>"whatever.com/PROJECT_ID", :default=>"www.something.com"}
        }

        assert_raise RuntimeError do
          check_order_details(@mi_attempt)
        end

        @config = config
      end
    end

  end
end
