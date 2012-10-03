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

      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert fetched_docs.blank?, 'docs were not destroyed!'
    end

    context 'when an MI attempt is modified' do
      setup do
        old_strain = Strain.first
        new_strain = Strain.offset(1).first
        es_cell = Factory.create(:es_cell,
          :gene => cbx1,
          :name => 'EPD0027_2_A02',
          :mutation_subtype => 'conditional_ready',
          :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi',
          :allele_id => 902,
          :ikmc_project_id => '35505')

        mi = Factory.create(:mi_attempt_genotype_confirmed,
          :consortium_name => 'BaSH',
          :colony_background_strain => old_strain,
          :es_cell => es_cell)

        pa1 = Factory.create(:phenotype_attempt_status_cec, :mi_attempt => mi)
        pa2 = Factory.create(:phenotype_attempt_status_cec, :mi_attempt => mi)

        SolrUpdate::Queue::Item.destroy_all

        mi.update_attributes!(:colony_background_strain => new_strain)

        @mi_attempt = mi
        @phenotype_attempts = [pa1, pa2]
        @new_strain = new_strain
        @es_cell = es_cell

        SolrUpdate::Queue.run
      end

      should 'update the MI document in SOLR index' do
        mi_doc = {
          'id' => @mi_attempt.id,
          'type' => 'mi_attempt',
          'product_type' => 'Mouse',
          'allele_type' => 'Conditional Ready',
          'allele_id' => 902,
          'mgi_accession_id' => cbx1.mgi_accession_id,
          'strain' => @new_strain.name,
          'allele_name' => @es_cell.allele_symbol,
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/902/allele-image",
          'genbank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/902/escell-clone-genbank-file",
          'order_from_url' => "http://www.komp.org/geneinfo.php?project=CSD35505",
          'order_from_name' => 'KOMP'
        }

        fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
        fetched_docs.each {|d| d.delete('score')}
        assert_equal 1, fetched_docs.size

        fetched_mi_doc = fetched_docs.first

        assert_equal mi_doc, fetched_mi_doc
      end

      should 'update all of the MI\'s phenotype attempt docs in the SOLR index' do
        fetched_docs = @allele_index_proxy.search(:q => 'type:phenotype_attempt')
        ids = fetched_docs.map {|i| i['id']}
        assert_equal @phenotype_attempts.map(&:id).sort, ids.sort
      end
    end

    should 'delete SOLR docs in index for mi_attempts that are deleted from the DB' do
      mi = Factory.create :mi_attempt
      SolrUpdate::Queue.run
      assert_equal 1, @allele_index_proxy.search(:q => 'type:mi_attempt').size

      mi.status_stamps.destroy_all
      mi.destroy
      SolrUpdate::Queue.run
      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert_equal [], fetched_docs
    end

  end
end
