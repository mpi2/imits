class ReadOnlyIndexReport

  ROW_LIMIT = 10

  def self.get_new_impc_mouse_prod_attempts_table
    sql = %Q{
      select
        genes.marker_symbol,
        consortia.name as consortium,
        consortia.id as consortium_id,
        centres.name as production_centre,
        centres.id as production_centre_id,
        to_char(mi_date, 'DD Mon YYYY') as mi_date
      from mi_attempts join mi_plans on mi_attempts.mi_plan_id = mi_plans.id
      join consortia on consortia.id = mi_plans.consortium_id and consortia.name != 'EUCOMMToolsCre'
      join centres on centres.id = mi_plans.production_centre_id
      join genes on genes.id = mi_plans.gene_id
      where (mi_date - current_date >= -30) and mi_attempts.report_to_public = true and mi_plans.report_to_public = true
      order by mi_date desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

  end

  def self.get_new_impc_gc_mice_table
    sql = %Q{
      select
        genes.marker_symbol as marker_symbol,
        consortia.name as consortium,
        consortia.id as consortium_id,
        centres.name as production_centre,
        centres.id as production_centre_id,
        mi_attempt_status_stamps.created_at as gc_date2,
        to_char(mi_date, 'DD Mon YYYY') as mi_date,
        to_char(mi_attempt_status_stamps.created_at, 'DD Mon YYYY') as gc_date,
        DATE_PART('day', current_date - mi_attempt_status_stamps.created_at) || ' days' as other_date
      from mi_attempts join plans on mi_attempts.plan_id = plans.id
      join consortia on consortia.id = plans.consortium_id and consortia.name != 'EUCOMMToolsCre'
      join centres on centres.id = plans.production_centre_id
      join genes on genes.id = plans.gene_id
      join mi_attempt_status_stamps on mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id and mi_attempt_status_stamps.status_id = 2
      where mi_attempts.report_to_public = true and plans.report_to_public = true
      order by gc_date2 desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

  end

  def self.get_ikmc_production_statistics

    sql = %Q{
      SELECT 'targeting_vectors' AS type, substring(targ_rep_pipelines.name from 1 for 4) AS name, count(distinct genes.id) AS count
      FROM targ_rep_targeting_vectors
      JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
      JOIN targ_rep_pipelines ON targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id and targ_rep_pipelines.name IN ('EUCOMM', 'EUCOMMTools', 'KOMP-CSD', 'KOMP-Regeneron') AND targ_rep_pipelines.report_to_public IS true
      JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
      JOIN genes ON genes.id = targ_rep_alleles.gene_id
      --JOIN targ_rep_ikmc_project_statuses ON targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id AND targ_rep_ikmc_project_statuses.name IN ('Vector Complete')
      WHERE targ_rep_targeting_vectors.report_to_public IS true
      GROUP BY substring(targ_rep_pipelines.name FROM 1 FOR 4)

      UNION ALL
      select 'es_cells' as type, substring(targ_rep_pipelines.name from 1 for 4) as name, count(distinct genes.id) as count
      from targ_rep_es_cells
      join targ_rep_ikmc_projects on targ_rep_ikmc_projects.id = targ_rep_es_cells.ikmc_project_foreign_id
      join targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id and targ_rep_pipelines.name in ('EUCOMM', 'EUCOMMTools', 'KOMP-CSD', 'KOMP-Regeneron') AND targ_rep_pipelines.report_to_public IS true
      join targ_rep_alleles on targ_rep_alleles.id = targ_rep_es_cells.allele_id
      join genes on genes.id = targ_rep_alleles.gene_id
      --join targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id and targ_rep_ikmc_project_statuses.name IN ('ES Cells - Targeting Confirmed')
      where targ_rep_es_cells.report_to_public is true
      group by substring(targ_rep_pipelines.name from 1 for 4)

      UNION ALL
      select 'mice' as type, substring(targ_rep_pipelines.name from 1 for 4) as name, count(distinct genes.id) as count
      from mi_attempts
      join targ_rep_es_cells on targ_rep_es_cells.id = mi_attempts.es_cell_id and targ_rep_es_cells.report_to_public is true
      join targ_rep_ikmc_projects on targ_rep_ikmc_projects.id = targ_rep_es_cells.ikmc_project_foreign_id
      join targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id and targ_rep_pipelines.name in ('EUCOMM', 'EUCOMMTools', 'KOMP-CSD', 'KOMP-Regeneron') and targ_rep_pipelines.report_to_public is true
      join targ_rep_alleles on targ_rep_alleles.id = targ_rep_es_cells.allele_id
      join genes on genes.id = targ_rep_alleles.gene_id
      join mi_attempt_status_stamps on mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id
      join mi_attempt_statuses on mi_attempt_statuses.id = mi_attempt_status_stamps.status_id and mi_attempt_statuses.code = 'gtc'
      group by substring(targ_rep_pipelines.name from 1 for 4)
    }

    results = ActiveRecord::Base.connection.execute(sql)

    hash = {}

    results.each do |row|
      hash[row['name']] ||= {}
      hash[row['name']][row['type']] = row['count']
    end

    result = hash.keys.map do |key|
      {
      'project_name' => key == 'EUCO' ? 'EUCOMM' : key,
      'genes_with_vectors' => hash[key]['targeting_vectors'],
      'genes_with_es_cells' => hash[key]['es_cells'],
      'genes_with_mice' => hash[key]['mice']
      }
    end

    result

  end

end
