class SolrUpdate::Queue::Item < ActiveRecord::Base
  set_table_name 'solr_update_queue_items'

  belongs_to :mi_attempt
  belongs_to :phenotype_attempt
end

# == Schema Information
#
# Table name: solr_update_queue_items
#
#  id                   :integer         not null, primary key
#  mi_attempt_id        :integer
#  phenotype_attempt_id :integer
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_solr_update_queue_items_on_mi_attempt_id         (mi_attempt_id) UNIQUE
#  index_solr_update_queue_items_on_phenotype_attempt_id  (phenotype_attempt_id) UNIQUE
#

