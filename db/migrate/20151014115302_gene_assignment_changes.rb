class GeneAssignmentChanges < ActiveRecord::Migration

  def self.up


    ### extract ES Cell QC into new table
    create_table :es_cell_qcs do |t|
      t.integer :plan_id, :null => false
      t.integer :sub_project_id, :null => true
      t.integer :status_id, :null => false
      t.integer :number_of_es_cells_received
      t.date    :es_cells_received_on
      t.integer :es_cells_received_from_id
      t.integer :number_of_es_cells_starting_qc
      t.integer :number_of_es_cells_passing_qc
      t.integer :comment_id
#      t.timestamps
    end

    create_table :es_cell_qc_statuses do |t|
      t.string :name, :limit => 50, :null => false
      t.string :description, :limit => 255
      t.integer :order_by
    end
    add_index :es_cell_qc_statuses, :name, :unique => true

    create_table :es_cell_qc_status_stamps do |table|
      table.integer :es_cell_qc_id, :null => false
      table.integer :status_id, :null => false
      table.timestamps
    end

    create_table :intentions do |t|
      t.string :name, :null => false
      t.string :description, :limit => 255
    end

    create_table :plans do |t|
      t.integer :gene_id, :null => false
      t.integer :consortium_id
      t.integer :production_centre_id
    end


    add_foreign_key :es_cell_qcs, :plans
    add_foreign_key :es_cell_qcs, :es_cell_qc_statuses, :column => :status_id

    add_foreign_key :es_cell_qc_status_stamps, :es_cell_qcs
    add_foreign_key :es_cell_qc_status_stamps, :es_cell_qc_statuses, :column => :status_id


    ### extract intentions of plans. i.e. are mice to be produced, are mice going to be phenotyped etc.
    create_table :plan_intentions do |t|
      t.integer :plan_id, :null => false
      t.integer :sub_project_id, :null => true
      t.integer :status_id, :null => false
      t.integer :intention_id, :null => false

      t.boolean :assign, :default => false, :null => false
      t.boolean :conflict, :default => false, :null => false
      t.boolean :withdrawn, :default => false, :null => false

      t.text    :comment
      t.text    :completion_comment
      t.boolean :ignore_available_mice, :default => false, :null => false
      t.boolean :report_to_public,:default => true, :null => false
#      t.timestamps
    end

    create_table :plan_intention_statuses do |t|
      t.string :name, :limit => 50, :null => false
      t.string :description, :limit => 255
      t.integer :order_by
    end
    add_index :plan_intention_statuses, :name, :unique => true

    create_table :plan_intention_status_stamps do |table|
      table.integer :plan_intention_id, :null => false
      table.integer :status_id, :null => false

#      table.timestamps
    end

    add_foreign_key :plan_intentions, :intentions
    add_foreign_key :plan_intentions, :plans
    add_foreign_key :plan_intentions, :plan_intention_statuses, :column => :status_id
    
    add_foreign_key :plan_intention_status_stamps, :plan_intentions
    add_foreign_key :plan_intention_status_stamps, :plan_intention_statuses, :column => :status_id

    create_table :plan_intention_allele_intentions do |t|
      t.integer :plan_intention_id, :null => false
      t.integer :priority_id, :null => true
      t.boolean :bespoke_allele, :default => false, :null => false
      t.boolean :recovery_allele, :default => false, :null => false
      t.boolean :conditional_allele, :default => false, :null => false
      t.boolean :non_conditional_allele, :default => false, :null => false
      t.boolean :cre_knock_in_allele, :default => false, :null => false
      t.boolean :cre_bac_allele, :default => false, :null => false

      t.boolean :deletion_allele, :default => false, :null => false
      t.boolean :point_mutation, :default => false, :null => false
      t.text :comment
  #    t.timestamps
    end
 
    add_column :mi_attempts, :sub_project_id, :integer 
    add_column :mouse_allele_mods, :sub_project_id, :integer
    add_column :phenotyping_productions, :sub_project_id, :integer

    add_column :mi_attempts, :plan_id, :integer
    add_column :mouse_allele_mods, :plan_id, :integer
    add_column :phenotyping_productions, :plan_id, :integer

    remove_index :mi_plan_priorities, column: :name
    rename_table :mi_plan_priorities, :plan_intention_allele_intention_priorities
    add_index :plan_intention_allele_intention_priorities, :name, unique: true
#    remove_index :mi_plan_logical_key
#    rename_table :mi_plans, :plans
#    add_index :plan, [:gene_id, :consortium_id, :production_centre_id, :sub_project_id], unique: true, name: 'plan_logical_key'
    remove_index :mi_plan_es_qc_comments, column:  :name
    rename_table :mi_plan_es_qc_comments, :es_cell_qc_comments
    add_index :es_cell_qc_comments, :name, unique: true

    rename_table :mi_plan_sub_projects, :sub_projects

    sql = <<-EOF
        --
        INSERT INTO es_cell_qc_statuses (name, description, order_by) VALUES 
        ('ES Cell Received', 'ES Cells have been received by the production centre', 100),
        ('ES Cell QC In Progress', 'The ES cells are currently being QCed by the production centre', 105),
        ('ES Cell QC Complete', 'ES cells have passed the QC phase and are ready for micro-injection', 110),
        ('ES Cell QC Failed', 'ES cells have failed the QC phase, and micro-injection cannot proceed', 90);
        
        --
        INSERT INTO plan_intention_statuses (name, description, order_by) VALUES 
        ('Register Interest', 'Gene has been added to gene list as a gene of interest', 1),
        ('Assigned', 'Gene has been assigned into the production pipeline', 10),
        ('Withdrawn', 'Gene has been removed from the gene list as the gene is no longer a gene of interest', 15);
        
        --
        INSERT INTO intentions (name, description) VALUES
        ('ES Cell QC', 'Intend to QC ES Cells'),
        ('Mouse Production', 'Intend to produce mice via Micro Injection'),
        ('ES Cell Micro Injection', 'Intend to produce mice via ES Cell Micro Injection'),
        ('CRIPSR Micro Injection', 'Intend to produce mice via CRISPR Micro Injection'),
        ('Allele Modification', 'Intend to produce mice via allele modification'),
        ('Phenotyping', 'Intend to pheotype existing mice');

        --

        INSERT INTO plans(id, gene_id, consortium_id, production_centre_id)         
          SELECT max(id) AS id, gene_id, consortium_id, production_centre_id
          FROM mi_plans
          GROUP BY gene_id, consortium_id, production_centre_id;

        SELECT setval('plans_id_seq', (SELECT MAX(id) FROM plans));
        
        --
        INSERT INTO es_cell_qcs (plan_id, status_id, sub_project_id,
                             number_of_es_cells_received, es_cells_received_on, es_cells_received_from_id,
                             number_of_es_cells_starting_qc, number_of_es_cells_passing_qc,
                             comment_id) 
        SELECT plans.id AS mi_plan_id, 
                             CASE WHEN es_cell_failed.id IS NOT NULL THEN 4
                                  WHEN es_cell_complete.id IS NOT NULL THEN 3
                                  WHEN es_cell_in_progress.id IS NOT NULL THEN 2
                                  ELSE 1
                             END AS status_id,
                             mi_plans.sub_project_id,
                             mi_plans.number_of_es_cells_received AS number_of_es_cells_received, mi_plans.es_cells_received_on AS es_cells_received_on, mi_plans.es_cells_received_from_id AS es_cells_received_from_id,
                             mi_plans.number_of_es_cells_starting_qc AS number_of_es_cells_starting_qc, mi_plans.number_of_es_cells_passing_qc AS number_of_es_cells_passing_qc,
                             mi_plans.es_qc_comment_id AS comment_id
        FROM mi_plans
        JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
        LEFT JOIN mi_plan_status_stamps es_cell_in_progress ON es_cell_in_progress.mi_plan_id = mi_plans.id AND es_cell_in_progress.status_id = 8 
        LEFT JOIN mi_plan_status_stamps es_cell_complete ON es_cell_complete.mi_plan_id = mi_plans.id AND es_cell_complete.status_id = 9  
        LEFT JOIN mi_plan_status_stamps es_cell_failed ON es_cell_failed.mi_plan_id = mi_plans.id AND es_cell_failed.status_id = 10
        WHERE mi_plans.number_of_es_cells_starting_qc > 0 OR mi_plans.number_of_es_cells_received > 0;

        --
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, status_id, updated_at, created_at)
        SELECT es_cell_qcs.id, 
               CASE WHEN mi_plan_status_stamps.status_id = 8 THEN 1
                    WHEN mi_plan_status_stamps.status_id = 9 THEN 2
                    ELSE 3
               END, 
               mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
          FROM mi_plan_status_stamps
          JOIN mi_plans On mi_plans.id = mi_plan_status_stamps.mi_plan_id
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          JOIN es_cell_qcs ON es_cell_qcs.plan_id = plans.id
        WHERE mi_plan_status_stamps.status_id IN (8, 9, 10);


        --
--'ES Cell QC'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        CASE WHEN max(p.new_status_id) IN (8, 9) THEN 3 ELSE 4 END AS status_id,
        1 AS intention_id,
        CASE WHEN max(p.new_status_id) IN (10) THEN false ELSE true END AS assign,
        CASE WHEN max(p.new_status_id) IN (10) THEN true ELSE false END AS withdrawn,
        false AS conflict
        FROM (SELECT mi_plans.*, CASE WHEN mi_plans.status_id = 7 THEN 12 ELSE mi_plans.status_id END AS new_status_id FROM mi_plans) p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE p.status_id IN (8, 9, 10)
        GROUP BY plans.id, p.sub_project_id;

--'CRISPR Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        3 AS status_id,
        4 AS intention_id,
        true AS assign,
        false AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM mi_attempts) ma ON ma.mi_plan_id = p.id 
        WHERE p.mutagenesis_via_crispr_cas9 = true AND p.is_active = true AND p.withdrawn = false
        GROUP BY plans.id, p.sub_project_id;

--'Withdrawn CRISPR Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        3 AS status_id,
        4 AS intention_id,
        false AS assign,
        true AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM mi_attempts) ma ON ma.mi_plan_id = p.id 
        WHERE p.mutagenesis_via_crispr_cas9 = true AND (p.is_active = false OR p.withdrawn = true)
        GROUP BY plans.id, p.sub_project_id;

--'Register Interest ES Cell Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        1 AS status_id,
        3 AS intention_id,
        false AS assign,
        false AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM mi_attempts) ma ON ma.mi_plan_id = p.id
        WHERE p.mutagenesis_via_crispr_cas9 = false AND p.phenotype_only = false AND ma.mi_plan_id IS NULL AND p.is_active = true AND p.withdrawn = false
        GROUP BY plans.id, p.sub_project_id;

--'ES Cell Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        3 status_id,
        3 AS intention_id,
        true AS assign,
        false AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM mi_attempts) ma ON ma.mi_plan_id = p.id
        WHERE p.mutagenesis_via_crispr_cas9 = false AND p.phenotype_only = false AND ma.mi_plan_id IS NOT NULL AND p.is_active = true AND p.withdrawn = false
        GROUP BY plans.id, p.sub_project_id;


--'Withdrawn ES Cell Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        4 AS status_id,
        3 AS intention_id,
        false AS assign,
        true AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE p.mutagenesis_via_crispr_cas9 = false AND p.phenotype_only = false AND (p.is_active = false OR p.withdrawn = true)
        GROUP BY plans.id, p.sub_project_id;

--'Allele Modification'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        3 AS status_id,
        5 AS intention_id,
        true AS assign,
        false AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        JOIN (SELECT DISTINCT mi_plan_id FROM mouse_allele_mods) mam ON mam.mi_plan_id = p.id 
        WHERE mam.mi_plan_id IS NOT NULL AND p.is_active = true AND p.withdrawn = false
        GROUP BY plans.id, p.sub_project_id;

--'Withdrawn Allele Modification'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        4 AS status_id,
        5 AS intention_id,
        false AS assign,
        true AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        JOIN (SELECT DISTINCT mi_plan_id FROM mouse_allele_mods) mam ON mam.mi_plan_id = p.id 
        WHERE mam.mi_plan_id IS NOT NULL AND (p.is_active = false OR p.withdrawn = true)
        GROUP BY plans.id, p.sub_project_id;

--'Phenotyping'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        3 AS status_id,
        6 AS intention_id,
        true AS assign,
        false AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM phenotyping_productions) pp ON pp.mi_plan_id = p.id
        WHERE ((p.phenotype_only = true AND pp.mi_plan_id IS NULL) OR pp.mi_plan_id IS NOT NULL) AND p.is_active = true AND p.withdrawn = false
        GROUP BY plans.id, p.sub_project_id;

--'Withdrawn Phenotyping'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        p.sub_project_id,
        4 AS status_id,
        6 AS intention_id,
        false AS assign,
        true AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM phenotyping_productions) pp ON pp.mi_plan_id = p.id
        WHERE ((p.phenotype_only = true AND pp.mi_plan_id IS NULL) OR pp.mi_plan_id IS NOT NULL) AND (p.is_active = false OR p.withdrawn = true)
        GROUP BY plans.id, p.sub_project_id;

        --
        UPDATE mi_attempts SET (plan_id, sub_project_id) = (plans.id, mi_plans.sub_project_id)
          FROM mi_plans, plans
          WHERE mi_plans.id = mi_attempts.mi_plan_id AND plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id;
        --
        UPDATE mouse_allele_mods SET (plan_id, sub_project_id) = (plans.id, mi_plans.sub_project_id)
          FROM mi_plans, plans
          WHERE mi_plans.id = mouse_allele_mods.mi_plan_id AND plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id;
        --
        UPDATE phenotyping_productions SET (plan_id, sub_project_id) = (plans.id, mi_plans.sub_project_id)
          FROM mi_plans, plans
          WHERE mi_plans.id = phenotyping_productions.mi_plan_id AND plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id;
    EOF

    ActiveRecord::Base.connection.execute(sql)


  end

  def self.down

  end


end
