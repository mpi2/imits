class GeneAssignment::StatusStamp < ActiveRecord::Base
  acts_as_reportable

  belongs_to :status, :class_name => 'GeneAssignment::Status'
  belongs_to :gene_assignment
  
  validates :gene_assignment, :presence => true
  validates :status, :presence => true

  validates_uniqueness_of :status_id, :scope => :gene_assignment_id
end
