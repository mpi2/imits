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

    add_column :targ_rep_alleles, :allele_genbank_file_id, :integer
    add_column :targ_rep_alleles, :vector_genbank_file_id, :integer

    sql = <<-EOF
      ----
      INSERT INTO alleles(
        es_cell_id, allele_confirmed, 
        mgi_allele_symbol_without_impc_abbreviation, mgi_allele_symbol_superscript,  allele_symbol_superscript_template,
        mgi_allele_accession_id, allele_type, created_at, updated_at, genbank_file_id
        )
      SELECT targ_rep_es_cells.id, true,
             true, targ_rep_es_cells.mgi_allele_symbol_superscript, targ_rep_es_cells.allele_symbol_superscript_template, 
             targ_rep_es_cells.mgi_allele_id, CASE WHEN targ_rep_es_cells.allele_type IS NULL OR targ_rep_es_cells.allele_type = '' THEN '''''' ELSE targ_rep_es_cells.allele_type END,
             targ_rep_es_cells.created_at, targ_rep_es_cells.updated_at, targ_rep_genbank_files.id
      FROM targ_rep_es_cells
        JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_es_cells.allele_id
        LEFT JOIN targ_rep_genbank_files ON targ_rep_genbank_files.allele_id = targ_rep_alleles.id
      ;

      INSERT INTO production_centre_qcs (allele_id, five_prime_screen, three_prime_screen, loxp_screen, loss_of_allele, vector_integrity)
      SELECT alleles.id,
             production_qc_five_prime_screen,
             production_qc_three_prime_screen,
             production_qc_loxp_screen,
             production_qc_loss_of_allele,
             production_qc_vector_integrity
      FROM targ_rep_es_cells
        JOIN alleles ON alleles.es_cell_id = targ_rep_es_cells.id
      ;

      UPDATE targ_rep_genbank_files SET file_gb = escell_clone
      ;

      INSERT INTO targ_rep_genbank_files (allele_id, file_gb, created_at, updated_at)
      SELECT allele_id, targeting_vector, created_at, updated_at 
      FROM targ_rep_genbank_files
      WHERE targeting_vector IS NOT NULL
      ;

      UPDATE targ_rep_genbank_files SET file_gb = allele_genbank_file, targeting_vector = allele_genbank_file
      WHERE allele_genbank_file IS NOT NULL
      ;

      DELETE FROM targ_rep_genbank_files WHERE file_gb IS NULL
      ;

      UPDATE targ_rep_alleles SET allele_genbank_file_id = targ_rep_genbank_files.id
      FROM targ_rep_genbank_files
      WHERE targ_rep_genbank_files.escell_clone IS NOT NULL AND targ_rep_genbank_files.allele_id = targ_rep_alleles.id
      ;

      UPDATE targ_rep_alleles SET vector_genbank_file_id = targ_rep_genbank_files.id
      FROM targ_rep_genbank_files
      WHERE targ_rep_genbank_files.file_gb IS NOT NULL AND targ_rep_genbank_files.escell_clone IS NULL AND targ_rep_genbank_files.targeting_vector IS NOT NULL AND targ_rep_genbank_files.allele_id = targ_rep_alleles.id
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
    remove_column :targ_rep_genbank_files, :allele_genbank_file

    drop_table :targ_rep_real_alleles
  end
end
