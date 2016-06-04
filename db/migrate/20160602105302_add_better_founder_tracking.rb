class AddBetterFounderTracking < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :voltage, :float
    add_column :mi_attempts, :number_of_pulses, :integer
    add_column :mi_attempts, :crsp_embryo_transfer_day, :string, :default => 'Same Day'
    add_column :mi_attempts, :crsp_embryo_2_cell, :integer


    add_column :mutagenesis_factors, :no_g0_where_mutation_detected, :integer
    add_column :mutagenesis_factors, :no_nhej_g0_mutants, :integer
    add_column :mutagenesis_factors, :no_deletion_g0_mutants, :integer
    add_column :mutagenesis_factors, :no_hr_g0_mutants, :integer
    add_column :mutagenesis_factors, :no_hdr_g0_mutants, :integer
    add_column :mutagenesis_factors, :no_hdr_g0_mutants_all_donors_inserted, :integer
    add_column :mutagenesis_factors, :no_hdr_g0_mutants_subset_donors_inserted, :integer


    sql = <<-EOF
      UPDATE mutagenesis_factors SET no_nhej_g0_mutants = mi_attempts.crsp_total_num_mutant_founders
      FROM mi_attempts
      WHERE mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id AND allele_target = 'NHEJ';

      UPDATE mutagenesis_factors SET no_deletion_g0_mutants = mi_attempts.crsp_total_num_mutant_founders
      FROM mi_attempts
      WHERE mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id AND allele_target = 'Deletion';

      UPDATE mutagenesis_factors SET no_hr_g0_mutants = mi_attempts.crsp_total_num_mutant_founders
      FROM mi_attempts
      WHERE mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id AND allele_target = 'HR';

      UPDATE mutagenesis_factors SET (no_hdr_g0_mutants, no_hdr_g0_mutants_all_donors_inserted) = (mi_attempts.crsp_total_num_mutant_founders, mi_attempts.crsp_total_num_mutant_founders)
      FROM mi_attempts
      WHERE mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id AND allele_target = 'HDR';

      UPDATE mutagenesis_factors SET no_g0_where_mutation_detected = mi_attempts.crsp_total_num_mutant_founders
      FROM mi_attempts
      WHERE mi_attempts.mutagenesis_factor_id = mutagenesis_factors.id AND (allele_target IS NULL OR allele_target = '');
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :crsp_total_num_mutant_founders
  end

  def self.down
    add_column :mi_attempts, :crsp_total_num_mutant_founders, :integer

    sql = <<-EOF
      UPDATE mi_attempts SET crsp_total_num_mutant_founders = max(mutagenesis_factors.no_g0_where_mutation_detected, mutagenesis_factors.no_nhej_g0_mutants, mutagenesis_factors.no_deletion_g0_mutants, mutagenesis_factors.no_hr_g0_mutants, mutagenesis_factors.no_hdr_g0_mutants)
      FROM mutagenesis_factors
      WHERE mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :voltage
    remove_column :mi_attempts, :number_of_pulses
    remove_column :mi_attempts, :embryo_transfer_day
    remove_column :mi_attempts, :embryo_2_cell

    remove_column :mutagenesis_factors, :no_g0_where_mutation_detected
    remove_column :mutagenesis_factors, :no_nhej_g0_mutants
    remove_column :mutagenesis_factors, :no_deletion_g0_mutants
    remove_column :mutagenesis_factors, :no_hr_g0_mutants
    remove_column :mutagenesis_factors, :no_hdr_g0_mutants
    remove_column :mutagenesis_factors, :no_hdr_g0_mutants_all_donors_inserted
    remove_column :mutagenesis_factors, :no_hdr_g0_mutants_subset_donors_inserted
  end

    

end
