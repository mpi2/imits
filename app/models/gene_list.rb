class GeneList < ActiveRecord::Base
  acts_as_reportable

  has_many :gene_assignments
  has_many :current_assigned_gene_assignments, :class_name => "GeneAssignment", :conditions =>  "assigned = true"

  validates :name, :presence => true, :uniqueness => true
end
