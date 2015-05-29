class NewCrisprMiExperimentalDesign < ActiveRecord::Migration

  def self.up
    add_column :mutagenesis_factors, :mi_attempt_id, :integer
    add_column :mutagenesis_factors, :gene_target_id, :integer
    add_column :colony_qcs, :mutagenesis_factor_id, :integer
    add_column :trace_calls, :mutagenesis_factor_id, :integer

    create_table :gene_targets do |t|
      t.integer :mi_plan_id, :null => false
      t.integer :mi_attempt_id, :null => false
    end

    create_table :colony_alleles do |t|
      t.integer :colony_id, :null => false
      t.integer :gene_target_id, :null => true
      t.integer :real_allele_id, :null => true
    end

    add_foreign_key :mutagenesis_factors, :mi_attempts
    add_foreign_key :mutagenesis_factors, :gene_targets
    add_foreign_key :colony_qcs, :mutagenesis_factors
    add_foreign_key :trace_calls, :mutagenesis_factors

    add_foreign_key :gene_targets, :mi_plans
    add_foreign_key :gene_targets, :mi_attempts

    add_foreign_key :colony_alleles, :colonies
    add_foreign_key :colony_alleles, :gene_targets
    add_foreign_key :colony_alleles, :targ_rep_real_alleles, :column => :real_allele_id, :name => 'colony_alleles_real_allele_fk'


    sql = <<-EOF

        INSERT INTO gene_targets (mi_plan_id, mi_attempt_id)
        SELECT mi_plans.id, mi_attempts.id
        FROM mi_attempts
        JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id;

        INSERT INTO colony_alleles (colony_id, gene_target_id)
        SELECT colonies.id, gene_targets.id
        FROM colonies
        JOIN mi_attempts ON mi_attempts.id = colonies.mi_attempt_id
        JOIN gene_targets ON gene_targets.mi_attempt_id = mi_attempts.id;

        UPDATE mutagenesis_factors SET mi_attempt_id = mi_attempts.id, gene_target_id = gene_targets.id
        FROM mi_attempts, gene_targets
        WHERE mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id AND gene_targets.mi_attempt_id = mi_attempts.id;

        UPDATE colony_qcs SET mutagenesis_factor_id = tmp.mutagenesis_factor_id
        FROM (SELECT colonies.id AS colony_id, mi_attempts.mutagenesis_factor_id AS mutagenesis_factor_id FROM mi_attempts JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id) AS tmp
        WHERE tmp.colony_id = colony_qcs.colony_id;

        UPDATE trace_calls SET mutagenesis_factor_id = tmp.mutagenesis_factor_id
        FROM (SELECT colonies.id AS colony_id, mi_attempts.mutagenesis_factor_id AS mutagenesis_factor_id FROM mi_attempts JOIN colonies ON colonies.mi_attempt_id = mi_attempts.id) AS tmp
        WHERE tmp.colony_id = trace_calls.colony_id;

        DELETE FROM targ_rep_crisprs WHERE id IN (SELECT targ_rep_crisprs.id FROM targ_rep_crisprs JOIN mutagenesis_factors ON mutagenesis_factors.id = targ_rep_crisprs.mutagenesis_factor_id WHERE mutagenesis_factors.mi_attempt_id IS NULL);

        DELETE FROM targ_rep_genotype_primers WHERE id IN (SELECT targ_rep_genotype_primers.id FROM targ_rep_genotype_primers JOIN mutagenesis_factors ON mutagenesis_factors.id = targ_rep_genotype_primers.mutagenesis_factor_id WHERE mutagenesis_factors.mi_attempt_id IS NULL);

        DELETE FROM mutagenesis_factors WHERE mi_attempt_id IS NULL;
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :mutagenesis_factor_id
#    remove_column :mi_attempts, :mi_plan_id

    change_column :mutagenesis_factors, :mi_attempt_id, :integer, :null => false
    change_column :mutagenesis_factors, :gene_target_id, :integer, :null => false
    change_column :trace_calls, :mutagenesis_factor_id, :integer, :null => false

  end



  def self.down

    remove_foreign_key :mutagenesis_factors, :mi_attempts
    remove_foreign_key :mutagenesis_factors, :gene_targets
    remove_foreign_key :colony_qcs, :mutagenesis_factors
    remove_foreign_key :trace_calls, :mutagenesis_factors

    remove_foreign_key :gene_targets, :mi_plans
    remove_foreign_key :gene_targets, :mi_attempts

    remove_foreign_key :colony_alleles, :colonies
    remove_foreign_key :colony_alleles, :gene_targets
    remove_foreign_key :colony_alleles, :name => 'colony_alleles_real_allele_fk'

    remove_column :mutagenesis_factors, :mi_attempt_id
    remove_column :mutagenesis_factors, :gene_target_id
    remove_column :colony_qcs, :mutagenesis_factor_id
    remove_column :trace_calls, :mutagenesis_factor_id

    drop_table :gene_targets
    drop_table :colony_alleles

    add_column :mi_attempts, :mutagenesis_factor_id
    add_column :mi_attempts, :mi_plan_id
  end

end