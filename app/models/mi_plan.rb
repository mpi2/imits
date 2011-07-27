# encoding: utf-8

class MiPlan < ActiveRecord::Base
  belongs_to :gene
  belongs_to :consortium
  belongs_to :mi_plan_status
  belongs_to :mi_plan_priority

  access_association_by_attribute :gene, :name
  access_association_by_attribute :consortium, :name
  access_association_by_attribute :mi_plan_status, :name
  access_association_by_attribute :mi_plan_priority, :name

  validates :gene, :presence => true
  validates :consortium, :presence => true
  validates :mi_plan_status, :presence => true
  validates :mi_plan_priority, :presence => true

  validates_uniqueness_of :gene_id, :scoped_to => [:consortium_id]
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
#  index_mi_plans_on_gene_id_and_consortium_id  (gene_id,consortium_id) UNIQUE
#

