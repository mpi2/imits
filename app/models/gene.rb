class Gene < ActiveRecord::Base
  acts_as_reportable

  has_many :es_cells
  has_many :mi_plans

  validates :marker_symbol, :presence => true, :uniqueness => true

  def self.find_or_create_from_mart_data(mart_data)
    return self.find_or_create_by_mgi_accession_id(
      :marker_symbol => mart_data['marker_symbol'],
      :mgi_accession_id => mart_data['mgi_accession_id'])
  end

  # BEGIN Mart Operations

  def self.find_or_create_from_marts_by_mgi_accession_id(mgi_accession_id)
    return nil if mgi_accession_id.blank?

    gene = self.find_by_mgi_accession_id(mgi_accession_id)
    return gene if gene

    mart_data = DCC_BIOMART.search(
      :filters =>  { 'mgi_accession_id' => mgi_accession_id },
      :attributes => ['marker_symbol', 'mgi_accession_id'],
      :process_results => true,
      :timeout => 600
    )

    if mart_data[0].blank?
      return nil
    else
      return self.create!(mart_data[0])
    end
  end

  # END Mart Operations

end

# == Schema Information
# Schema version: 20110802094958
#
# Table name: genes
#
#  id                                 :integer         not null, primary key
#  marker_symbol                      :string(75)      not null
#  mgi_accession_id                   :string(40)
#  ikmc_projects_count                :integer
#  conditional_es_cells_count         :integer
#  non_conditional_es_cells_count     :integer
#  deletion_es_cells_count            :integer
#  other_targeted_mice_count          :integer
#  other_condtional_mice_count        :integer
#  mutation_published_as_lethal_count :integer
#  publications_for_gene_count        :integer
#  go_annotations_for_gene_count      :integer
#  created_at                         :datetime
#  updated_at                         :datetime
#
# Indexes
#
#  index_genes_on_marker_symbol  (marker_symbol) UNIQUE
#

