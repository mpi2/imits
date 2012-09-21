require 'test_helper'

class SolrUpdateIntegrationTest < ActiveSupport::TestCase
  context 'SOLR update system' do

    setup do
      @allele_index_proxy = SolrUpdate::IndexProxy::Allele.new

      # TODO Make this with a 'CommandFactory' or something
      commands = ActiveSupport::OrderedHash.new
      commands['delete'] = {'query' => '*:*'}
      commands['commit'] = {}
      commands_json = commands.to_json
      @allele_index_proxy.update(commands_json)

      fetched_docs = @allele_index_proxy.search(:q => 'type:mi_attempt')
      assert fetched_docs.blank?, 'docs were not destroyed!'
    end

    should 'update the SOLR index when an mi_attempt is modified' do
      old_strain = Strain.first
      new_strain = Strain.offset(1).first
      es_cell = Factory.create(:es_cell,
        :gene => cbx1,
        :name => 'EPD0027_2_A02',
        :mutation_subtype => 'conditional_ready',
        :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi',
        :ikmc_project_id => '35505')

      mi = Factory.create(:mi_attempt,
        :colony_background_strain => old_strain,
        :es_cell => es_cell)

      SolrUpdate::Queue::Item.destroy_all

      mi.update_attributes!(:colony_background_strain => new_strain)

      doc = {
        'id' => mi.id,
        'type' => 'mi_attempt',
        'product_type' => 'Mouse',
        'allele_type' => 'Conditional Ready',
        'mgi_accession_id' => cbx1.mgi_accession_id,
        'strain' => new_strain.name,
        'allele_name' => es_cell.allele_symbol,
        'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/902/allele-image",
        'genbank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/902/escell-clone-genbank-file",
        'order_from_url' => "http://www.komp.org/geneinfo.php?project=CSD#{es_cell.ikmc_project_id}",
        'order_from_name' => 'KOMP'
      }

      SolrUpdate::Queue.run

      fetched_docs = @allele_index_proxy.search(:q => 'type:allele')
      fetched_docs.each {|d| d.delete('score')}
      assert_equal 1, fetched_docs.size

      fetched_doc = fetched_docs.first

      doc.keys.each do |key|
        assert_equal doc[key], fetched_doc[key], "#{key} expected to be #{doc[key]}, but was #{fetched_doc[key]}"
      end

      assert_equal doc, fetched_doc
    end

    should 'delete SOLR docs in index for mi_attempts that are deleted from the DB'

  end
end
