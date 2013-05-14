class AddMiPlanIdToSolrUpdateQueueItems < ActiveRecord::Migration
  def up
    add_column :solr_update_queue_items, :gene_id, :integer

    sql = %Q{
      ALTER TABLE solr_update_queue_items ADD CONSTRAINT solr_update_queue_items_xor_fkeys_newer CHECK (
      (allele_id is NULL AND     mi_attempt_id IS NULL AND     phenotype_attempt_id IS NOT NULL AND gene_id is null) OR
      (allele_id is NULL AND     mi_attempt_id IS NOT NULL AND phenotype_attempt_id IS NULL     AND gene_id is null) OR
      (allele_id is NOT NULL AND mi_attempt_id IS NULL AND     phenotype_attempt_id IS NULL     AND gene_id is null) OR
      (allele_id is NULL AND     mi_attempt_id IS NULL AND     phenotype_attempt_id IS NULL     AND gene_id is not null)
      )
    }

    execute(sql)
    execute('ALTER TABLE solr_update_queue_items DROP CONSTRAINT solr_update_queue_items_xor_fkeys_new;')
  end

  def down
    sql = %Q{
    ALTER TABLE solr_update_queue_items ADD CONSTRAINT solr_update_queue_items_xor_fkeys_new CHECK (
    (allele_id is NULL AND     mi_attempt_id IS NULL AND     phenotype_attempt_id IS NOT NULL) OR
    (allele_id is NULL AND     mi_attempt_id IS NOT NULL AND phenotype_attempt_id IS NULL) OR
    (allele_id is NOT NULL AND mi_attempt_id IS NULL AND     phenotype_attempt_id IS NULL)
    )
    }

    execute(sql)
    execute('ALTER TABLE solr_update_queue_items DROP CONSTRAINT solr_update_queue_items_xor_fkeys_newer;')
    remove_column :solr_update_queue_items, :gene_id
  end
end
