#!/usr/bin/env ruby

ApplicationModel.audited_transaction do

  es_cells = EsCell.find_all_by_allele_id(0)
  es_cells.each do |es_cell|
    mi_attempts = es_cell.mi_attempts
    mi_attempts.each do |mi|
      phenotype_attempts = mi.phenotype_attempts

      reference = {'type' => 'mi_attempt', 'id' => mi.id}
      SolrUpdate::Queue.enqueue_for_delete(reference)
      Rails.logger.info "Created item in SolrUpdate queue for deletion: Deleting mi_attempt '#{mi.id}' from solr index"
      puts "delete mi_attempt mi.id"

      phenotype_attempts.each do |pa|
        reference = {'type' => 'phenotype_attempt', 'id' => pa.id}
        SolrUpdate::Queue.enqueue_for_delete(reference)
        Rails.logger.info "Created item in SolrUpdate queue for deletion: Deleting phenotype_attempt '#{mi.id}' from solr index"
        puts "delete phenotype_attempt pa.id"
      end
    end
  end
raise "ROLLBACK"
end