class AddMutagenesisFactorExternalRefToMutagenesisFactor < ActiveRecord::Migration
  def change
  	add_column :mutagenesis_factors, :external_ref, :string
  end
end