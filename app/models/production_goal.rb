class ProductionGoal < ActiveRecord::Base

  ## Gems/Plugins
  acts_as_audited
  extend AccessAssociationByAttribute
  include ::Public::Serializable


  PRIVATE_ATTRIBUTES = %w{
  }

  READABLE_ATTRIBUTES = %w(
    id
    year
    month
    mi_goal
    gc_goal
    crispr_mi_goal
    crispr_gc_goal
    total_mi_goal
    total_gc_goal
    consortium_name
    consortium_id
  )

  attr_accessible *READABLE_ATTRIBUTES

  before_save :calculate_totals

  ## Validations
  validates :consortium_id, :presence => true, :uniqueness => {:scope => [:year, :month]}
  validates :year, :presence => true, :numericality => {:greater_than => 2010, :less_than => 2050}
  validates :month, :presence => true, :numericality => {:less_than => 13, :greater_than => 0}

  validate do |pg|
    if pg.mi_goal.nil? && pg.crispr_mi_goal.nil?
      pg.errors.add :base, 'An MI Goal must be entered (either for ES Cell or CRIPSR)'
    end

    if pg.gc_goal.nil? && pg.crispr_gc_goal.nil?
      pg.errors.add :base, 'An GC Goal must be entered (either for ES Cell or CRIPSR)'
    end
  end

  ## Relationships
  belongs_to :consortium

  access_association_by_attribute :consortium, :name



  def calculate_totals
    self.total_mi_goal = (self.mi_goal.blank? ? 0 : self.mi_goal) + (self.crispr_mi_goal.blank? ? 0 : self.crispr_mi_goal)
    self.total_gc_goal = (self.gc_goal.blank? ? 0 : self.gc_goal) + (self.crispr_gc_goal.blank? ? 0 : self.crispr_gc_goal)
  end

  def self.readable_name
    return 'production goal'
  end

end

# == Schema Information
#
# Table name: production_goals
#
#  id             :integer          not null, primary key
#  consortium_id  :integer
#  year           :integer
#  month          :integer
#  mi_goal        :integer
#  gc_goal        :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  crispr_mi_goal :integer
#  crispr_gc_goal :integer
#  total_mi_goal  :integer
#  total_gc_goal  :integer
#
# Indexes
#
#  index_production_goals_on_consortium_id_and_year_and_month  (consortium_id,year,month) UNIQUE
#
