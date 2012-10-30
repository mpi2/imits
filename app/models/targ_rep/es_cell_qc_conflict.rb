class TargRep::EsCellQcConflict < ActiveRecord::Base
  acts_as_audited

  attr_accessor :nested

  belongs_to :es_cell, :class_name => "TargRep::EsCell"

  validates :es_cell, :presence => true
  validates :qc_field, :presence => true
  validates :proposed_result, :presence => true

  # Stamp the current QC result for the ES Cell if it's not already noted...
  before_create :stamp_qc_result

  private

    def stamp_qc_result
      if conflict.current_result.blank?
        conflict.current_result = conflict.es_cell.attributes[conflict.qc_field.to_s]
      end
    end

end

# == Schema Information
#
# Table name: targ_rep_es_cell_qc_conflicts
#
#  id              :integer         not null, primary key
#  es_cell_id      :integer
#  qc_field        :string(255)     not null
#  current_result  :string(255)     not null
#  proposed_result :string(255)     not null
#  comment         :text
#  created_at      :datetime
#  updated_at      :datetime
#
# Indexes
#
#  es_cell_qc_conflicts_es_cell_id_fk  (es_cell_id)
#

