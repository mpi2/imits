class TargRep::Pipeline < ActiveRecord::Base

  acts_as_reportable

  self.include_root_in_json = false

  ##
  ## Associations
  ##

  has_many :targeting_vectors, :class_name => "TargRep::TargetingVector"
  has_many :es_cells, :class_name => "TargRep::EsCell"
  has_many :ikmc_projects, :class_name => "TargRep::IkmcProject"
  ##
  ## Validations
  ##

  validates :name,
    :uniqueness => {:message => 'has already been taken'},
    :presence => true

  scope :targeted, where(:gene_trap => false)
  scope :gene_trap, where(:gene_trap => true)

end

# == Schema Information
#
# Table name: targ_rep_pipelines
#
#  id               :integer         not null, primary key
#  name             :string(255)     not null
#  description      :string(255)
#  created_at       :datetime        not null
#  updated_at       :datetime        not null
#  legacy_id        :integer
#  report_to_public :boolean         default(TRUE)
#  gene_trap        :boolean         default(FALSE)
#
# Indexes
#
#  index_targ_rep_pipelines_on_name  (name) UNIQUE
#

