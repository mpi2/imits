require 'test_helper'

class SolrUpdateIntegrationTest < ActiveSupport::TestCase
  context 'SOLR update system' do

    setup do
      @allele_index_proxy = SolrUpdate::IndexProxy::Allele.new

      commands = {}
      commands['delete'] = {'query' => '*:*'}
      commands['commit'] = {}
      commands_json = commands.to_json
      @allele_index_proxy.update(commands_json)

      fetched_docs = @allele_index_proxy.search(:q => '*:*')
      assert fetched_docs.blank?, 'docs were not destroyed!'

      old_strain = Strain.first
      new_strain = Strain.offset(1).first
      allele = Factory.create(:allele, :gene => cbx1)
      es_cell = Factory.create(:es_cell,
      :allele => allele,
      :name => 'EPD0027_2_A02',
      :mutation_subtype => 'conditional_ready',
      :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi',
      :allele => allele,
      :ikmc_project_id => '35505')

      mi = Factory.create(:mi_attempt2_status_gtc,
      :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => es_cell.gene, :force_assignment => true),
      :colony_background_strain => old_strain,
      :es_cell => es_cell)

      pa1 = Factory.create(:phenotype_attempt_status_cec,
      :mi_attempt => mi,
      :colony_background_strain => old_strain)
      pa2 = Factory.create(:phenotype_attempt_status_cec,
      :mi_attempt => mi,
      :colony_background_strain => old_strain)

      SolrUpdate::Queue::Item.destroy_all

      @mi_attempt = mi
      @phenotype_attempts = [pa1, pa2]
      @new_strain = new_strain
      @allele = allele
      @es_cell = es_cell
    end

    context 'when an MI attempt is modified' do
      setup do
        @mi_attempt.update_attributes!(:colony_background_strain => @new_strain)

# Not needed because default distribution centre is made for te production centre.
#        dist_centre = Factory.create :mi_attempt_distribution_centre,
#       :centre => Centre.find_by_name!('WTSI'),
#        :is_distributed_by_emma => false, :mi_attempt => @mi_attempt
#        @mi_attempt.distribution_centres = [dist_centre]

        SolrUpdate::Queue.run
      end

      should_if_solr 'update the MI document in SOLR index' do
        mi_doc = {
          'id' => @mi_attempt.id,
          'type' => 'mi_attempt',
          'product_type' => 'Mouse',
          'allele_type' => 'Conditional Ready',
          'allele_id' => @allele.id,
          'mgi_accession_id' => cbx1.mgi_accession_id,
          'strain' => @new_strain.name,
          'allele_name' => @mi_attempt.allele_symbol,
          'allele_image_url' => "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/allele-image",
          'genbank_file_url' => "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file",
          'order_from_urls' => ["mailto:mouseinterest@sanger.ac.uk?subject=Mutant mouse for Cbx1"],
          'order_from_names' => ['WTSI'],
          'best_status_pa_cre_ex_not_required' => '',
          'best_status_pa_cre_ex_required' => 'Cre Excision Complete',
          'current_pa_status'=>'',
          'simple_allele_image_url' => 'https://www.i-dcc.org/imits/targ_rep/alleles/1/allele-image?simple=true',
          'colony_name' => 'WTSI-EPD0027_2_A02-1',
          'production_centre' => 'WTSI',
          'es_cell_name' => 'EPD0027_2_A02',
          'marker_symbol' => 'Cbx1',
          'project_ids' => ['35505'],
          "allele_has_issue" => false
        }

        fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
        fetched_docs.each {|d| d.delete('score')}
        assert_equal 1, fetched_docs.size

        fetched_mi_doc = fetched_docs.first

        assert_equal mi_doc, fetched_mi_doc
      end

      should_if_solr 'update all of the MI\'s phenotype attempt docs in the SOLR index' do
        if Rails.configuration.enable_solr_phenotype_attempt
          fetched_docs = @allele_index_proxy.search(:q => 'type:phenotype_attempt')
          ids = fetched_docs.map {|i| i['id']}
          assert_equal @phenotype_attempts.map(&:id).sort, ids.sort
        end
      end
    end

    #should_if_solr 'delete SOLR docs in index for mi_attempts that are deleted from the DB' do
    should_eventually 'delete SOLR docs in index for mi_attempts that are deleted from the DB' do
      mi = Factory.create :mi_attempt2_status_gtc
      SolrUpdate::Queue.run
      assert_equal 1, @allele_index_proxy.search(:q => 'type:mi_attempt').size

      mi.reload
      mi.status_stamps.reload

      #puts "#### mi:"
      #pp mi
      #puts "#### mi.status_stamps:"
      #pp mi.status_stamps

      mi.status_stamps.destroy_all
      mi.reload

      #puts "#### mi.status_stamps 2:"
      #pp mi.status_stamps

      mi.destroy
      SolrUpdate::Queue.run
      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert_equal [], fetched_docs
    end

    should_if_solr 'update a modified phenotype_attempt doc in the SOLR index' do
      if Rails.configuration.enable_solr_phenotype_attempt
        phenotype_attempt = @phenotype_attempts.first

        phenotype_attempt.update_attributes!(:colony_background_strain => @new_strain)
        SolrUpdate::Queue.run

        pa_doc = {
          'id' => phenotype_attempt.id,
          'allele_has_issue' => false,
          'type' => 'phenotype_attempt',
          'product_type' => 'Mouse',
          'allele_type' => 'Cre-excised Reporter-tagged deletion (tm1b)',
          'allele_id' => @allele.id,
          'mgi_accession_id' => cbx1.mgi_accession_id,
          'strain' => @new_strain.name,
          'allele_name' => phenotype_attempt.allele_symbol,
          'allele_image_url' => "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/allele-image-cre",
          'genbank_file_url' => "https://www.i-dcc.org/imits/targ_rep/alleles/#{@allele.id}/escell-clone-cre-genbank-file",
          'best_status_pa_cre_ex_not_required' => '',
          'best_status_pa_cre_ex_required' => 'Cre Excision Complete',
          'current_pa_status' => 'Cre Excision Complete',
          'simple_allele_image_url' => 'https://www.i-dcc.org/imits/targ_rep/alleles/1/allele-image-cre?simple=true',
          'production_centre' => 'WTSI',
          'marker_symbol' => 'Cbx1',
          'colony_name' => 'WTSI-EPD0027_2_A02-1-1',
          'parent_mi_attempt_colony_name' => 'WTSI-EPD0027_2_A02-1',
          'project_ids' => ['35505']
        }

        fetched_docs = @allele_index_proxy.search(:q => 'type:phenotype_attempt')
        fetched_docs.each {|d| d.delete('score')}
        assert_equal 1, fetched_docs.size

        fetched_pa_doc = fetched_docs.first

        assert_equal pa_doc, fetched_pa_doc
      end
    end

    should_if_solr 'delete a deleted phenotype_attempt from the SOLR index' do
      if Rails.configuration.enable_solr_phenotype_attempt
        phenotype_attempt = @phenotype_attempts.first
        phenotype_attempt.update_attributes!(:colony_background_strain => @new_strain)

        SolrUpdate::Queue.run
        assert_equal 1, @allele_index_proxy.search(:q => 'type:phenotype_attempt').size

        phenotype_attempt.status_stamps.destroy_all
        phenotype_attempt.distribution_centres.destroy_all
        phenotype_attempt.destroy
        SolrUpdate::Queue.run
        fetched_docs = @allele_index_proxy.search(:q => 'type:phenotype_attempt')
        assert_equal [], fetched_docs
      end
    end

    should_if_solr 'update an mi_plan`s mi_attempt solr docs if the mi_plan changes' do
      plan = @mi_attempt.mi_plan
      plan.update_attributes!(:number_of_es_cells_starting_qc => 4)
      SolrUpdate::Queue.run
      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert_equal [@mi_attempt.id], fetched_docs.map{|i| i['id']}
    end

    should_if_solr 'update a gene`s mi_attempt solr docs if the gene changes' do
      gene = @mi_attempt.gene
      gene.update_attributes!(:ikmc_projects_count => gene.ikmc_projects_count.to_i + 1)
      SolrUpdate::Queue.run
      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert_equal [@mi_attempt.id], fetched_docs.map{|i| i['id']}
    end

    should_if_solr 'update an es_cell`s mi_attempt solr docs if the es_cell changes' do
      es_cell = @mi_attempt.es_cell
      es_cell.update_attributes!(:parental_cell_line => 'JM8.P6')
      SolrUpdate::Queue.run
      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert_equal [@mi_attempt.id], fetched_docs.map{|i| i['id']}
    end

  end
end
