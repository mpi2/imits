class AddKompSpecificCmgFilter < ActiveRecord::Migration
  def self.up
    add_column :genes, :cmg_tier1, :boolean, default: false 
    add_column :genes, :cmg_tier2, :boolean, default: false
    add_column :genes, :idg, :boolean, default: false

    sql = <<-EOF
      UPDATE genes SET cmg_tier1 = gpa.cmg_tier1, cmg_tier2 = gpa.cmg_tier2, idg = gpa.idg
        FROM gene_private_annotations gpa
        WHERE gpa.gene_id = genes.id;

      UPDATE gene_private_annotations SET cmg_tier1 = false, cmg_tier2 = false, idg = false;
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :genes, :cmg_tier1
    remove_column :genes, :cmg_tier2
    remove_column :genes, :idg
  end
end
