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
    ccds_data = {}
    vega_data = {}
    ncbi_data = {}
    ensembl_data = {}
    gene_list = []
    file_name = "#{Rails.application.config.paths['tmp'].first}/gene_list/gene_list.txt"
    ccds_file_name = "#{Rails.application.config.paths['tmp'].first}/gene_list/CCDS.txt"
    vega_file_name = "#{Rails.application.config.paths['tmp'].first}/gene_list/vega.txt"
    ensembl_file_name = "#{Rails.application.config.paths['tmp'].first}/gene_list/ensembl.txt"
    ncbi_file_name = "#{Rails.application.config.paths['tmp'].first}/gene_list/ncbi.txt"

    self.class.download_gene_list if ! File.exist?(file_name)
    self.class.download_ccds_list if ! File.exist?(ccds_file_name)
    self.class.download_vega_list if ! File.exist?(vega_file_name)
    self.class.download_ensembl_list if ! File.exist?(ensembl_file_name)
    self.class.download_ncbi_list if ! File.exist?(ncbi_file_name)

    open(file_name) do |file|
      headers = file.readline.strip.split("\t")
      marker_symbol_index = 0
      chromosome_index = 5
      start_index = 6
      end_index = 7
      strand_index = 8
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        data[row[marker_symbol_index]] = {
          'chr' => row[chromosome_index],
          'start' => row[start_index],
          'end' => row[end_index],
          'strand' => row[strand_index]
        }
      end
    end

    open(ccds_file_name) do |file|
      headers = file.readline.strip.split("\t")
      ncbi_id_index = headers.index('gene_id')
      ccds_ids_index = headers.index('ccds_id')
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        if !ccds_data.has_key?(row[ncbi_id_index])
          ccds_data[row[ncbi_id_index]] = {
            'ccds_ids' => []
          }
        end
        ccds_data[row[ncbi_id_index]]['ccds_ids'] << row[ccds_ids_index]
      end
    end

    open(vega_file_name) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_id_index = 0
      vega_ids_index = 5
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        if !vega_data.has_key?(row[mgi_accession_id_index])
          vega_data[row[mgi_accession_id_index]] = {
            'vega_ids' => []
          }
        end
        vega_data[row[mgi_accession_id_index]]['vega_ids'] << row[vega_ids_index]
      end
    end

    open(ensembl_file_name) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_id_index = 0
      ens_ids_index = 5
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        if !ensembl_data.has_key?(row[mgi_accession_id_index])
          ensembl_data[row[mgi_accession_id_index]] = {
            'ens_ids' => []
          }
        end
        ensembl_data[row[mgi_accession_id_index]]['ens_ids'] << row[ens_ids_index]
      end
    end

    open(ncbi_file_name) do |file|
      headers = file.readline.strip.split("\t")
      mgi_accession_id_index = 0
      ncbi_ids_index = 8
      file.each_line do |line|
        row = line.strip.gsub(/\"/, '').split("\t")
        if !ncbi_data.has_key?(row[mgi_accession_id_index])
          ncbi_data[row[mgi_accession_id_index]] = {
            'ncbi_ids' => []
          }
        end
        if !row[ncbi_ids_index].blank?
          ncbi_data[row[mgi_accession_id_index]]['ncbi_ids'] << row[ncbi_ids_index]
        end
      end
    end



    idcc_master_genelist.each do |gene_record|
      additional_data = {}
      if data.has_key?(gene_record['mgi_id'])
        additional_data = data[gene_record['mgi_id']]
      else
        additional_data = {
          'chr' => nil,
          'start' => nil,
          'end' => nil,
          'strand' => nil}
      end


      if vega_data.has_key?(gene_record['mgi_id']) and vega_data[gene_record['mgi_id']]['vega_ids'] != []
        additional_data = additional_data.merge({'vega_ids' => vega_data[gene_record['mgi_id']]['vega_ids'].join(',')})
      else
        additional_data = additional_data.merge({
          'vega_ids' => nil})
      end

      if ensembl_data.has_key?(gene_record['mgi_id']) and ensembl_data[gene_record['mgi_id']]['ens_ids'] != []
        additional_data = additional_data.merge({'ensembl_ids' => ensembl_data[gene_record['mgi_id']]['ens_ids'].join(',')})
      else
        additional_data = additional_data.merge({
          'ensembl_ids' => nil})
      end

      if ncbi_data.has_key?(gene_record['mgi_id']) and ncbi_data[gene_record['mgi_id']]['ncbi_ids'] != []
        additional_data = additional_data.merge({'ncbi_ids' => ncbi_data[gene_record['mgi_id']]['ncbi_ids'].join(',')})
      else
        additional_data = additional_data.merge({
          'ncbi_ids' => nil})
      end

      if ccds_data.has_key?(additional_data['ncbi_ids']) and ccds_data[additional_data['ncbi_ids']]['ccds_ids'] != []
        additional_data = additional_data.merge({'ccds_ids' => ccds_data[additional_data['ncbi_ids']]['ccds_ids'].join(',')})
      else
        additional_data = additional_data.merge({
          'ccds_ids' => nil})
      end


      gene_list << gene_record.merge(additional_data)
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
     ["Vega IDs", "vega_ids"],
     ["NCBI IDs", "ncbi_ids"],
     ["Ensembl IDs", "ensembl_ids"],
     ["CCDS IDs", "ccds_ids"]
    ]
  end

  def self.download_gene_list
    url = "ftp://ftp.informatics.jax.org/pub/reports/MGI_MRK_Coord.rpt"
    filename = "#{Rails.application.config.paths['tmp'].first}/gene_list/gene_list.txt"
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, "wb") do |file|
      file.write open(url).read
    end
  end

  def self.download_ccds_list
    url = "ftp://ftp.ncbi.nlm.nih.gov/pub/CCDS/current_mouse/CCDS.current.txt"
    filename = "#{Rails.application.config.paths['tmp'].first}/gene_list/CCDS.txt"
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, "wb") do |file|
      file.write open(url).read
    end
  end

  def self.download_vega_list
    url = "ftp://ftp.informatics.jax.org/pub/reports/MRK_VEGA.rpt"
    filename = "#{Rails.application.config.paths['tmp'].first}/gene_list/vega.txt"
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, "wb") do |file|
      file.write open(url).read
    end
  end

  def self.download_ensembl_list
    url = "ftp://ftp.informatics.jax.org/pub/reports/MRK_ENSEMBL.rpt"
    filename = "#{Rails.application.config.paths['tmp'].first}/gene_list/ensembl.txt"
    FileUtils.mkdir_p File.dirname(filename)
    File.open(filename, "wb") do |file|
      file.write open(url).read
    end
  end

  def self.download_ncbi_list
    url = "ftp://ftp.informatics.jax.org/pub/reports/MGI_EntrezGene.rpt"
    filename = "#{Rails.application.config.paths['tmp'].first}/gene_list/ncbi.txt"
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








