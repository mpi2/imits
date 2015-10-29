class GeneAssignment::Status < ActiveRecord::Base
  acts_as_reportable

  has_many :gene_assignments
  has_many :status_stamps, class_name => 'GeneAssignment::StatusStamps'

  validates :name, :presence => true, :uniqueness => true
end
