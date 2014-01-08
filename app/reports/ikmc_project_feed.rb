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

  def idcc_master_genelist_additional_data

    headers = []
    data = {}
    gene_list = []
    file_name = "#{Rails.application.config.paths['tmp'].first}/gene_list/gene_list.txt"
    self.class.download_gene_list if ! File.exist?(file_name)

    open(file_name) do |file|
      headers = file.readline.strip.split("\t")
      marker_symbol_index = headers.index('1. MGI accession id')
      ncbi_id_index = headers.index('6. Entrez gene id')
      vega_id_index = headers.index('16. VEGA gene id')
      ensembl_id_index = headers.index('11. Ensembl gene id')
      chromosome_index = headers.index('7. NCBI gene chromosome')
      start_index = headers.index('8. NCBI gene start')
      end_index = headers.index('9. NCBI gene end')
      strand_index = headers.index('10. NCBI gene strand')
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        data[row[marker_symbol_index]] = {
          'ncbi_id' => row[ncbi_id_index],
          'vega_id' => row[vega_id_index],
          'ensembl_id' => row[ensembl_id_index],
          'chr' => row[chromosome_index],
          'start' => row[start_index],
          'end' => row[end_index],
          'strand' => row[strand_index]
        }
      end
    end
    idcc_master_genelist.each do |gene_record|
      if data.has_key?(gene_record['mgi_id'])
        gene_list << gene_record.merge(data[gene_record['mgi_id']])
      else
        gene_list << gene_record.merge({
          'ncbi_id' => nil,
          'vega_id' => nil,
          'ensembl_id' => nil,
          'chr' => nil,
          'start' => nil,
          'end' => nil,
          'strand' => nil})
      end
    end

    @idcc_master_genelist = gene_list
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
     ["Vega IDs", "vega_id"],
     ["NCBI IDs", "ncbi_id"],
     ["Ensembl IDs", "ensembl_id"]
    ]
  end

  def self.download_gene_list
    url = "ftp://ftp.informatics.jax.org/pub/reports/MGI_Gene_Model_Coord.rpt"
    filename = "#{Rails.application.config.paths['tmp'].first}/gene_list/gene_list.txt"
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, "wb") do |file|
      file.write open(url).read
    end
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
             csd.status_name AS CSD,
             reg.status_name AS Regeneron,
             eucomm.status_name AS EUCOMM,
             norcomm.status_name AS NorCOMM
      FROM genes
        LEFT JOIN best_status_for_pipelines AS csd ON genes.id = csd.gene_id AND csd.pipeline_name = 'KOMP-CSD'
        LEFT JOIN best_status_for_pipelines AS reg ON genes.id = reg.gene_id AND reg.pipeline_name = 'KOMP-Regeneron'
        LEFT JOIN best_status_for_pipelines AS eucomm ON genes.id = eucomm.gene_id AND eucomm.pipeline_name = 'EUCOMM'
        LEFT JOIN best_status_for_pipelines AS norcomm ON genes.id = norcomm.gene_id AND norcomm.pipeline_name = 'NorCOMM'

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








