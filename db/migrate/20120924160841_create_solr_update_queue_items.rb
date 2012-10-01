class CreateSolrUpdateQueueItems < ActiveRecord::Migration
  def self.up
    create_table :solr_update_queue_items do |table|
      table.integer :mi_attempt_id
      table.integer :phenotype_attempt_id
      table.column :action, :text

      table.timestamps
    end
    add_index :solr_update_queue_items, :mi_attempt_id, :unique => true
    add_index :solr_update_queue_items, :phenotype_attempt_id, :unique => true
    execute('ALTER TABLE solr_update_queue_items ADD CONSTRAINT solr_update_queue_items_xor_fkeys CHECK ((mi_attempt_id IS NULL AND phenotype_attempt_id IS NOT NULL) OR (mi_attempt_id IS NOT NULL AND phenotype_attempt_id IS NULL))')
    execute("ALTER TABLE solr_update_queue_items ADD CONSTRAINT solr_update_queue_items_action CHECK (action IN ('update', 'delete') )")
  end

  def self.down
    drop_table :solr_update_queue_items
  end
end
