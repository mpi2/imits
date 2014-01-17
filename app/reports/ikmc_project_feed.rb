class IkmcProjectFeed
  require 'open-uri'

  attr_accessor :komp_project
  attr_accessor :idcc_master_genelist

  def komp_project
    @komp_project ||= ActiveRecord::Base.connection.execute(self.class.komp_project_sql)
  end

  def idcc_master_genelist
    @idcc_master_genelist ||= ActiveRecord::Base.connection.execute(self.class.idcc_master_genelist_sql)
  end


## CLASS METHODS
  def self.komp_projects_columns
    [["MGI ID", "mgi_id"],
     ["Origin", "origin"],
     ["Project ID", "project_id"],
     ["Status", "status"],
     ["Datetime", "datetime"]
    ]
  end

  def self.idcc_master_genelist_columns
    [["MGI ID", "mgi_id"],
     ["Symbol", "symbol"],
     ["Chr", "chr"],
     ["Start", "start"],
     ["End", "end"],
     ["Strand", "strand"],
     ["CSD", "csd"],
     ["Regeneron", "regeneron"],
     ["EUCOMM", "eucomm"],
     ["NorCOMM", "norcomm"],
     ["Vega IDs", "vega_ids"],
     ["NCBI IDs", "ncbi_ids"],
     ["Ensembl IDs", "ensembl_ids"],
     ["CCDS IDs", "ccds_ids"]
    ]
  end


  def self.idcc_master_genelist_sql
    sql = <<-EOF
      WITH gene_projects AS (

        SELECT DISTINCT a1.gene_id, targ_rep_es_cells.ikmc_project_foreign_id
        FROM targ_rep_es_cells
          JOIN targ_rep_alleles AS a1 ON a1.id = targ_rep_es_cells.allele_id

        UNION

        SELECT DISTINCT a2.gene_id, targ_rep_targeting_vectors.ikmc_project_foreign_id
        FROM targ_rep_targeting_vectors
          JOIN targ_rep_alleles AS a2 ON a2.id = targ_rep_targeting_vectors.allele_id
      ),

      best_status_for_pipelines AS (
        SELECT DISTINCT ON (gene_projects.gene_id, targ_rep_pipelines.name) gene_projects.gene_id, targ_rep_pipelines.name AS pipeline_name, targ_rep_ikmc_project_statuses.name AS status_name
        FROM gene_projects
          JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = gene_projects.ikmc_project_foreign_id
          JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
          JOIN targ_rep_ikmc_project_statuses ON targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id
        ORDER BY gene_projects.gene_id, targ_rep_pipelines.name, targ_rep_ikmc_project_statuses.order_by, targ_rep_ikmc_project_statuses.name
      )

      SELECT genes.mgi_accession_id AS MGI_ID,
             genes.marker_symbol AS Symbol,
             genes.chr AS chr,
             genes.start_coordinates AS start,
             genes.end_coordinates AS end,
             genes.strand_name AS strand,
             csd.status_name AS CSD,
             reg.status_name AS Regeneron,
             eucomm.status_name AS EUCOMM,
             norcomm.status_name AS NorCOMM,
             genes.vega_ids AS vega_ids,
             genes.ncbi_ids AS ncbi_ids,
             genes.ensembl_ids AS ensembl_ids,
             genes.ccds_ids AS ccds_ids
      FROM genes
        LEFT JOIN best_status_for_pipelines AS csd ON genes.id = csd.gene_id AND csd.pipeline_name = 'KOMP-CSD'
        LEFT JOIN best_status_for_pipelines AS reg ON genes.id = reg.gene_id AND reg.pipeline_name = 'KOMP-Regeneron'
        LEFT JOIN best_status_for_pipelines AS eucomm ON genes.id = eucomm.gene_id AND eucomm.pipeline_name = 'EUCOMM'
        LEFT JOIN best_status_for_pipelines AS norcomm ON genes.id = norcomm.gene_id AND norcomm.pipeline_name = 'NorCOMM'
      WHERE genes.mgi_accession_id NOT LIKE 'CGI_%'

    EOF
  end

  def self.komp_project_sql
    sql = <<-EOF

      WITH gene_projects AS (

        SELECT DISTINCT a1.gene_id, targ_rep_es_cells.ikmc_project_foreign_id
        FROM targ_rep_es_cells
          JOIN targ_rep_alleles AS a1 ON a1.id = targ_rep_es_cells.allele_id

        UNION

        SELECT DISTINCT a2.gene_id, targ_rep_targeting_vectors.ikmc_project_foreign_id
        FROM targ_rep_targeting_vectors
          JOIN targ_rep_alleles AS a2 ON a2.id = targ_rep_targeting_vectors.allele_id
      ),

      best_status_for_pipelines AS (
        SELECT DISTINCT ON (gene_projects.gene_id, targ_rep_pipelines.name)
                      gene_projects.gene_id,
                      targ_rep_pipelines.name AS pipeline_name,
                      targ_rep_ikmc_project_statuses.name AS status_name,
                      targ_rep_ikmc_projects.name AS project_name,
                      targ_rep_ikmc_projects.updated_at AS updated_at
        FROM gene_projects
          JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = gene_projects.ikmc_project_foreign_id
          JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
          JOIN targ_rep_ikmc_project_statuses ON targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id
        ORDER BY gene_projects.gene_id, targ_rep_pipelines.name, targ_rep_ikmc_project_statuses.order_by DESC, targ_rep_ikmc_project_statuses.name

      )

      SELECT genes.mgi_accession_id AS MGI_ID,
        CASE
          WHEN best_status_for_pipelines.pipeline_name = 'KOMP-CSD'
            THEN 'CSD'
          WHEN best_status_for_pipelines.pipeline_name = 'KOMP-Regeneron'
            THEN 'Regeneron'
          ELSE
            best_status_for_pipelines.pipeline_name
          END AS Origin,
        best_status_for_pipelines.project_name AS Project_ID,
        best_status_for_pipelines.status_name AS Status,
        best_status_for_pipelines.updated_at AS Datetime

      FROM best_status_for_pipelines
        JOIN genes ON genes.id = best_status_for_pipelines.gene_id
      WHERE best_status_for_pipelines.pipeline_name LIKE 'KOMP%'
    EOF

  end
end








