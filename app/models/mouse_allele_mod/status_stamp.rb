# encoding: utf-8

class MouseAlleleMod::StatusStamp < ActiveRecord::Base
  acts_as_audited

  belongs_to :mouse_allele_mod
  belongs_to :status

  delegate :name, :code, :to => :status
end

# == Schema Information
#
# Table name: mouse_allele_mod_status_stamps
#
#  id                  :integer          not null, primary key
#  mouse_allele_mod_id :integer          not null
#  status_id           :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
