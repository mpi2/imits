# encoding: utf-8

class MiAttempt::DistributionCentre < ActiveRecord::Base

  belongs_to :mi_attempt
  belongs_to :centre
  belongs_to :deposited_material

  validates :mi_attempt_id, :presence => true
  validates :centre_id, :presence => true
  #validates :deposited_material_id, :presence => true
end

# == Schema Information
#
# Table name: mi_attempt_distribution_centres
#
#  id                    :integer         not null, primary key
#  start_date            :date
#  end_date              :date
#  mi_attempt_id         :integer         not null
#  deposited_material_id :integer         not null
#  centre_id             :integer         not null
#  created_at            :datetime
#  updated_at            :datetime
#

