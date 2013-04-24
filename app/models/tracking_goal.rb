class TrackingGoal < ActiveRecord::Base
  
  ## Gems/Plugins
  acts_as_audited
  extend AccessAssociationByAttribute
  include ::Public::Serializable
  
  attr_accessor :month, :year

  GOAL_TYPES = %w(
    total_injected_clones
    total_glt_clones
    cre_exicised_genes
    phenotype_started_genes
    phenotype_complete_genes
  )

  READABLE_ATTRIBUTES = %w(
    id
    goal
    goal_type
    year
    month
    date
    production_centre_name
    production_centre_id
  )

  ## Validations
  validates :production_centre_id, :presence => true, :uniqueness => {:scope => [:date, :goal_type]}
  validates :date, :presence => true
  validates :goal, :presence => true
  validates :goal_type, :presence => true, :inclusion => {:in => GOAL_TYPES}

  ## Relationships
  belongs_to :production_centre, :class_name => 'Centre'

  access_association_by_attribute :production_centre, :name

  attr_accessible *READABLE_ATTRIBUTES

  before_validation do
    if @month && @year
      self.date = Date.parse("#{@year}-#{@month}-01") rescue nil
    end

    true
  end

  def month
    return if date.blank?
    date.month
  end

  def year
    return if date.blank?
    date.year
  end

  def self.readable_name
    return 'tracking goal'
  end

end

# == Schema Information
#
# Table name: tracking_goals
#
#  id                   :integer         not null, primary key
#  production_centre_id :integer
#  date                 :date
#  goal_type            :string(255)
#  goal                 :integer
#  created_at           :datetime        not null
#  updated_at           :datetime        not null
#

