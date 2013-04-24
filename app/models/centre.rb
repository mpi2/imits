class Centre < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :mi_plans, :foreign_key => 'production_centre_id'
  has_many :mi_attempt_distribution_centres, :class_name => "MiAttempt::DistributionCentre"
  has_many :phenotype_attempt_distribution_centres, :class_name => "PhenotypeAttempt::DistributionCentre"

  has_many :tracking_goals

  default_scope :order => 'name ASC'

  def has_children?
    ! (mi_plans.empty? && mi_attempt_distribution_centres.empty? && phenotype_attempt_distribution_centres.empty?)
  end

  def destroy
    return false if has_children?
    super
  end

  def self.readable_name
    return 'centre'
  end
end

# == Schema Information
#
# Table name: centres
#
#  id         :integer         not null, primary key
#  name       :string(100)     not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_centres_on_name  (name) UNIQUE
#

