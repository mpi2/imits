class AddAlleleIndexOnSolrUpdateQueueItems < ActiveRecord::Migration
  def self.up
    add_index :solr_update_queue_items, :allele_id, :unique => true

    execute('ALTER TABLE solr_update_queue_items ADD CONSTRAINT solr_update_queue_items_xor_fkeys_new CHECK ((allele_id is NULL AND mi_attempt_id IS NULL AND phenotype_attempt_id IS NOT NULL) OR (allele_id is NULL AND mi_attempt_id IS NOT NULL AND phenotype_attempt_id IS NULL) OR (allele_id is NOT NULL AND mi_attempt_id IS NULL AND phenotype_attempt_id IS NULL))')
    execute('ALTER TABLE solr_update_queue_items DROP CONSTRAINT solr_update_queue_items_xor_fkeys;')
  end

  def self.down
    remove_index :solr_update_queue_items, :allele_id
    execute('ALTER TABLE solr_update_queue_items ADD CONSTRAINT solr_update_queue_items_xor_fkeys CHECK ((mi_attempt_id IS NULL AND phenotype_attempt_id IS NOT NULL) OR (mi_attempt_id IS NOT NULL AND phenotype_attempt_id IS NULL))')
    execute('ALTER TABLE solr_update_queue_items DROP CONSTRAINT solr_update_queue_items_xor_fkeys_new;')
  end
end
