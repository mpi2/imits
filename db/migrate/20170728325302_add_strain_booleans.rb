class AddStrainBooleans < ActiveRecord::Migration

  def self.up
    add_column :strains, :background_strain, :boolean, :default => false
    add_column :strains, :test_cross_strain, :boolean, :default => false
    add_column :strains, :blast_strain, :boolean, :default => false

    sql = <<-EOF
      WITH colony_strains AS (
        SELECT DISTINCT strains.name 
          FROM colonies 
          JOIN strains ON strains.id = colonies.background_strain_id
      )

      UPDATE strains SET background_strain = true
        FROM colony_strains
        WHERE strains.name = colony_strains.name;

      WITH phenotype_production_strains AS (
        SELECT DISTINCT strains.name 
          FROM phenotyping_productions 
          JOIN strains ON strains.id = phenotyping_productions.colony_background_strain_id
      )

      UPDATE strains SET background_strain = true
        FROM phenotype_production_strains
        WHERE strains.name = phenotype_production_strains.name;

      UPDATE strains SET background_strain = false WHERE strains.name = '(B6;129-Gt(ROSA)26Sor<tm1(DTA)Mrc>/J x B6.FVB-Tg(Ddx4-cre)1Dcas>/J)F1/MvwJ';


      WITH cross_test_strains AS (
        SELECT DISTINCT strains.name 
          FROM mi_attempts 
          JOIN strains ON strains.id = mi_attempts.test_cross_strain_id
      )

      UPDATE strains SET test_cross_strain = true
        FROM cross_test_strains
        WHERE strains.name = cross_test_strains.name;

      WITH blast_strains AS (
        SELECT DISTINCT strains.name 
          FROM mi_attempts 
          JOIN strains ON strains.id = mi_attempts.blast_strain_id
      )

      UPDATE strains SET blast_strain = true
        FROM blast_strains
        WHERE strains.name = blast_strains.name;
    EOF

    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :strains, :background_strain
    remove_column :strains, :test_cross_strain
    remove_column :strains, :blast_strain
  end

end
