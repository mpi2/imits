class AddTypeToTargRepAlleles < ActiveRecord::Migration
  def change
    add_column :targ_rep_alleles, :type, :string, :default => 'TargRep::TargetedAllele'
    TargRep::TargetedAllele.update_all({:type => 'TargRep::GeneTrap'}, 'mutation_type_id = 7')
  end
end
