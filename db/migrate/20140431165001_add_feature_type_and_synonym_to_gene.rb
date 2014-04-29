class AddFeatureTypeAndSynonymToGene < ActiveRecord::Migration
  def change
    add_column :genes, :feature_type, :string
    add_column :genes, :synonyms, :string
  end
end
