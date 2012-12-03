class SolrUpdate::Queue::Item < ApplicationModel
  set_table_name 'solr_update_queue_items'

  belongs_to :mi_attempt
  belongs_to :phenotype_attempt
  belongs_to :allele, :class_name => "TargRep::Allele"

  def reference
    if mi_attempt_id
      return {'type' => 'mi_attempt', 'id' => mi_attempt_id}
    elsif phenotype_attempt_id
      return {'type' => 'phenotype_attempt', 'id' => phenotype_attempt_id}
    elsif allele_id
      return {'type' => 'allele', 'id' => allele_id}
    else
      raise SolrUpdate::Error, 'No IDs set'
    end
  end

  def self.add(reference, action)
    if reference.kind_of?(ApplicationModel)
      reference = {'type' => get_model_type(reference), 'id' => reference.id}
    elsif reference.kind_of?(TargRep::Allele)
      reference = {'type' => 'allele', 'id' => reference.id}
    end
      

    fkey = reference['type'] + '_id'

    existing = self.where(fkey => reference['id']).all.first
    if ! existing.blank?
      existing.destroy
    end

    self.create!(fkey => reference['id'], :action => action)
  end

  def self.get_model_type(model)
    if model.kind_of? MiAttempt
      return 'mi_attempt'
    elsif model.kind_of? PhenotypeAttempt
      return 'phenotype_attempt'
    elsif model.kind_of? TargRep::Allele
      return 'allele'
    else
      raise 'unknown model type'
    end
  end
  private_class_method :get_model_type

  def self.process_in_order(args = {})
    args.symbolize_keys!

    self.order('created_at asc').limit(args[:limit]).all.each do |item|
      yield(item)
    end
  end

end

# == Schema Information
#
# Table name: solr_update_queue_items
#
#  id                   :integer         not null, primary key
#  mi_attempt_id        :integer
#  phenotype_attempt_id :integer
#  action               :text
#  created_at           :datetime
#  updated_at           :datetime
#  allele_id            :integer
#
# Indexes
#
#  index_solr_update_queue_items_on_allele_id             (allele_id) UNIQUE
#  index_solr_update_queue_items_on_mi_attempt_id         (mi_attempt_id) UNIQUE
#  index_solr_update_queue_items_on_phenotype_attempt_id  (phenotype_attempt_id) UNIQUE
#

