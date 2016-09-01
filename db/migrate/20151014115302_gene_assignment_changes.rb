class GeneAssignmentChanges < ActiveRecord::Migration

  def self.up


    ### extract ES Cell QC into new table
    create_table :es_cell_qcs do |t|
      t.integer :plan_id, :null => false
      t.integer :sub_project_id, :null => true
      t.integer :priority_id, :null => true
      t.integer :status_id, :null => false
      t.boolean :bespoke_allele, :default => false, :null => false
      t.boolean :recovery_allele, :default => false, :null => false
      t.boolean :conditional_allele, :default => false, :null => false
      t.boolean :non_conditional_allele, :default => false, :null => false
      t.boolean :cre_knock_in_allele, :default => false, :null => false
      t.boolean :cre_bac_allele, :default => false, :null => false
      t.boolean :deletion_allele, :default => false, :null => false
      t.boolean :point_mutation_allele, :default => false, :null => false
      t.boolean :conditional_tm1c_allele, :default => false, :null => false
      t.boolean :conditional_point_mutation_allele, :default => false, :null => false
      t.text    :completion_comment
      t.string  :completion_note, :limit => 100
      t.integer :number_of_es_cells_received
      t.date    :es_cells_received_on
      t.integer :es_cells_received_from_id
      t.integer :number_of_es_cells_starting_qc
      t.integer :number_of_es_cells_passing_qc
      t.integer :comment_id
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

      table.timestamps
    end

    add_foreign_key :plan_intentions, :intentions
    add_foreign_key :plan_intentions, :plans
    add_foreign_key :plan_intentions, :plan_intention_statuses, :column => :status_id
    
    add_foreign_key :plan_intention_status_stamps, :plan_intentions
    add_foreign_key :plan_intention_status_stamps, :plan_intention_statuses, :column => :status_id

    add_column :mi_attempts, :sub_project_id, :integer 
    add_column :mouse_allele_mods, :sub_project_id, :integer
    add_column :phenotyping_productions, :sub_project_id, :integer

    add_column :mi_attempts, :plan_id, :integer
    add_column :mouse_allele_mods, :plan_id, :integer
    add_column :phenotyping_productions, :plan_id, :integer

    remove_index :mi_plan_priorities, column: :name
    rename_table :mi_plan_priorities, :es_cell_qc_priorities
    add_index :es_cell_qc_priorities, :name, unique: true
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
        ('ES Cell Micro Injection', 'Intend to produce mice via ES Cell Micro Injection'),
        ('CRISPR Micro Injection', 'Intend to produce mice via CRISPR Micro Injection'),
        ('Allele Modification', 'Intend to produce mice via allele modification'),
        ('Phenotyping', 'Intend to pheotype existing mice');

        --

        INSERT INTO plans(id, gene_id, consortium_id, production_centre_id)         
          SELECT max(id) AS id, gene_id, consortium_id, production_centre_id
          FROM mi_plans
          GROUP BY gene_id, consortium_id, production_centre_id;

        SELECT setval('plans_id_seq', (SELECT MAX(id) FROM plans));
        
        --
        INSERT INTO es_cell_qcs (plan_id, priority_id, status_id, sub_project_id,
                             number_of_es_cells_received, es_cells_received_on, es_cells_received_from_id,
                             number_of_es_cells_starting_qc, number_of_es_cells_passing_qc,
                             comment_id) 
        SELECT plans.id AS mi_plan_id, 
               mi_plans.priority_id AS priority_id,
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
        WHERE mi_plans.number_of_es_cells_starting_qc > 0 OR mi_plans.number_of_es_cells_received > 0 OR number_of_es_cells_received IS NOT NULL OR es_cells_received_on IS NOT NULL OR es_cells_received_from_id IS NOT NULL;

        --
          -- 'Insert ES Cell QC status stamps'
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, status_id, updated_at, created_at)
        SELECT es_cell_qcs.id, 
               CASE WHEN mi_plan_status_stamps.status_id = 8 THEN 2
                    WHEN mi_plan_status_stamps.status_id = 9 THEN 3
                    ELSE 4
               END, 
               mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
          FROM mi_plan_status_stamps
          JOIN mi_plans ON mi_plans.id = mi_plan_status_stamps.mi_plan_id
          JOIN plans ON plans.gene_id = mi_plans.gene_id AND plans.consortium_id = mi_plans.consortium_id AND plans.production_centre_id = mi_plans.production_centre_id
          JOIN es_cell_qcs ON es_cell_qcs.plan_id = plans.id
        WHERE mi_plan_status_stamps.status_id IN (8, 9, 10);

        --
          -- 'Insert received status stamps if received data given'
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, status_id, updated_at, created_at)
        SELECT es_cell_qcs.id, 
               1, 
               es_cell_qcs.es_cells_received_on, 
               es_cell_qcs.es_cells_received_on
          FROM es_cell_qcs
          WHERE es_cell_qcs.es_cells_received_on IS NOT NULL;

        --
          -- 'Insert received status stamps and set to qc started date if given'
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, status_id, updated_at, created_at)
        SELECT es_cell_qcs.id, 
               1, 
               es_cell_qc_status_stamps.updated_at, 
               es_cell_qc_status_stamps.created_at
          FROM es_cell_qcs
          JOIN es_cell_qc_status_stamps ON es_cell_qc_status_stamps.es_cell_qc_id = es_cell_qcs.id AND es_cell_qc_status_stamps.status_id = 2
          LEFT JOIN es_cell_qc_status_stamps AS es_cells_received ON es_cells_received.es_cell_qc_id = es_cell_qcs.id AND es_cells_received.status_id = 1
          WHERE es_cells_received.id IS NULL;

        --
          -- 'Set received status stamp to date mi_plan was created if es cell received data not given'
        INSERT INTO es_cell_qc_status_stamps (es_cell_qc_id, status_id, updated_at, created_at)
        SELECT es_cell_qcs.id, 
               1, 
               mi_plans.created_at, 
               mi_plans.created_at
          FROM es_cell_qcs
          JOIN plans ON plans.id = es_cell_qcs.plan_id
          JOIN mi_plans ON plans.id = mi_plans.id
          LEFT JOIN es_cell_qc_status_stamps AS es_cells_received ON es_cells_received.es_cell_qc_id = es_cell_qcs.id AND es_cells_received.status_id = 1
          WHERE es_cells_received.id IS NULL;

        --
--'ES Cell QC'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        max(p.sub_project_id) AS sub_project_id,
        CASE WHEN max(p.status_id) IN (8, 9, 10) THEN 2 ELSE 3 END AS status_id,
        1 AS intention_id,
        true AS assign,
        CASE WHEN max(p.status_id) IN (7, 11) THEN true ELSE false END AS withdrawn,
        false AS conflict
        FROM (SELECT DISTINCT mi_plans.id AS mi_plan_id FROM mi_plans JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = mi_plans.id AND mi_plan_status_stamps.status_id IN (8, 9, 10)) AS p_id
        JOIN mi_plans p ON p.id = p_id.mi_plan_id 
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        GROUP BY plans.id;

--'ES Cell QC Intention Status stamps Register Interest'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 1, p.updated_at, p.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE plan_intentions.intention_id = 1;

--'ES Cell QC Intention Status stamps assigned'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 2, mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = p.id
        WHERE plan_intentions.intention_id = 1 AND mi_plan_status_stamps.status_id IN (8);

--'ES Cell QC Intention Status stamps withdrawn'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 3, mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = p.id AND mi_plan_status_stamps.status_id = p.status_id
        WHERE plan_intentions.intention_id = 1 AND p.status_id IN (7, 11);


--'CRISPR Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        max(p.sub_project_id) AS sub_project_id,
        CASE WHEN bool_and(p.withdrawn OR p.is_active = false) = true THEN 3 
             WHEN bool_or(CASE WHEN ma.mi_plan_id IS NOT NULL THEN true ELSE false END) = true THEN 2
             ELSE 1 END AS status_id,
        3 AS intention_id,
        bool_or(CASE WHEN ma.mi_plan_id IS NOT NULL THEN true ELSE false END) AS assign,
        bool_and(p.withdrawn OR p.is_active = false) AS withdrawn,
        false AS conflict
        FROM mi_plans p
          JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          LEFT JOIN (SELECT DISTINCT mi_plan_id FROM mi_attempts) ma ON ma.mi_plan_id = p.id
        WHERE p.mutagenesis_via_crispr_cas9 = true
        GROUP BY plans.id;

--'CRISPR Micro Injection Status stamps Register Interest'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 1, p.updated_at, p.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE plan_intentions.intention_id = 3;

--'CRISPR Micro Injection Status stamps assigned'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 2, LEAST(mis.created_at, to_timestamp( to_char(mis.mi_date, 'DD Mon YYYY HH24:MI:SS'),'DD Mon YYYY HH24:MI:SS')), LEAST(mis.created_at, to_timestamp( to_char(mis.mi_date, 'DD Mon YYYY HH24:MI:SS'),'DD Mon YYYY HH24:MI:SS'))
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN (SELECT mi_plan_id, min(mi_date) AS mi_date, min(created_at) AS created_at FROM mi_attempts GROUP BY mi_plan_id) AS mis ON mis.mi_plan_id = p.id
        WHERE plan_intentions.intention_id = 3;

--'CRISPR Micro Injection Status stamps withdrawn'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 3, mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = p.id AND mi_plan_status_stamps.status_id = p.status_id
        WHERE plan_intentions.intention_id = 3 AND p.status_id IN (7, 11);


--'ES Cell Micro Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        max(p.sub_project_id) AS sub_project_id,
        CASE WHEN bool_and(p.withdrawn OR p.is_active = false) = true THEN 3 
             WHEN bool_or(CASE WHEN ma.mi_plan_id IS NOT NULL THEN true ELSE false END) = true THEN 2
             ELSE 1 END AS status_id,
        2 AS intention_id,
        bool_or(CASE WHEN ma.mi_plan_id IS NOT NULL THEN true ELSE false END) AS assign,
        bool_and(p.withdrawn OR p.is_active = false) AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM mi_attempts) ma ON ma.mi_plan_id = p.id
        WHERE p.mutagenesis_via_crispr_cas9 = false AND p.phenotype_only = false
        GROUP BY plans.id;


--'ES Cell Micro Injection Status stamps Register Interest'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 1, p.updated_at, p.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE plan_intentions.intention_id = 2;

--'ES Cell Micro Injection Status stamps assigned'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 2, LEAST(mis.created_at, to_timestamp( to_char(mis.mi_date, 'DD Mon YYYY HH24:MI:SS'),'DD Mon YYYY HH24:MI:SS')), LEAST(mis.created_at, to_timestamp( to_char(mis.mi_date, 'DD Mon YYYY HH24:MI:SS'),'DD Mon YYYY HH24:MI:SS'))
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN (SELECT mi_plan_id, min(mi_date) AS mi_date, min(created_at) AS created_at FROM mi_attempts GROUP BY mi_plan_id) AS mis ON mis.mi_plan_id = p.id
        WHERE plan_intentions.intention_id = 2;

--'ES Cell Micro Injection Status stamps withdrawn'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 3, mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = p.id AND mi_plan_status_stamps.status_id = p.status_id
        WHERE plan_intentions.intention_id = 2 AND p.status_id IN (7, 11);

--'Allele Modification Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        max(p.sub_project_id) AS sub_project_id,
        CASE WHEN bool_and(p.withdrawn OR p.is_active = false) = true THEN 3 
             ELSE 2 END AS status_id,
        4 AS intention_id,
        true AS assign,
        bool_and(p.withdrawn OR p.is_active = false) AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        JOIN (SELECT DISTINCT mi_plan_id FROM mouse_allele_mods) mam ON mam.mi_plan_id = p.id 
        WHERE mam.mi_plan_id IS NOT NULL
        GROUP BY plans.id;

--'Allele Modification Injection Status stamps Register Interest'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 1, p.updated_at, p.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE plan_intentions.intention_id = 4;

--'Allele Modification Injection Status stamps assigned'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 2, mams.created_at, mams.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN (SELECT mi_plan_id, min(created_at) AS created_at FROM mouse_allele_mods GROUP BY mi_plan_id) AS mams ON mams.mi_plan_id = p.id
        WHERE plan_intentions.intention_id = 4;

--'Allele Modification Injection Status stamps withdrawn'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 3, mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = p.id AND mi_plan_status_stamps.status_id = p.status_id
        WHERE plan_intentions.intention_id = 4 AND p.status_id IN (7, 11);

--'Phenotyping Injection'
        INSERT INTO plan_intentions (plan_id, sub_project_id, status_id, intention_id, assign, withdrawn, conflict)
        SELECT plans.id,
        max(p.sub_project_id) AS sub_project_id,
        CASE WHEN bool_and(p.withdrawn OR p.is_active = false) = true THEN 3 
             WHEN bool_or(CASE WHEN pp.mi_plan_id IS NOT NULL THEN true ELSE false END) = true THEN 2
             ELSE 1 END AS status_id,
        5 AS intention_id,
        bool_or(CASE WHEN pp.mi_plan_id IS NOT NULL THEN true ELSE false END) AS assign,
        bool_and(p.withdrawn OR p.is_active = false) AS withdrawn,
        false AS conflict
        FROM mi_plans p
        JOIN plans ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        LEFT JOIN (SELECT DISTINCT mi_plan_id FROM phenotyping_productions) pp ON pp.mi_plan_id = p.id
        WHERE ((p.phenotype_only = true AND pp.mi_plan_id IS NULL) OR pp.mi_plan_id IS NOT NULL)
        GROUP BY plans.id;

--'Phenotyping Injection Status stamps Register Interest'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 1, p.updated_at, p.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
        WHERE plan_intentions.intention_id = 5;

--'Phenotyping Injection Status stamps assigned'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 2, pps.created_at, pps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN (SELECT mi_plan_id, min(created_at) AS created_at FROM phenotyping_productions GROUP BY mi_plan_id) AS pps ON pps.mi_plan_id = p.id
        WHERE plan_intentions.intention_id = 5;

--'Phenotyping Injection Status stamps withdrawn'
        INSERT INTO plan_intention_status_stamps (plan_intention_id, status_id, updated_at, created_at)
        SELECT plan_intentions.id, 3, mi_plan_status_stamps.updated_at, mi_plan_status_stamps.created_at
        FROM plan_intentions
          JOIN plans ON plans.id = plan_intentions.plan_id
          JOIN mi_plans p ON plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id
          JOIN mi_plan_status_stamps ON mi_plan_status_stamps.mi_plan_id = p.id AND mi_plan_status_stamps.status_id = p.status_id
        WHERE plan_intentions.intention_id = 5 AND p.status_id IN (7, 11);

--'UPDATE Allele Intentions'
        UPDATE es_cell_qcs SET (bespoke_allele, recovery_allele, conditional_allele, cre_knock_in_allele, cre_bac_allele, deletion_allele, conditional_tm1c_allele, conditional_point_mutation_allele, point_mutation_allele) = (p.bespoke_allele, p.recovery_allele, p.conditional_allele, p.cre_knock_in_allele, p.cre_bac_allele, p.deletion_allele, p.point_mutation, p.conditional_tm1c, p.conditional_point_mutation)
        FROM plans, 
               (SELECT consortium_id, production_centre_id, gene_id, 
                  bool_or(is_bespoke_allele) AS bespoke_allele,
                  bool_or(CASE WHEN recovery IS NULL THEN false ELSE recovery END) AS recovery_allele,
                  bool_or(is_conditional_allele) AS conditional_allele,
                  bool_or(is_deletion_allele) AS deletion_allele,
                  bool_or(is_cre_knock_in_allele) AS cre_knock_in_allele,
                  bool_or(is_cre_bac_allele) AS cre_bac_allele,
                  bool_or(conditional_tm1c) AS conditional_tm1c,
                  bool_or(point_mutation) AS point_mutation,
                  bool_or(conditional_point_mutation) AS conditional_point_mutation
                FROM mi_plans 
                WHERE phenotype_only != true
                GROUP BY consortium_id, production_centre_id, gene_id) AS p
          WHERE plans.id = es_cell_qcs.plan_id AND plans.gene_id = p.gene_id AND plans.consortium_id = p.consortium_id AND plans.production_centre_id = p.production_centre_id;
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
