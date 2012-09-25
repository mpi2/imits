class SolrUpdate::Queue::Item < ActiveRecord::Base
  set_table_name 'solr_update_queue_items'

  belongs_to :mi_attempt
  belongs_to :phenotype_attempt

  def self.add(object_id, command_type)
    if object_id.kind_of?(ApplicationModel)
      add_model(object_id, command_type)
    else
      fkey = object_id['type'] + '_id'
      self.create!(fkey => object_id['id'], :command_type => command_type)
    end
  end

  def self.add_model(model, command_type)
    if model.kind_of? MiAttempt
      self.create!(:mi_attempt_id => model.id, :command_type => command_type)
    elsif model.kind_of? PhenotypeAttempt
      self.create!(:phenotype_attempt_id => model.id, :command_type => command_type)
    else
      raise 'unknown model type'
    end
  end
  private_class_method :add_model

  def self.process_in_order
    self.order('created_at asc').all.each do |item|
      if item.mi_attempt_id
        object_id = {'type' => 'mi_attempt', 'id' => item.mi_attempt_id}
      elsif item.phenotype_attempt_id
        object_id = {'type' => 'phenotype_attempt', 'id' => item.phenotype_attempt_id}
      end
      yield([object_id, item.command_type])
      item.destroy
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
#  command_type         :text
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_solr_update_queue_items_on_mi_attempt_id         (mi_attempt_id) UNIQUE
#  index_solr_update_queue_items_on_phenotype_attempt_id  (phenotype_attempt_id) UNIQUE
#

