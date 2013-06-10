class TargRep::IkmcProject::Status < ActiveRecord::Base

  acts_as_reportable

  ##
  ## Associations
  ##

  has_many :ikmc_projects, :class_name => "TargRep::IkmcProject"

  ##
  ## Validations
  ##

  validates :name,
    :uniqueness => {:message => 'has already been taken'},
    :presence => true
end

# == Schema Information
#
# Table name: targ_rep_ikmc_project_statuses
#
#  id   :integer         not null, primary key
#  name :string(255)
#

