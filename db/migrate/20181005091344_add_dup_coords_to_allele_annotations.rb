class AddDupCoordsToAlleleAnnotations < ActiveRecord::Migration
  def change
    add_column :allele_annotations, :dup_coords, :string

    sql = <<-EOF
      DELETE FROM allele_annotations;
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end
end
  