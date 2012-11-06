class AddAlleleIdToSolrUpdateQueueItem < ActiveRecord::Migration
  def self.up
    add_column :solr_update_queue_items, :allele_id, :integer
  end

  def self.down
    remove_column :solr_update_queue_items, :allele_id
  end
end
