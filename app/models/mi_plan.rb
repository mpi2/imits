# encoding: utf-8

class MiPlan < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :gene
  belongs_to :consortium
  belongs_to :mi_plan_status
  belongs_to :mi_plan_priority
  belongs_to :production_centre, :class_name => 'Centre'

  validates :gene, :presence => true
  validates :consortium, :presence => true
  validates :mi_plan_status, :presence => true
  validates :mi_plan_priority, :presence => true

  validates_uniqueness_of :gene_id, :scope => [:consortium_id, :production_centre_id]

  def self.assign_genes_and_mark_conflicts
    grouped_by_gene = self.all.group_by {|i| i.gene.mgi_accession_id}

    grouped_by_gene.each do |mgi_accession_id, mi_plans|
      mi_plans.each do |mi_plan|
        mi_plan.mi_plan_status = MiPlanStatus.find_by_name!('Assigned')
        mi_plan.save!
      end
    end
  end

end

# == Schema Information
# Schema version: 20110727110911
#
# Table name: mi_plans
#
#  id                   :integer         not null, primary key
#  gene_id              :integer         not null
#  consortium_id        :integer         not null
#  mi_plan_status_id    :integer         not null
#  mi_plan_priority_id  :integer         not null
#  production_centre_id :integer
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  mi_plan_logical_key  (gene_id,consortium_id,production_centre_id) UNIQUE
#

