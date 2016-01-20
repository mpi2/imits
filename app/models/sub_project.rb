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

# IDEAS FOR IMPROVEMENT
# Add centre to table and filter sub_projects based on centre in forms.
# validate :centre, :presence => true

end

# == Schema Information
#
# Table name: plans
#
#  id                   :integer          not null, primary key
#  gene_id              :integer          not null
#  consortium_id        :integer
#  production_centre_id :integer
#
