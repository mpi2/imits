class GeneAssignmentChanges < ActiveRecord::Migration

  def self.up


    ### extract ES Cell QC into new table
    create_table :es_cell_qcs do |t|
      t.integer :mi_plan_id, :null => true
      t.integer :status_id, :null => true
      t.integer :sub_project_id, :null => true
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


    add_foreign_key :es_cell_qcs, :mi_plans
    add_foreign_key :es_cell_qcs, :ees_cell_qc_statuses

    add_foreign_key :es_cell_qc_status_stamps, :es_cell_qcs
    add_foreign_key :es_cell_qc_status_stamps, :es_cell_qc_statuses


    ### extract intentions of plans. i.e. are mice to be produced, are mice going to be phenotyped etc.
    create_table :plan_intentions do |t|
      t.integer :mi_plan_id, :null => true
      t.integer :sub_project_id
      t.boolean :produce_mice
      t.boolean :phenotype_mice
      t.boolean :produce_mice_via_crispr_cas9_injection
      t.boolean :produce_mice_via_mouse_allele_modification
      t.boolean :produce_mice_via_es_cell_injection
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
      t.boolean :is_active, :default => true, :null => false
      t.timestamps
    end
 
    add_column :mi_attempts, :sub_project_id, :integer
    add_column :mouse_allele_mods, :sub_project_id, :integer
    add_column :phenotyping_productions, :sub_project_id, :integer



    sql = <<-EOF
        --
        INSERT INTO es_cell_qc_statuses (name, description, order_by) VALUES 
        ('ES Cell QC In Progress', 'The ES cells are currently being QCed by the production centre', 100),
        ('ES Cell QC Complete', 'ES cells have passed the QC phase and are ready for micro-injection', 110),
        ('ES Cell QC Failed', 'ES cells have failed the QC phase, and micro-injection cannot proceed', 90)

        --
        INSERT INTO es_cell_qcs (mi_plan_id, status_id, sub_project_id
                             number_of_es_cells_received, es_cells_received_on, es_cells_received_from_id,
                             number_of_es_cells_starting_qc, number_of_es_cells_passing_qc,
                             comment_id) 
        SELECT mi_plans.id AS mi_plan_id, 
                             CASE WHEN es_cell_failed.id IS NOT NULL THEN 3
                                  WHEN es_cell_complete.id IS NOT NULL THEN 2
                                  WHEN es_cell_in_progress.id IS NOT NULL THEN 1 
                             END AS status_id,
                             mi_plans.sub_project_id
                             mi_plans.number_of_es_cells_received AS number_of_es_cells_received, mi_plans.es_cells_received_on AS es_cells_received_on, mi_plans.es_cells_received_from_id AS es_cells_received_from_id,
                             mi_plans.number_of_es_cells_starting_qc AS number_of_es_cells_starting_qc, mi_plans.number_of_es_cells_passing_qc AS number_of_es_cells_passing_qc,
                             mi_plans.comment_id AS comment_id
        FROM mi_plans
        LEFT JOIN mi_plan_status_stamps es_cell_in_progress ON es_cell_in_progress.mi_plan_id = mi_plans.id AND es_cell_in_progress.status_id = 8 
        LEFT JOIN mi_plan_status_stamps es_cell_complete ON es_cell_complete.mi_plan_id = mi_plans.id AND es_cell_complete.status_id = 9  
        LEFT JOIN mi_plan_status_stamps es_cell_failed ON es_cell_failed.mi_plan_id = mi_plans.id AND es_cell_failed.status_id = 10
        WHERE mi_plans.number_of_es_cells_starting_qc > 0 OR mi_plans.number_of_es_cells_received > 0

        --
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, es_cell_qc_status_id, updated_at, created_at) VALUES
        SELECT mi_plan_status_stamps.es_cell_qcs, 
               CASE WHEN mi_plan_status_stamps.status_id = 8 THEN 1
                    WHEN mi_plan_status_stamps.status_id = 9 THEN 2
                    ELSE 3
               END, 
               mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
          FROM mi_plan_status_stamps
          JOIN es_cell_qcs ON es_cell_qcs.mi_plan_id = mi_plan_status_stamps.mi_plan_id
        WHERE mi_plan_status_stamps.status_id IN (8, 9, 10)

        --
        INSERT INTO plan_intentions () VALUES
        SELECT
          FROM 

        DELETE FROM mi_plans
        WHERE mi_plans.id = (SELECT DISTINCT GREATEST(plan1.id, plan2.id) FROM mi_plans plan1 JOIN mi_plans plan2 ON plan1.id != plan2.id AND plan1.gene_id = plan2.gene_id AND plan1.consortium_id = plan2.consortium_id AND plan1.production_centre_id = plan2.production_centre_id)

        UPDATE plan_intentions


        --
        UPDATE mi_attempts SET sub_project_id = mi_plan.sub_project_id
          FROM mi_plans
          WHERE mi_plans.id = mi_attempts.mi_plan_id
        --
        UPDATE mouse_allele_mods SET sub_project_id = mi_plan.sub_project_id
          FROM mi_plans
          WHERE mi_plans.id = mi_attempts.mi_plan_id
        --
        UPDATE phenotyping_productions SET sub_project_id = mi_plan.sub_project_id
          FROM mi_plans
          WHERE mi_plans.id = mi_attempts.mi_plan_id
    EOF

 #   remove_column :mi_plans, :priority_id
 #   remove_column :mi_plans, :number_of_es_cells_starting_qc
 #   remove_column :mi_plans, :number_of_es_cells_passing_qc
 #   remove_column :mi_plans, :sub_project_id
 #   remove_column :mi_plans, :is_bespoke_allele
 #   remove_column :mi_plans, :is_conditional_allele
 #   remove_column :mi_plans, :is_deletion_allele
 #   remove_column :mi_plans, :is_cre_knock_in_allele
 #   remove_column :mi_plans, :is_cre_bac_allele
 #   remove_column :mi_plans, :comment
 #   remove_column :mi_plans, :es_qc_comment_id
 #   remove_column :mi_plans, :phenotype_only
 #   remove_column :mi_plans, :completion_note
 #   remove_column :mi_plans, :recovery
 #   remove_column :mi_plans, :conditional_tm1c
 #   remove_column :mi_plans, :number_of_es_cells_received
 #   remove_column :mi_plans, :es_cells_received_on
 #   remove_column :mi_plans, :es_cells_received_from_id
 #   remove_column :mi_plans, :point_mutation
 #   remove_column :mi_plans, :conditional_point_mutation
 #   remove_column :mi_plans, :allele_symbol_superscript
 #   remove_column :mi_plans, :report_to_public
 #   remove_column :mi_plans, :completion_comment
 #   remove_column :mi_plans, :mutagenesis_via_crispr_cas9





  end

  def self.down
    drop_table :planned_alleles

    remove_column :mi_attempts, :sub_project_id
    remove_column :mouse_allele_mods, :sub_project_id
    remove_column :phenotpying_production, :sub_project_id
  end


end
