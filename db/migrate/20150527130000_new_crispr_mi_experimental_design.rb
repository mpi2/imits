class NewCrisprMiExperimentalDesign < ActiveRecord::Migration

  def self.up

    create_table :gene_targets do |t|
      t.integer :mi_plan_id, :null => false
      t.integer :mi_attempt_id, :null => false
    end

    create_table :colony_alleles do |t|
      t.integer :colony_id, :null => false
      t.integer :mutagenesis_factor_id, :null => true
    end

    add_column :colony_qcs, :colony_allele_id, :integer
    add_column :trace_calls, :gene_target_id, :integer
    add_column :mutagenesis_factors, :gene_target_id, :integer

    add_foreign_key :gene_targets, :mi_plans
    add_foreign_key :gene_targets, :mi_attempts

    add_foreign_key :mutagenesis_factors, :gene_targets

    add_foreign_key :colony_alleles, :colonies
    add_foreign_key :colony_alleles, :mutagenesis_factors

    add_foreign_key :colony_qcs, :colony_alleles
    add_foreign_key :trace_calls, :gene_targets

    sql = <<-EOF

        INSERT INTO gene_targets (mi_plan_id, mi_attempt_id)
        SELECT mi_plans.id, mi_attempts.id
        FROM mi_attempts
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id;

        INSERT INTO colony_alleles (colony_id, mutagenesis_factor_id)
        SELECT colonies.id, mi_attempts.mutagenesis_factor_id
        FROM colonies
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id;

        UPDATE mutagenesis_factors SET gene_target_id = tmp.gene_target_id
        FROM (SELECT gene_targets.id AS gene_target_id, mi_attempts.mutagenesis_factor_id AS mutagenesis_factor_id FROM mi_attempts JOIN gene_targets ON gene_targets.mi_attempt_id = mi_attempts.id) AS tmp
        WHERE mutagenesis_factors.id = tmp.mutagenesis_factor_id;

        UPDATE colony_qcs SET colony_allele_id = colony_alleles.id
        FROM colony_alleles
        WHERE colony_alleles.colony_id = colony_qcs.colony_id;

        UPDATE trace_calls SET gene_target_id = gene_targets.id
        FROM colonies
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
        JOIN gene_targets ON gene_targets.mi_attempt_id = mi_attempts.id
        WHERE colonies.id = trace_calls.colony_id;

    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :mutagenesis_factor_id
    remove_column :mi_attempts, :mi_plan_id

    remove_column :colony_qcs, :colony_id
    remove_column :trace_calls, :colony_id

  end



  def self.down

    puts "You're now in trouble. This was a one way migration"

  end

end