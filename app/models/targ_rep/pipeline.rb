class TargRep::Pipeline < ActiveRecord::Base

  self.include_root_in_json = false

  ##
  ## Associations
  ##

  has_many :targeting_vectors, :dependent => :destroy, :class_name => "TargRep::TargetingVector"
  has_many :es_cells, :dependent => :destroy, :class_name => "TargRep::EsCell"

  ##
  ## Validations
  ##

  validates :name,
    :uniqueness => {:message => 'This pipeline name has already been taken'},
    :presence => true


end

# == Schema Information
#
# Table name: targ_rep_pipelines
#
#  id          :integer         not null, primary key
#  name        :string(255)     not null
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#

