class EsCellQc::StatusStamp < ActiveRecord::Base
  acts_as_reportable

  validates :es_cell_qc, :presence => true
  validates :status, :presence => true

  validates_uniqueness_of :status_id, :scope => :es_cell_qc_id
end
