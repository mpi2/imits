class Centre < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :mi_plans, :foreign_key => 'production_centre_id'
  has_many :colony_distribution_centres, :class_name => "Colony::DistributionCentre"
  has_many :phenotype_attempt_distribution_centres, :class_name => "PhenotypeAttempt::DistributionCentre"

  has_many :tracking_goals, :foreign_key => 'production_centre_id'

  default_scope :order => 'name ASC'

  def has_children?
    ! (mi_plans.empty? && colony_distribution_centres.empty?)
  end

  def destroy
    return false if has_children?
    super
  end

  def self.komp
    return [
      Centre.find_by_name('BCM'),
      Centre.find_by_name('UCD'),
      Centre.find_by_name('TCP'),
      Centre.find_by_name('JAX'),
      Centre.find_by_name('Harwell')
    ]
  end

  def self.readable_name
    return 'centre'
  end

end

# == Schema Information
#
# Table name: centres
#
#  id            :integer          not null, primary key
#  name          :string(100)      not null
#  created_at    :datetime
#  updated_at    :datetime
#  contact_name  :string(100)
#  contact_email :string(100)
#  code          :string(255)
#  superscript   :string(255)
#  full_name     :string(255)
#
# Indexes
#
#  index_centres_on_name  (name) UNIQUE
#
