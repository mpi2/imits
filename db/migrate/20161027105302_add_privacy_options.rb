class AddPrivacyOptions < ActiveRecord::Migration

  def self.up
    add_column :targ_rep_alleles, :private, :boolean, :default => false, :null => false
    add_column :colonies, :private, :boolean, :default => false, :null => false
    add_column :mutagenesis_factors, :private, :boolean, :default => false, :null => false
    add_column :mi_attempts, :privacy, :string, :default => 'Share all Allele(s)', :null => false
    add_column :targ_rep_alleles, :production_centre_id, :integer
    add_column :colonies, :crispr_allele_category, :string

    sql = <<-EOF
      UPDATE mi_attempts SET privacy = 'Share all Allele(s)';

      WITH es_cell_production_centre AS (
      	SELECT targ_rep_es_cells.allele_id AS allele_id, FIRST_VALUE(substring(targ_rep_es_cells.mgi_allele_symbol_superscript from '\\)(.+)$')) OVER (PARTITION BY targ_rep_es_cells.allele_id) AS mgi_centre
      	FROM targ_rep_es_cells
      	WHERE targ_rep_es_cells.mgi_allele_symbol_superscript IS NOT NULL
      ),

      distinct_production_centre AS (
        SELECT DISTINCT es_cell_production_centre.allele_id AS allele_id, es_cell_production_centre.mgi_centre AS centre_code
        FROM es_cell_production_centre
      ),
  
      production_centre AS (
      SELECT
        distinct_production_centre.allele_id AS allele_id,
        CASE WHEN distinct_production_centre.centre_code = 'Mbp' THEN 5
             WHEN distinct_production_centre.centre_code = 'Vlcg' THEN 5
             WHEN distinct_production_centre.centre_code = 'Tigm' THEN 5
             WHEN distinct_production_centre.centre_code = 'IscOrc' THEN 2
             WHEN distinct_production_centre.centre_code = 'WCS' THEN 1
             WHEN distinct_production_centre.centre_code = 'Wtsi' THEN 1
             WHEN distinct_production_centre.centre_code = '1TybEmcf' THEN 1
             WHEN distinct_production_centre.centre_code = 'mfgc' THEN 11
             WHEN distinct_production_centre.centre_code = 'Cmhd' THEN 11
             WHEN distinct_production_centre.centre_code = 'Hmgu' THEN 6
             ELSE 100
      	END AS id
      FROM distinct_production_centre
      )

      UPDATE targ_rep_alleles SET production_centre_id = production_centre.id
      FROM production_centre
      WHERE production_centre.allele_id = targ_rep_alleles.id;

      UPDATE targ_rep_alleles SET production_centre_id = 1
      WHERE targ_rep_alleles.production_centre_id IS NULL;

      UPDATE colonies SET crispr_allele_category = mi_attempts.allele_target
      FROM mi_attempts
      WHERE mi_attempts.id = colonies.mi_attempt_id;
    EOF

    ActiveRecord::Base.connection.execute(sql)
 
 end


 def self.down
    remove_column :targ_rep_alleles, :private
    remove_column :colonies, :private
    remove_column :mutagenesis_factors, :private
    remove_column :mi_attempts, :privacy
    remove_column :targ_rep_alleles, :production_centre_id
    remove_column :colonies, :crispr_allele_category
  end
end
