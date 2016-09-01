# encoding: utf-8

class SubProject < ApplicationModel
  acts_as_audited
  acts_as_reportable

  has_many :plan_intentions
  has_many :es_cell_qcs
  has_many :mi_attempts
  has_many :mouse_allele_mods
  has_many :phenotyping_productions

  validates :name, :uniqueness => {:case_sensitive => false}

  def assigned?
    return true unless plan_intentions.blank?
    return true unless es_cell_qcs.blank?
    return true unless mi_attempts.blank?
    return true unless mouse_allele_mods.blank?
    return true unless phenotyping_productions.blank?
    false
  end

# IDEAS FOR IMPROVEMENT
# Add centre to table and filter sub_projects based on centre in forms.
# validate :centre, :presence => true

end

# == Schema Information
#
# Table name: sub_projects
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#
