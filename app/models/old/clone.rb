class Old::Clone < Old::ModelBase
  set_table_name 'emi_clone'
end

# == Schema Information
# Schema version: 20110311153640
#
# Table name: emi_clone
#
#  id                        :integer         not null, primary key
#  clone_name                :string(128)     not null
#  created_date              :datetime
#  creator_id                :integer
#  edit_date                 :datetime
#  edited_by                 :string(128)
#  pipeline_id               :integer         not null
#  gene_symbol               :string(256)
#  allele_name               :string(256)
#  ensembl_id                :string(20)
#  otter_id                  :string(20)
#  target_exon               :string(20)
#  design_id                 :integer
#  design_instance_id        :integer
#  recombineering_bac_strain :string(4000)
#  es_cell_line_type         :string(4000)
#  genotype_pass_level       :string(4000)
#  es_cell_strain            :string(100)
#  es_cell_line              :string(100)
#  customer_priority         :boolean
#

