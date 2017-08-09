class AddOligoSequenceToMutagenesisFactorDonor < ActiveRecord::Migration

  def self.up

    rename_table :mutagenesis_factor_vectors, :mutagenesis_factor_donors
    add_column :mutagenesis_factor_donors, :oligo_sequence_fa, :text 

    sql = <<-EOF

      ----
      UPDATE mutagenesis_factor_donors SET oligo_sequence_fa = targ_rep_alleles.sequence, vector_id = null
      FROM targ_rep_targeting_vectors, targ_rep_alleles
      WHERE targ_rep_targeting_vectors.id = mutagenesis_factor_donors.vector_id AND targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id AND targ_rep_alleles.sequence IS NOT NULL
      ;

    EOF

    ActiveRecord::Base.connection.execute(sql)
  end
end
