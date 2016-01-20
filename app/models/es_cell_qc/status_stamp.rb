class EsCellQc::StatusStamp < ActiveRecord::Base
  acts_as_reportable

  validates :es_cell_qc, :presence => true
  validates :status, :presence => true

  validates_uniqueness_of :status_id, :scope => :es_cell_qc_id
end

# == Schema Information
#
# Table name: es_cell_qc_status_stamps
#
#  id            :integer          not null, primary key
#  es_cell_qc_id :integer          not null
#  status_id     :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
