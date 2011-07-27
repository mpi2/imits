class Gene < ActiveRecord::Base
  has_many :es_cells

  validates :marker_symbol, :presence => true, :uniqueness => true

  def self.find_or_create_from_mart_data(mart_data)
    gene = Gene.find_by_marker_symbol(mart_data['marker_symbol'])
    if gene
      return gene
    else
      return Gene.create!(:marker_symbol => mart_data['marker_symbol'],
        :mgi_accession_id => mart_data['mgi_accession_id'])
    end
  end
end

# == Schema Information
# Schema version: 20110727110911
#
# Table name: genes
#
#  id               :integer         not null, primary key
#  marker_symbol    :string(75)      not null
#  mgi_accession_id :string(40)
#  created_at       :datetime
#  updated_at       :datetime
#
# Indexes
#
#  index_genes_on_marker_symbol  (marker_symbol) UNIQUE
#

