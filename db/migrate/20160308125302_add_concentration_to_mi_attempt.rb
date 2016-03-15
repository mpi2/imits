class AddConcentrationToMiAttempt < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :individually_set_grna_concentrations, :boolean, :null => false, :default => false
    add_column :mi_attempts, :grna_conentration, :float
    add_column :mi_attempts, :nuclease_concentration, :float
    add_column :mi_attempts, :nuclease, :string

    add_column :mutagenesis_factors, :vector_oligo_concentration, :float

    add_column :targ_rep_crisprs, :grna_conentration, :float

    sql = <<-EOF
      UPDATE mi_attempts SET (nuclease) = (mutagenesis_factors.nuclease)
      FROM mutagenesis_factors
      WHERE mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mutagenesis_factors, :nuclease
  end

  def self.down
    remove_column :mi_attempts, :individually_set_grna_concentrations
    remove_column :mi_attempts, :grna_conentration
    remove_column :mi_attempts, :nuclease_concentration

    remove_column :mutagenesis_factors, :vector_oligo_concentration

    remove_column :targ_rep_crisprs, :grna_conentration

    add_column :mutagenesis_factors, :nuclease, :string

    sql = <<-EOF
      UPDATE mutagenesis_factors SET (nuclease) = (mi_attempts.nuclease)
      FROM mi_attempts
      WHERE mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id
    EOF

    ActiveRecord::Base.connection.execute(sql)

    remove_column :mi_attempts, :nuclease
  end


end
