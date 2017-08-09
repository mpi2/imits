class RefactorAlleleStructureForEsCells < ActiveRecord::Migration

  def self.up
    create_table :alleles do |t|
      t.integer :es_cell_id
      t.boolean :allele_confirmed, :null => false, :default => false
      t.boolean :mgi_allele_symbol_without_impc_abbreviation
      t.string  :mgi_allele_symbol_superscript
      t.string  :allele_symbol_superscript_template
      t.string  :mgi_allele_accession_id
      t.string  :allele_type
      t.integer :genbank_file_id
      t.timestamps
    end

    create_table :production_centre_qcs do |t|
      t.integer :allele_id
      t.string  :five_prime_screen
      t.string  :three_prime_screen
      t.string  :loxp_screen
      t.string  :loss_of_allele
      t.string  :vector_integrity
    end

    add_column :targ_rep_genbank_files, :file_gb, :text

    add_column :targ_rep_alleles, :allele_genebank_file_id, :integer
    add_column :targ_rep_alleles, :vector_genebank_file_id, :integer

    sql = <<-EOF
      ----
      INSERT INTO alleles(
        es_cell_id, allele_confirmed, 
        mgi_allele_symbol_without_impc_abbreviation, mgi_allele_symbol_superscript, 
        mgi_allele_accession_id, allele_type, allele_symbol_superscript_template, auto_allele_description, allele_description, created_at, updated_at, genbank_file_id
        )
      SELECT targ_rep_es_cells.id, true,
             true, targ_rep_es_cells.mgi_allele_symbol_superscript, targ_rep_es_cells.mgi_allele_id,
             targ_rep_es_cells.allele_type, targ_rep_es_cells.allele_symbol_superscript_template, NULL, NULL,
             targ_rep_es_cells.created_at, targ_rep_es_cells.updated_at, targ_rep_genbank_files.id
      FROM targ_rep_es_cells
        JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
        LEFT JOIN targ_rep_genbank_files ON targ_rep_genbank_files.allele_id = targ_rep_alleles.id
        ;


      INSERT INTO production_centre_qcs (five_prime_screen, three_prime_screen, loxp_screen, loss_of_allele, vector_integrity)
      SELECT CASE WHEN production_qc_five_prime_screen = 'pass' THEN 'pass' 
                  WHEN production_qc_five_prime_screen = 'not confirmed' THEN 'fail' 
                  WHEN production_qc_five_prime_screen = 'no reads detected' THEN 'no reads detected' 
                  ELSE 'na' END, 
      SELECT CASE WHEN production_qc_three_prime_screen = 'pass' THEN 'pass' 
                  WHEN production_qc_three_prime_screen = 'not confirmed' THEN 'fail' 
                  WHEN production_qc_three_prime_screen = 'no reads detected' THEN 'no reads detected' 
                  ELSE 'na' END,
      SELECT CASE WHEN production_qc_loxp_screen = 'pass' THEN 'pass' 
                  WHEN production_qc_loxp_screen = 'not confirmed' THEN 'fail' 
                  WHEN production_qc_loxp_screen = 'no reads detected' THEN 'no reads detected' 
                  ELSE 'na' END,
      SELECT CASE WHEN production_qc_loss_of_allele = 'pass' THEN 'pass' 
                  WHEN production_qc_loss_of_allele = 'fail' THEN 'fail' 
                  WHEN production_qc_loss_of_allele = 'passb' THEN 'pass' 
                  ELSE 'na' END,
      SELECT CASE WHEN production_qc_vector_integrity = 'pass' THEN 'pass' 
                  WHEN production_qc_vector_integrity = 'fail' THEN 'fail' 
                  WHEN production_qc_vector_integrity = 'passb' THEN 'pass' 
                  ELSE 'na' END
      FROM targ_rep_es_cells
      ;

      UPDATE targ_rep_genbank_files SET file_gb = escell_clone;

      INSERT INTO targ_rep_genbank_files (allele_id, file_gb, created_at, updated_at)
      SELECT allele_id, targeting_vector, created_at, updated_at 
      FROM targ_rep_genbank_files
      WHERE targeting_vector IS NOT NULL
      ;

      DELETE targ_rep_genbank_files WHERE file_gb IS NULL
      ;

      UPDATE targ_rep_alleles SET allele_genebank_file_id = targ_rep_genbank_files.id
      FROM targ_rep_genbank_files
      WHERE targ_rep_genbank_files.escell_clone IS NOT NULL AND targ_rep_genbank_files.allele_id = targ_rep_alleles.id
      ;

      UPDATE targ_rep_alleles SET vector_genebank_file_id = targ_rep_genbank_files.id
      FROM targ_rep_genbank_files
      WHERE targ_rep_genbank_files.file_gb IS NOT NULL AND targ_rep_genbank_files.escell_clone IS NULL AND targ_rep_genbank_files.targeting_vector IS NULL AND targ_rep_genbank_files.allele_id = targ_rep_alleles.id
      ;
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :real_allele_id
    remove_column :mouse_allele_mods, :real_allele_id
    remove_column :targ_rep_es_cells, :real_allele_id

    remove_column :targ_rep_es_cells, :mgi_allele_symbol_superscript
    remove_column :targ_rep_es_cells, :mgi_allele_id
    remove_column :targ_rep_es_cells, :production_qc_five_prime_screen
    remove_column :targ_rep_es_cells, :production_qc_three_prime_screen
    remove_column :targ_rep_es_cells, :production_qc_loxp_screen
    remove_column :targ_rep_es_cells, :production_qc_loss_of_allele
    remove_column :targ_rep_es_cells, :production_qc_vector_integrity
    remove_column :targ_rep_es_cells, :allele_type
    remove_column :targ_rep_es_cells, :allele_symbol_superscript_template

    remove_column :targ_rep_genbank_files, :allele_id
    remove_column :targ_rep_genbank_files, :targeting_vector
    remove_column :targ_rep_genbank_files, :escell_clone

    drop_table :targ_rep_real_alleles
  end
end
