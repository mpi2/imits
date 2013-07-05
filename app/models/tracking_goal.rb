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
    eucomm_required
    komp_required
    norcomm_required
    wtsi_required
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
  validates :goal, :presence => true
  validates :goal_type, :presence => true, :inclusion => {:in => GOAL_TYPES}

  ## Relationships
  belongs_to :production_centre, :class_name => 'Centre'

  access_association_by_attribute :production_centre, :name

  attr_accessible *READABLE_ATTRIBUTES

  before_validation do
    if !month.blank? && !year.blank?
      begin
        self.date = Date.parse("#{year}-#{month}-01")
      rescue
        self.errors.add :date, "Invalid date"
      end
    end

    true
  end

  before_save(:on => :create) do
    if self.date.blank?
      ## Check to see if we already have a blank date for the cumulative row.
      if self.class.where(:goal_type => self.goal_type, :production_centre_id => self.production_centre_id, :date => nil).first
        self.errors.add :date, 'There is already a cumulative goal for this production centre.'
        return false
      end
    end
  end

  def month
    @month || date.try(:month)
  end

  def year
    @year || date.try(:year)
  end

  def cumulative?
    self.date.blank?
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

