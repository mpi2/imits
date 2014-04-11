# encoding: utf-8

class PhenotypingProduction::StatusStamp < ActiveRecord::Base
  acts_as_audited

  belongs_to :phenotyping_production
  belongs_to :status

  delegate :name, :code, :to => :status
end

# == Schema Information
#
# Table name: phenotyping_production_status_stamps
#
#  id                        :integer          not null, primary key
#  phenotyping_production_id :integer          not null
#  status_id                 :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
