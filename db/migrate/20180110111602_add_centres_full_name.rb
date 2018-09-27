class AddCentresFullName < ActiveRecord::Migration

  def self.up
    add_column :centres, :full_name, :string
    add_column :consortia, :credit_centre_with_production, :boolean, :default => true

    sql = <<-EOF
      UPDATE centres SET full_name = 'Australian Phenomics Network' WHERE centres.name = 'APN';
      UPDATE centres SET full_name = 'Bayor College of Medicine' WHERE centres.name = 'BCM';
      UPDATE centres SET full_name = 'CAM-SU Genomic Resource Center, Soochow University' WHERE centres.name = 'CAM-SU GRC';
      UPDATE centres SET full_name = 'Transgenese et Archivage d Animaux Modeles' WHERE centres.name = 'CDTA';
      UPDATE centres SET full_name = 'Immunophenomique Center' WHERE centres.name = 'CIPHE';
      UPDATE centres SET full_name = 'Centro National De Biotecnologia' WHERE centres.name = 'CNB';
      UPDATE centres SET full_name = 'Centre National de la Recherche Scientifique' WHERE centres.name = 'CNRS';
      UPDATE centres SET full_name = 'B.S.R.C. Alexander Fleming Institute' WHERE centres.name = 'Fleming';
      UPDATE centres SET full_name = 'Medical Research Council Harwell' WHERE centres.name = 'Harwell';
      UPDATE centres SET full_name = 'Helmholtz-Zentrum Muenchen' WHERE centres.name = 'HMGU';
      UPDATE centres SET full_name = 'Institut Clinique de la Souris' WHERE centres.name = 'ICS';
      UPDATE centres SET full_name = 'Czech centre for Phenogenomics' WHERE centres.name = 'CCP-IMG';
      UPDATE centres SET full_name = 'The Jackson Laboratory' WHERE centres.name = 'JAX';
      UPDATE centres SET full_name = 'Korea Mouse Phenotype Consortium' WHERE centres.name = 'KMPC';
      UPDATE centres SET full_name = 'Korea Research Institute of Bioscience and Biotechnology' WHERE centres.name = 'KRIBB';
      UPDATE centres SET full_name = 'MARC Nanjing University' WHERE centres.name = 'MARC';
      UPDATE centres SET full_name = 'CNR Monterotondo' WHERE centres.name = 'Monterotondo';
      UPDATE centres SET full_name = 'CNR Monterotondo' WHERE centres.name = 'Monterotondo R&D';
      UPDATE centres SET full_name = 'National Laboratory Animal Center, National Applied Research Laboratories' WHERE centres.name = 'NARLabs';
      UPDATE centres SET full_name = 'RIKEN BioResource Center' WHERE centres.name = 'RIKEN BRC';
      UPDATE centres SET full_name = 'Toronto Centre for Phenogenomics' WHERE centres.name = 'TCP';
      UPDATE centres SET full_name = 'UC Davies' WHERE centres.name = 'UCD';
      UPDATE centres SET full_name = 'Welcome Trust Sanger Institute' WHERE centres.name = 'WTSI';
    EOF
 
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.down
    remove_column :centres, :full_name
    remove_column :consortia, :credit_centre_with_production
  end

end
