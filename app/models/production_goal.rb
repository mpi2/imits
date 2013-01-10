class ProductionGoal < ActiveRecord::Base
  
  ## Gems/Plugins
  acts_as_audited
  extend AccessAssociationByAttribute
  include ::Public::Serializable
  
  READABLE_ATTRIBUTES = %w(
    year
    month
    mi_goal
    gc_goal
    consortium_name
    consortium_id
  )

  ## Validations
  validates :consortium_id, :presence => true, :uniqueness => {:scope => [:year, :month]}
  validates :year, :presence => true
  validates :month, :presence => true
  validates :mi_goal, :presence => true
  validates :gc_goal, :presence => true

  ## Relationships
  belongs_to :consortium

  access_association_by_attribute :consortium, :name

  attr_accessible :year, :month, :mi_goal, :gc_goal, :consortium_name

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
# Indexes
#
#  index_production_goals_on_consortium_id_and_year_and_month  (consortium_id,year,month) UNIQUE
#

