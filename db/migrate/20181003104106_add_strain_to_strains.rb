class AddStrainToStrains < ActiveRecord::Migration
  def change
  	sql = <<-EOF
      INSERT INTO strains (name, mgi_strain_accession_id, mgi_strain_name, background_strain, test_cross_strain, blast_strain) 
      VALUES ('CBA/Ca', null, null, false, false, false) ;
    EOF
 
    ActiveRecord::Base.connection.execute(sql)
  end
end
