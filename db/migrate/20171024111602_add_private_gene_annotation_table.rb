class AddPrivateGeneAnnotationTable < ActiveRecord::Migration

  def self.up
    create_table :gene_private_annotations do |t|
      t.integer :gene_id, :null => false
      t.boolean :idg, :default => false
      t.boolean :cmg_tier1, :default => false
      t.boolean :cmg_tier2, :default => false
    end

    sql = <<-EOF
      INSERT INTO gene_private_annotations(gene_id) 
      SELECT genes.id
        FROM genes;
    EOF

    ActiveRecord::Base.connection.execute(sql)

  end

  def self.down
    drop_table :gene_private_annotations
  end

end
