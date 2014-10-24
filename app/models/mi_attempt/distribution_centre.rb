# encoding: utf-8

class MiAttempt::DistributionCentre < DistributionCentre
  extend AccessAssociationByAttribute
  include Public::Serializable

  acts_as_audited

  # DISTRIBUTION_NETWORKS = %w{
  #   CMMR
  #   EMMA
  #   MMRRC
  # }

  # FULL_ACCESS_ATTRIBUTES = %w{
  #   start_date
  #   end_date
  #   deposited_material_name
  #   centre_name
  #   is_distributed_by_emma
  #   distribution_network
  #   _destroy
  # }

  # READABLE_ATTRIBUTES = %w{
  #   id
  # } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES + ['mi_attempt_id']

  attr_accessible(*WRITABLE_ATTRIBUTES)

  belongs_to :mi_attempt
  # belongs_to :centre
  # belongs_to :deposited_material

  validates :mi_attempt_id, :presence => true
  # validates :centre_id, :presence => true
  # validates :deposited_material_id, :presence => true

  # access_association_by_attribute :deposited_material, :name
  # access_association_by_attribute :centre, :name

  # before_save do
  #   ## TODO: Update martbuilder so we don't need to continue updating the boolean.
  #   self[:is_distributed_by_emma] = self.distribution_network == 'EMMA'

  #   if (!self.distribution_network.blank?) && self.centre.name == 'KOMP Repo'
  #     self.centre = self.mi_attempt.mi_plan.production_centre
  #   end

  #   true # Rails doesn't save if you return false.
  # end

  # ## This is for backwards compatibility with portal.
  # def is_distributed_by_emma
  #   self.distribution_network == 'EMMA'
  # end

  # def is_distributed_by_emma=(bool)
  #   ## Set distribution_network to EMMA if `bool` is true
  #   if bool
  #     self.distribution_network = 'EMMA'
  #   ## Set distribution_network to nothing if `bool` is false and already set to EMMA, or leave as previous value.
  #   elsif is_distributed_by_emma
  #     self.distribution_network = nil
  #   end
  # end

  def self.readable_name
    return 'mi attempt distribution centre'
  end

end

# == Schema Information
#
# Table name: mi_attempt_distribution_centres
#
#  id                     :integer          not null, primary key
#  start_date             :date
#  end_date               :date
#  mi_attempt_id          :integer          not null
#  deposited_material_id  :integer          not null
#  centre_id              :integer          not null
#  is_distributed_by_emma :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  distribution_network   :string(255)
#
