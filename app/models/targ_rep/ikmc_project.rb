class TargRep::IkmcProject < ActiveRecord::Base

  acts_as_reportable
  extend AccessAssociationByAttribute
  ##
  ## Associations
  ##

  has_many :targeting_vectors, :class_name => "TargRep::TargetingVector", :foreign_key => 'ikmc_project_foreign_id'
  has_many :es_cells, :class_name => "TargRep::EsCell", :foreign_key => 'ikmc_project_foreign_id'
  belongs_to :status, :class_name => "TargRep::IkmcProject::Status"
  belongs_to :pipeline, :class_name => "TargRep::Pipeline"

  access_association_by_attribute :status, :name
  access_association_by_attribute :pipeline, :name
  ##
  ## Validations
  ##

  validates :name,
    :uniqueness => {:message => 'has already been taken'},
    :presence => true
end



# == Schema Information
#
# Table name: targ_rep_ikmc_projects
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  status_id   :integer
#  pipeline_id :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#

