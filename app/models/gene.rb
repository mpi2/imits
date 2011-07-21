class Gene < ActiveRecord::Base
end

# == Schema Information
# Schema version: 20110721091844
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

