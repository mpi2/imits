class ReorganisePhenotypingColonyName < ActiveRecord::Migration

  def self.up
    add_column :phenotype_attempts, :parent_colony_id, :integer
    add_column :mouse_allele_mods, :parent_colony_id, :integer
    add_column :phenotyping_productions, :parent_colony_id, :integer

    add_column :phenotyping_productions, :colony_background_strain_id, :integer
    add_column :phenotyping_productions, :rederivation_started, :boolean, :null => false, :default => false
    add_column :phenotyping_productions, :rederivation_complete, :boolean, :null => false, :default => false

    add_column :centres, :superscript, :string
    add_column :deleter_strains, :excision_type, :string

    add_column :colonies, :mouse_allele_mod_id, :integer
    add_column :colonies, :mgi_allele_symbol_superscript, :string
    add_column :colonies, :allele_symbol_superscript_template, :string
    add_column :colonies, :allele_type, :string
    add_column :colonies, :background_strain_id, :integer

    create_table :phenotype_attempt_ids do |t|
    end

    create_table :colony_distribution_centres do |t|
      t.integer :colony_id, :null => false
      t.integer :deposited_material_id, :null => false
      t.string :distribution_network
      t.integer :centre_id, :null => false
      t.date :start_date
      t.date :end_date
      t.string :reconciled, :limit =>255, :default => "not checked", :null => false
      t.datetime :reconciled_at
      t.boolean :available, :default => true, :null => false
      t.timestamps
    end

    add_foreign_key :colonies, :mouse_allele_mods, :column => :mouse_allele_mod_id, :name => 'colonies_mouse_allele_mod_fk'
    remove_index :colonies, :name => :colony_name_index
    remove_foreign_key :mouse_allele_mods, :name => :mouse_allele_mods_phenotype_attempt_id_fk
    remove_foreign_key :phenotyping_productions, :name => :phenotyping_productions_phenotype_attempt_id_fk
    remove_foreign_key :phenotyping_productions,  :name =>  :phenotyping_productions_mouse_allele_mod_id_fk

    remove_foreign_key :phenotype_attempt_distribution_centres,  :name =>  :fk_mouse_allele_mod_distribution_centres
    add_index :colonies, [:name, :mi_attempt_id, :mouse_allele_mod_id], :unique => true, :name => :mouse_allele_mod_colony_name_uniqueness_index

    sql = <<-EOF
        --
        INSERT INTO phenotype_attempt_ids (id) SELECT id FROM phenotype_attempts;
        SELECT setval('phenotype_attempt_ids_id_seq', (SELECT MAX(id) FROM phenotype_attempts));

        -- Move Mi Attempt mouse_allele_type to colonies table. Populate this fields from the mi_attempt field before removing this field.
        UPDATE colonies SET allele_type = mi_attempts.mouse_allele_type, background_strain_id = mi_attempts.colony_background_strain_id
        FROM mi_attempts
        WHERE mi_attempts.id = colonies.mi_attempt_id AND mi_attempts.mouse_allele_type IS NOT NULL;

        -- Move Mi Attempt background_strain to colonies table. Populate this fields from the mi_attempt field before removing this field.
        UPDATE colonies SET background_strain_id = mi_attempts.colony_background_strain_id
        FROM mi_attempts
        WHERE mi_attempts.id = colonies.mi_attempt_id AND mi_attempts.colony_background_strain_id IS NOT NULL;

        -- replace colony_name with a colony model. Create new colonies for all the mouse_allele_mod colonies
        INSERT INTO colonies (name, genotype_confirmed, mouse_allele_mod_id, mgi_allele_symbol_superscript, allele_symbol_superscript_template, allele_type, mgi_allele_id, background_strain_id) SELECT colony_name, CASE WHEN status_id = 6 THEN true ELSE false END, mouse_allele_mods.id, mouse_allele_mods.allele_name ,substring(mouse_allele_mods.allele_name from 'tm.') || '@' || substring(mouse_allele_mods.allele_name from '\(.+\).+') AS allele_symbol_superscript_template ,mouse_allele_mods.mouse_allele_type, mouse_allele_mods.allele_mgi_accession_id, mouse_allele_mods.colony_background_strain_id  FROM mouse_allele_mods WHERE mouse_allele_mods.cre_excision = true;

        -- Copy mouse_allele_mod qc to colony_qc table

        INSERT INTO colony_qcs (colony_id, qc_southern_blot, qc_five_prime_lr_pcr, qc_five_prime_cassette_integrity, qc_tv_backbone_assay, qc_neo_count_qpcr, qc_lacz_count_qpcr, qc_neo_sr_pcr, qc_loa_qpcr, qc_homozygous_loa_sr_pcr, qc_lacz_sr_pcr, qc_mutant_specific_sr_pcr, qc_loxp_confirmation, qc_three_prime_lr_pcr, qc_critical_region_qpcr, qc_loxp_srpcr, qc_loxp_srpcr_and_sequencing)
        SELECT colonies.id AS colony_id,
        qr1.description,
        qr2.description,
        qr3.description,
        qr4.description,
        qr5.description,
        qr6.description,
        qr7.description,
        qr8.description,
        qr9.description,
        qr10.description,
        qr11.description,
        qr12.description,
        qr13.description,
        qr14.description,
        qr15.description,
        qr16.description
        FROM mouse_allele_mods
        JOIN colonies ON colonies.mouse_allele_mod_id = mouse_allele_mods.id
        JOIN qc_results qr1 ON qr1.id = qc_southern_blot_id
        JOIN qc_results qr2 ON qr2.id = qc_five_prime_lr_pcr_id
        JOIN qc_results qr3 ON qr3.id = qc_five_prime_cassette_integrity_id
        JOIN qc_results qr4 ON qr4.id = qc_tv_backbone_assay_id
        JOIN qc_results qr5 ON qr5.id = qc_neo_count_qpcr_id
        JOIN qc_results qr6 ON qr6.id = qc_lacz_count_qpcr_id
        JOIN qc_results qr7 ON qr7.id = qc_neo_sr_pcr_id
        JOIN qc_results qr8 ON qr8.id = qc_loa_qpcr_id
        JOIN qc_results qr9 ON qr9.id = qc_homozygous_loa_sr_pcr_id
        JOIN qc_results qr10 ON qr10.id = qc_lacz_sr_pcr_id
        JOIN qc_results qr11 ON qr11.id = qc_mutant_specific_sr_pcr_id
        JOIN qc_results qr12 ON qr12.id = qc_loxp_confirmation_id
        JOIN qc_results qr13 ON qr13.id = qc_three_prime_lr_pcr_id
        JOIN qc_results qr14 ON qr14.id = qc_critical_region_qpcr_id
        JOIN qc_results qr15 ON qr15.id = qc_loxp_srpcr_id
        JOIN qc_results qr16 ON qr16.id = qc_loxp_srpcr_and_sequencing_id;

        -- Reorganise foreign keys to use parent_colonies not mi_attempt or mouse_allele_mod

        UPDATE phenotype_attempts SET parent_colony_id = colonies.id
        FROM mi_attempts, colonies
        WHERE mi_attempts.id = phenotype_attempts.mi_attempt_id AND colonies.mi_attempt_id = mi_attempts.id;

        UPDATE mouse_allele_mods SET parent_colony_id = colonies.id
        FROM mi_attempts, colonies
        WHERE mi_attempts.id = mouse_allele_mods.mi_attempt_id AND colonies.mi_attempt_id = mi_attempts.id;

        UPDATE phenotyping_productions SET parent_colony_id = colonies.id
        FROM mouse_allele_mods, mi_attempts, colonies
        WHERE mouse_allele_mods.id = phenotyping_productions.mouse_allele_mod_id AND mi_attempts.id = mouse_allele_mods.mi_attempt_id AND colonies.mi_attempt_id = mi_attempts.id AND mouse_allele_mods.cre_excision = false;

        UPDATE phenotyping_productions SET parent_colony_id = colonies.id, phenotype_attempt_id = mouse_allele_mods.phenotype_attempt_id
        FROM mouse_allele_mods, colonies
        WHERE mouse_allele_mods.id = phenotyping_productions.mouse_allele_mod_id AND colonies.mouse_allele_mod_id = mouse_allele_mods.id  AND mouse_allele_mods.cre_excision = true;

        UPDATE phenotyping_productions SET colony_background_strain_id = mouse_allele_mods.colony_background_strain_id, rederivation_started = mouse_allele_mods.rederivation_complete, rederivation_complete = mouse_allele_mods.rederivation_complete, phenotype_attempt_id = mouse_allele_mods.phenotype_attempt_id
        FROM mouse_allele_mods
        WHERE mouse_allele_mods.id = phenotyping_productions.mouse_allele_mod_id AND mouse_allele_mods.cre_excision = false;

       INSERT INTO colony_distribution_centres (colony_id, deposited_material_id, distribution_network, centre_id, start_date, end_date, reconciled, reconciled_at, available, updated_at, created_at)
         SELECT colonies.id, mi_attempt_distribution_centres.deposited_material_id, mi_attempt_distribution_centres.distribution_network, mi_attempt_distribution_centres.centre_id, mi_attempt_distribution_centres.start_date, mi_attempt_distribution_centres.end_date, mi_attempt_distribution_centres.reconciled, mi_attempt_distribution_centres.reconciled_at, mi_attempt_distribution_centres.available , mi_attempt_distribution_centres.updated_at, mi_attempt_distribution_centres.created_at FROM mi_attempt_distribution_centres JOIN mi_attempts ON mi_attempts.id = mi_attempt_distribution_centres.mi_attempt_id JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id
         UNION
         SELECT colonies.id, phenotype_attempt_distribution_centres.deposited_material_id, phenotype_attempt_distribution_centres.distribution_network, phenotype_attempt_distribution_centres.centre_id, phenotype_attempt_distribution_centres.start_date, phenotype_attempt_distribution_centres.end_date, phenotype_attempt_distribution_centres.reconciled, phenotype_attempt_distribution_centres.reconciled_at, phenotype_attempt_distribution_centres.available , phenotype_attempt_distribution_centres.updated_at, phenotype_attempt_distribution_centres.created_at FROM phenotype_attempt_distribution_centres JOIN mouse_allele_mods ON mouse_allele_mods.id = phenotype_attempt_distribution_centres.mouse_allele_mod_id JOIN colonies ON colonies.mouse_allele_mod_id = mouse_allele_mods.id
         ;

       --Delete mouse_allele_mods when mouse_allele_modifications are not occuring. Not required with the addition of parent_colony_id keys above

       DELETE FROM mouse_allele_mod_status_stamps WHERE mouse_allele_mod_status_stamps.mouse_allele_mod_id IN (SELECT id FROM mouse_allele_mods WHERE cre_excision = false);
       DELETE FROM mouse_allele_mods WHERE cre_excision = false;

       INSERT INTO phenotyping_production_statuses (name, code, order_by) VALUES ('Rederivation Started', 'res', 430), ('Rederivation Complete', 'rec', 440);
    EOF

    ActiveRecord::Base.connection.execute(sql)

    add_foreign_key :mouse_allele_mods, :phenotype_attempt_ids, :column => :phenotype_attempt_id
    add_foreign_key :phenotyping_productions, :phenotype_attempt_ids, :column => :phenotype_attempt_id


    remove_column :phenotyping_productions, :mouse_allele_mod_id

#    remove_column :mi_attempts, :mouse_allele_type

    remove_column :mouse_allele_mods, :mi_attempt_id
    remove_column :mouse_allele_mods, :colony_name
    remove_column :mouse_allele_mods,  :mouse_allele_type
#    remove_column :mouse_allele_mods, :allele_category
#    remove_column :mouse_allele_mods, :allele_name
#    remove_column :mouse_allele_mods, :allele_mgi_accession_id

#    alter_column :mouse_allele_mods, :cre_excision, :excision
  end

  def self.down
    remove_foreign_key :colonies, :name => 'colonies_mouse_allele_mod_fk'
    remove_index :colonies, :name => :mouse_allele_mod_colony_name_uniqueness_index
    remove_index :colonies, :name => :mi_attempt_colony_name_uniqueness_index
    add_index :colonies, [:name], :name => :colony_name_index

    remove_column :phenotype_attempts, :parent_colony_id
    remove_column :mouse_allele_mods, :parent_colony_id
    remove_column :phenotyping_productions, :parent_colony_id

    remove_column :phenotyping_productions, :colony_background_strain_id
    remove_column :phenotyping_productions, :rederivation_started
    remove_column :phenotyping_productions, :rederivation_complete

    remove_column :centres, :superscript
    remove_column :deleter_strains, :excision_type

    remove_column :colonies, :mouse_allele_mod_id
    remove_column :colonies, :mgi_allele_symbol_superscript
    remove_column :colonies, :allele_symbol_superscript_template
    remove_column :colonies, :allele_type
    remove_column :colonies, :background_strain_id

  end
end
