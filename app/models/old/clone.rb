# encoding: utf-8

class Old::Clone < Old::ModelBase
  set_table_name 'emi_clone'
  belongs_to :pipeline, :class_name => 'Old::Pipeline'
  has_many :emi_events, :class_name => 'Old::EmiEvent'

  scope :all_that_have_mi_attempts, proc { |mi_attempt_ids|
    select('DISTINCT emi_clone.*').joins(:emi_events => :mi_attempts)
  }
end

# == Schema Information
# Schema version: 20110527121721
#
# Table name: emi_clone
#
#  id                        :decimal(, )     not null, primary key
#  clone_name                :string(128)     not null
#  created_date              :datetime
#  creator_id                :integer(38)
#  edit_date                 :datetime
#  edited_by                 :string(128)
#  pipeline_id               :integer(38)     not null
#  gene_symbol               :string(256)
#  allele_name               :string(256)
#  ensembl_id                :string(20)
#  otter_id                  :string(20)
#  target_exon               :string(20)
#  design_id                 :decimal(, )
#  design_instance_id        :decimal(, )
#  recombineering_bac_strain :string(4000)
#  es_cell_line_type         :string(4000)
#  genotype_pass_level       :string(4000)
#  es_cell_strain            :string(100)
#  es_cell_line              :string(100)
#  customer_priority         :boolean(1)
#
# Indexes
#
#  emi_clone_uk1  (clone_name) UNIQUE
#
