class GeneAssignmentChanges < ActiveRecord::Migration

  def self.up
    ### Create Gene List tables
    create_table :gene_lists do |t|
      t.string :name, :null => false
      t.text :description
    end

    create_table :gene_assignments do |t|
      t.integer :plan_id, :null => false
      t.integer :status_id, :null => false
      t.integer :gene_list_id, :null => false
      t.boolean :assign, :null => false, :default => false
      t.boolean :withdraw, :null => false, :default => false 
      t.boolean :conflict, :null => false, :default => false
    end

    create_table :gene_assignment_statuses do |t|
      t.string :name, :limit => 50, :null => false
      t.string :description, :limit => 255
      t.integer :order_by

      t.timestamps
    end
    add_index :gene_assignment_statuses, :name, :unique => true

    create_table :gene_assignment_status_stamps do |table|
      table.integer :gene_assignment_id, :null => false
      table.integer :gene_assignment_status_id, :null => false

      table.timestamps
    end


    ### extract ES Cell QC into new table
    create_table :es_cell_qcs do |t|
      t.integer :plan_id, :null => true
      t.integer :status_id, :null => true
      t.integer :plan_intention_id, :null => true
      t.integer :number_of_es_cells_received
      t.date    :es_cells_received_on
      t.integer :es_cells_received_from_id
      t.integer :number_of_es_cells_starting_qc
      t.integer :number_of_es_cells_passing_qc
      t.integer :comment_id
      t.timestamps
    end

    create_table :es_cell_qc_statuses do |t|
      t.string :name, :limit => 50, :null => false
      t.string :description, :limit => 255
      t.integer :order_by

      t.timestamps
    end
    add_index :es_cell_qc_statuses, :name, :unique => true

    create_table :es_cell_qc_status_stamps do |table|
      table.integer :es_cell_qc_id, :null => false
      table.integer :es_cell_qc_status_id, :null => false

      table.timestamps
    end

    create_table :plans do |table|
      table.integer :gene_id, :null => false
      table.integer :consortium_id
      table.integer :production_centre_id


      table.timestamps
    end

    add_foreign_key :es_cell_qcs, :mi_plans
    add_foreign_key :es_cell_qcs, :ees_cell_qc_statuses

    add_foreign_key :es_cell_qc_status_stamps, :es_cell_qcs
    add_foreign_key :es_cell_qc_status_stamps, :es_cell_qc_statuses

    create_table :intentions do |t|
      t.string :name, :null => false
      t.string :description. :limit => 255
    end

    ### extract intentions of plans. i.e. are mice to be produced, are mice going to be phenotyped etc.
    create_table :plan_intentions do |t|
      t.integer :plan_id, :null => false
      t.integer :intention_id, :null => false
      t.integer :sub_project_id, :null => true
      t.integer :priority_id
      t.boolean :target_bespoke_allele, :default => false, :null => false
      t.boolean :target_recovery_allele, :default => false, :null => false
      t.boolean :target_conditional_allele, :default => false, :null => false
      t.boolean :target_non_conditional_allele, :default => false, :null => false
      t.boolean :target_cre_knock_in_allele, :default => false, :null => false
      t.boolean :target_cre_bac_allele, :default => false, :null => false
      t.boolean :target_conditional_tm1c, :default => false, :null => false
      t.boolean :target_conditional_tm1d, :default => false, :null => false
      t.boolean :target_point_mutation, :default => false, :null => false
      t.boolean :conditional_point_mutation, :default => false, :null => false
      t.boolean :target_deletion_allele, :default => false, :null => false
      t.text    :comment
      t.text    :completion_comment
      t.boolean :ignore_available_mice, :default => false, :null => false
      t.boolean :is_active, :default => true, :null => false
      t.boolean :report_to_public,:default => true, :null => false
      t.timestamps
    end
 
    rename_column :mi_attempts, :mi_plan_id, :plan_intention_id
    rename_column :mouse_allele_mods, :mi_plan_id, :plan_intention_id
    rename_column :phenotyping_productions, :mi_plan_id, :plan_intention_id

    remove_index :index_mi_plan_es_qc_comments_on_name
    rename_table :mi_plan_es_qc_comments, :es_qc_comments
    add_index :es_qc_comment, :name

    sql = <<-EOF
        --
        INSERT INTO es_cell_qc_statuses (name, description, order_by) VALUES 
        ('ES Cell Received' 'ES Cells have been received by the production centre', 100),
        ('ES Cell QC In Progress', 'The ES cells are currently being QCed by the production centre', 105),
        ('ES Cell QC Complete', 'ES cells have passed the QC phase and are ready for micro-injection', 110),
        ('ES Cell QC Failed', 'ES cells have failed the QC phase, and micro-injection cannot proceed', 90)
        
        --
        INSERT INTO gene_assignment_statuses (name, description, order_by) VALUES 
        ('Register Interest', 'Gene has been added to gene list as a gene of interest', 1),
        ('Conflict', 'More than one centre has shown an interest in this gene', 5),
        ('Assigned', 'Gene has been assigned into the production pipeline', 10),
        ('Withdrawn', 'Gene has been removed from the gene list as the gene is no longer a gene of interest', 15)
        
        --
        INSERT INTO gene_lists (name, description) VALUES
        ('ES Cell QC', 'Register genes to enter the ES Cell QC production pipeline'),
        ('Micro Injection', 'Register genes to enter the Micro-injection production pipeline'),
        ('Allele Modification', 'Register genes to enter the Allele Modification production pipeline'),
        ('Phenotyping', 'Register genes to enter the Pheotyping production pipeline')

        --
        INSERT INTO intentions (name, description) VALUES
        ('ES Cell QC', 'Intend to QC ES Cells'),
        ('ES Cell Micro Injection', 'Intend to produce mice via ES Cell Micro Injection'),
        ('CRIPSR Micro Injection', 'Intend to produce mice via CRISPR Micro Injection'),
        ('Allele Modification', 'Intend to produce mice via allele modification'),
        ('Phenotyping', 'Intend to pheotype existing mice')

        --
        INSERT INTO plans (gene_id, consortium_id, production_centre_id) VALUES
        SELECT DISTINCT gene_id, consortium_id, production_centre_id
        FROM mi_plans
        
        --
        INSERT INTO es_cell_qcs (plan_id, status_id, sub_project_id
                             number_of_es_cells_received, es_cells_received_on, es_cells_received_from_id,
                             number_of_es_cells_starting_qc, number_of_es_cells_passing_qc,
                             comment_id) 
        SELECT plans.id AS mi_plan_id, 
                             CASE WHEN es_cell_failed.id IS NOT NULL THEN 3
                                  WHEN es_cell_complete.id IS NOT NULL THEN 2
                                  WHEN es_cell_in_progress.id IS NOT NULL THEN 1 
                             END AS status_id,
                             mi_plans.sub_project_id
                             mi_plans.number_of_es_cells_received AS number_of_es_cells_received, mi_plans.es_cells_received_on AS es_cells_received_on, mi_plans.es_cells_received_from_id AS es_cells_received_from_id,
                             mi_plans.number_of_es_cells_starting_qc AS number_of_es_cells_starting_qc, mi_plans.number_of_es_cells_passing_qc AS number_of_es_cells_passing_qc,
                             mi_plans.comment_id AS comment_id
        FROM mi_plans
        JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
        LEFT JOIN mi_plan_status_stamps es_cell_in_progress ON es_cell_in_progress.mi_plan_id = mi_plans.id AND es_cell_in_progress.status_id = 8 
        LEFT JOIN mi_plan_status_stamps es_cell_complete ON es_cell_complete.mi_plan_id = mi_plans.id AND es_cell_complete.status_id = 9  
        LEFT JOIN mi_plan_status_stamps es_cell_failed ON es_cell_failed.mi_plan_id = mi_plans.id AND es_cell_failed.status_id = 10
        WHERE mi_plans.number_of_es_cells_starting_qc > 0 OR mi_plans.number_of_es_cells_received > 0

        --
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, es_cell_qc_status_id, updated_at, created_at) VALUES
        SELECT es_cell_qc.id, 
               CASE WHEN mi_plan_status_stamps.status_id = 8 THEN 1
                    WHEN mi_plan_status_stamps.status_id = 9 THEN 2
                    ELSE 3
               END, 
               mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
          FROM mi_plan_status_stamps
          JOIN mi_plans On mi_plans.id = mi_plan_status_stamps.mi_plan_id
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          JOIN es_cell_qcs ON es_cell_qcs.plan_id = plans.id
        WHERE mi_plan_status_stamps.status_id IN (8, 9, 10)


        --
--'ES Cell QC'
        INSERT INTO gene_assignment (plan_id, status_id, gene_list_id, assign, withdraw, conflict) VALUES
        SELECT plan.id,
        CASE WHEN max(p.new_status_id) IN (8, 9) THEN 4 ELSE 1 END AS status_id,
        1 AS gene_list_id,
        false AS assign,
        CASE WHEN max(p.new_status_id) IN (10) THEN true ELSE false END AS withdrawn,
        false AS conflict
        FROM (SELECT mi_plans.*, CASE WHEN mi_plans.status_id = 7 THEN 12 ELSE mi_plans.status_id END AS new_status_id FROM mi_plans) p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE p.status_id IN (8, 9, 10)
        GROUP BY plan.id

--'Micro Injection'
        INSERT INTO gene_assignment (plan_id, status_id, gene_list_id, assign, withdraw, conflict) VALUES
        SELECT plan.id,
        CASE WHEN max(p.new_status_id) IN (10, 11 ,12) THEN 4 ELSE 1 END AS status_id,
        AS gene_list_id,
        false AS assign,
        CASE WHEN max(p.new_status_id) IN (10, 11 ,12) THEN true ELSE false END AS withdrawn,
        false AS conflict
        FROM (SELECT mi_plans.*, CASE WHEN mi_plans.status_id = 7 THEN 12 ELSE mi_plans.status_id END AS new_status_id FROM mi_plans) p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        GROUP BY plan.id

--'Allele Modification'
        INSERT INTO gene_assignment (plan_id, status_id, gene_list_id, assign, withdraw, conflict) VALUES
        SELECT plan.id,
        CASE WHEN max(p.new_status_id) IN (10, 11 ,12) THEN 4 ELSE 1 END AS status_id,
        AS gene_list_id,
        false AS assign,
        CASE WHEN max(p.new_status_id) IN (10, 11 ,12) THEN true ELSE false END AS withdrawn,
        false AS conflict
        FROM (SELECT mi_plans.*, CASE WHEN mi_plans.status_id = 7 THEN 12 ELSE mi_plans.status_id END AS new_status_id FROM mi_plans) p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        GROUP BY plan.id

--'Phenotyping'
        INSERT INTO gene_assignment (plan_id, status_id, gene_list_id, assign, withdraw, conflict) VALUES
        SELECT plan.id,
        CASE WHEN max(p.new_status_id) IN (10, 11 ,12) THEN 4 ELSE 1 END AS status_id,
        AS gene_list_id,
        false AS assign,
        CASE WHEN max(p.new_status_id) IN (10, 11 ,12) THEN true ELSE false END AS withdrawn,
        false AS conflict
        FROM (SELECT mi_plans.*, CASE WHEN mi_plans.status_id = 7 THEN 12 ELSE mi_plans.status_id END AS new_status_id FROM mi_plans) p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        GROUP BY plan.id

        --
        INSERT INTO plan_intentions (plan_id,
          produce_mice, phenotype_mice, produce_mice_via_crispr_cas9_injection, produce_mice_via_mouse_allele_modification,
          produce_mice_via_es_cell_injection, priority_id,
          target_bespoke_allele, target_recovery_allele, target_conditional_allele, target_non_conditional_allele,
          target_cre_knock_in_allele, target_cre_bac_allele, target_point_mutation, conditional_point_mutation, target_deletion_allele,
          comment, completion_comment,
          ignore_available_mice, is_active, report_to_public) VALUES

        SELECT
          plans.id,
          CASE WHEN count(mi_attempts.id) > 0 OR bool_or(mi_plans.mutagenesis_via_crispr_cas9) == true THEN true ELSE false END AS produce_mice,
          CASE WHEN count(phenotyping_productions.id) OR bool_or(mi_plans.phenotype_only) = true AS phenotype_mice,
          CASE WHEN bool_or(mi_plans.mutagenesis_via_crispr_cas9) == true THEN true ELSE false END AS produce_mice_via_crispr_cas9_injection,
          CASE WHEN count(mouse_allele_mods.id) > 0 THEN true ELSE false END AS produce_mice_via_mouse_allele_modification,
          CASE WHEN count(mi_attempts.id) > 0 AND bool_or(mi_plans.mutagenesis_via_crispr_cas9) == false THEN true ELSE false END AS produce_mice_via_es_cell_injection,
          min(mi_plans.priority_id),
          bool_or(mi_plans.target_bespoke_allele),
          bool_or(mi_plans.target_recovery_allele),
          bool_or(mi_plans.target_conditional_allele),
          bool_or(mi_plans.target_non_conditional_allele),
          bool_or(mi_plans.target_cre_knock_in_allele),
          bool_or(mi_plans.target_cre_bac_allele),
          bool_or(mi_plans.target_point_mutation),
          bool_or(mi_plans.conditional_point_mutation),
          bool_or(mi_plans.target_deletion_allele),
          string_agg(mi_plans.comment, ', '),
          string_agg(mi_plans.completion_comment, ', '),
          bool_or(mi_plans.ignore_available_mice),
          bool_or(mi_plans.is_active),
          bool_or(mi_plans.report_to_public)

          FROM mi_plans
          LEFT JOIN mi_attempts ON mi_attempts.mi_plan_id = mi_plans.id
          LEFT JOIN mouse_allele_mods ON mouse_allele_mods.mi_plan_id = mi_plans.id
          LEFT JOIN phenotyping_productions ON phenotyping_productions.mi_plan_id = mi_plans.id
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          GROUP BY gene_id, consortium_id, production_centre_id, sub_project_id



        --
        UPDATE mi_attempts SET (sub_project_id, plan_id) = 
          SELECT (mi_plans.sub_project_id, plans.id)
          FROM mi_plans
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          WHERE mi_plans.id = mi_attempts.mi_plan_id
        --
        UPDATE mouse_allele_mods SET (sub_project_id, plan_id) = 
        SELECT (mi_plans.sub_project_id, plans.id)
          FROM mi_plans
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          WHERE mi_plans.id = mi_attempts.mi_plan_id
        --
        UPDATE phenotyping_productions SET (sub_project_id, plan_id) = 
        SELECT (mi_plans.sub_project_id, plans.id)
          FROM mi_plans
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          WHERE mi_plans.id = mi_attempts.mi_plan_id
    EOF


  end

  def self.down
    drop_table :planned_alleles

    remove_column :mi_attempts, :sub_project_id
    remove_column :mouse_allele_mods, :sub_project_id
    remove_column :phenotpying_production, :sub_project_id
  end


end
