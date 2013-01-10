class ProductionGoal < ActiveRecord::Base
  
  ## Gems/Plugins
  acts_as_audited

  extend AccessAssociationByAttribute
  
  ## Validations
  validates :year, :presence => true
  validates :month, :presence => true
  validates :mi_goal, :presence => true
  validates :gc_goal, :presence => true

  ## Relationships
  belongs_to :consortium

  access_association_by_attribute :consortium, :name

end

# == Schema Information
#
# Table name: production_goals
#
#  id            :integer         not null, primary key
#  consortium_id :integer
#  year          :integer
#  month         :integer
#  mi_goal       :integer
#  gc_goal       :integer
#  created_at    :datetime
#  updated_at    :datetime
#

