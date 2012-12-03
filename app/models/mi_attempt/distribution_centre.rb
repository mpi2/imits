# encoding: utf-8

class MiAttempt::DistributionCentre < ApplicationModel
  extend AccessAssociationByAttribute
  include Public::Serializable

  acts_as_audited

  FULL_ACCESS_ATTRIBUTES = %w{
    start_date
    end_date
    deposited_material_name
    centre_name
    is_distributed_by_emma
    _destroy
  }

  READABLE_ATTRIBUTES = %w{
    id
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  belongs_to :mi_attempt
  belongs_to :centre
  belongs_to :deposited_material

  validates :mi_attempt_id, :presence => true
  validates :centre_id, :presence => true
  validates :deposited_material_id, :presence => true

  access_association_by_attribute :deposited_material, :name
  access_association_by_attribute :es_cell_distribution_centre, :name
end

# == Schema Information
#
# Table name: mi_attempt_distribution_centres
#
#  id                     :integer         not null, primary key
#  start_date             :date
#  end_date               :date
#  mi_attempt_id          :integer         not null
#  deposited_material_id  :integer         not null
#  centre_id              :integer         not null
#  is_distributed_by_emma :boolean         default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#

