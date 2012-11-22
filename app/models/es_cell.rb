class EsCell < ActiveRecord::Base
  
end

# == Schema Information
#
# Table name: es_cells
#
#  id                                 :integer         not null, primary key
#  name                               :string(100)     not null
#  allele_symbol_superscript_template :string(75)
#  allele_type                        :string(2)
#  pipeline_id                        :integer         not null
#  created_at                         :datetime
#  updated_at                         :datetime
#  gene_id                            :integer         not null
#  parental_cell_line                 :string(255)
#  ikmc_project_id                    :string(100)
#  mutation_subtype                   :string(100)
#  allele_id                          :integer         not null
#
# Indexes
#
#  index_es_cells_on_name  (name) UNIQUE
#

