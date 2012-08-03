# encoding: utf-8

class PhenotypeAttempt::DistributionCentre < ActiveRecord::Base
  extend AccessAssociationByAttribute

  belongs_to :phenotype_attempt
  belongs_to :centre
  belongs_to :deposited_material

  validates :phenotype_attempt_id, :presence => true
  validates :centre_id, :presence => true
  validates :deposited_material_id, :presence => true

  access_association_by_attribute :deposited_material, :name
  access_association_by_attribute :centre, :name

  def as_json(options = {})
    options.merge(
      :only => [:start_date, :end_date, :is_distributed_by_emma],
      :methods => [:deposited_material_name, :centre_name]
    )
    super(options)
  end
end

# == Schema Information
#
# Table name: phenotype_attempt_distribution_centres
#
#  id                     :integer         not null, primary key
#  start_date             :date
#  end_date               :date
#  phenotype_attempt_id   :integer         not null
#  deposited_material_id  :integer         not null
#  centre_id              :integer         not null
#  is_distributed_by_emma :boolean         default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#

