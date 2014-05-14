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
      join consortia on consortia.id = mi_plans.consortium_id
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
      from mi_attempts join mi_plans on mi_attempts.mi_plan_id = mi_plans.id
      join consortia on consortia.id = mi_plans.consortium_id
      join centres on centres.id = mi_plans.production_centre_id
      join genes on genes.id = mi_plans.gene_id
      join mi_attempt_status_stamps on mi_attempt_status_stamps.mi_attempt_id = mi_attempts.id and mi_attempt_status_stamps.status_id = 2
      where mi_attempts.report_to_public = true and mi_plans.report_to_public = true
      order by gc_date2 desc limit #{ROW_LIMIT}
    }

    results = ActiveRecord::Base.connection.execute(sql)

  end

  def self.get_ikmc_production_statistics

    sql = %Q{
      WITH type_counts as(
      select 'targeting_vectors' as type, substring(targ_rep_pipelines.name from 1 for 4) as name, count(distinct genes.id) as count
      from targ_rep_targeting_vectors
      join targ_rep_ikmc_projects on targ_rep_ikmc_projects.id = targ_rep_targeting_vectors.ikmc_project_foreign_id
      join targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id and targ_rep_pipelines.name in ('EUCOMM', 'EUCOMMTools', 'KOMP-CSD', 'KOMP-Regeneron') and targ_rep_pipelines.report_to_public is true
      join targ_rep_alleles on targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
      join genes on genes.id = targ_rep_alleles.gene_id
      join targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id and targ_rep_ikmc_project_statuses.name in ('Vector Complete')
      where targ_rep_targeting_vectors.report_to_public is true
      group by substring(targ_rep_pipelines.name from 1 for 4)

      union
      select 'es_cells' as type, substring(targ_rep_pipelines.name from 1 for 4) as name, count(distinct genes.id) as count
      from targ_rep_es_cells
      join targ_rep_ikmc_projects on targ_rep_ikmc_projects.id = targ_rep_es_cells.ikmc_project_foreign_id
      join targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id and targ_rep_pipelines.name in ('EUCOMM', 'EUCOMMTools', 'KOMP-CSD', 'KOMP-Regeneron') and targ_rep_pipelines.report_to_public is true
      join targ_rep_alleles on targ_rep_alleles.id = targ_rep_es_cells.allele_id
      join genes on genes.id = targ_rep_alleles.gene_id
      join targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id and targ_rep_ikmc_project_statuses.name in ('ES Cells - Targeting Confirmed')
      where targ_rep_es_cells.report_to_public is true
      group by substring(targ_rep_pipelines.name from 1 for 4)

      union
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
      )

      select type,
      CASE WHEN name = 'KOMP' THEN 'KOMP'
       WHEN name = 'EUCO' THEN 'EUCOMM'
      END as name, count from type_counts
    }

    #SELECT COUNT(*) FROM "mi_attempt_status_stamps" WHERE "mi_attempt_status_stamps"."mi_attempt_id" = 1 AND "mi_attempt_status_stamps"."status_id" = 2


    results = ActiveRecord::Base.connection.execute(sql)

    hash = {}

#{"type"=>"targeting_vectors", "case"=>"KOMP", "count"=>"9773"}
#{"type"=>"targeting_vectors", "case"=>"EUCO", "count"=>"9382"}
#{"type"=>"es_cells", "case"=>"KOMP", "count"=>"9213"}
#{"type"=>"es_cells", "case"=>"EUCO", "count"=>"8339"}
#{"type"=>"mice", "case"=>"KOMP", "count"=>"3820"}
#{"type"=>"mice", "case"=>"EUCO", "count"=>"3141"}

    results.each do |row|
      #pp row
      hash[row['name']] ||= {}
      hash[row['name']][row['type']] = row['count']
    end

    pp hash

    array = hash.keys.map do |key|
      {
        'project_name' => key,
        'genes_with_vectors' => hash[key]['targeting_vectors'],
        'genes_with_es_cells' => hash[key]['es_cells'],
        'genes_with_mice' => hash[key]['mice']
        }
    end

    pp array

    array

    #hash = {}
    #
    #results.each do |row|
    #  pp row
    #
    #  hash['targeting_vectors_KOMP'] = row['count'].to_i if row['name'] == 'KOMP' && row['type'] == 'targeting_vectors'
    #  hash['targeting_vectors_EUCOMM'] = row['count'].to_i if row['name'] == 'EUCO' && row['type'] == 'targeting_vectors'
    #
    #  hash['es_cells_KOMP'] = row['count'].to_i if row['name'] == 'KOMP' && row['type'] == 'es_cells'
    #  hash['es_cells_EUCOMM'] = row['count'].to_i if row['name'] == 'EUCO' && row['type'] == 'es_cells'
    #
    #  hash['mice_KOMP'] = row['count'].to_i if row['name'] == 'KOMP' && row['type'] == 'mice'
    #  hash['mice_EUCOMM'] = row['count'].to_i if row['name'] == 'EUCO' && row['type'] == 'mice'
    #end
    #
    #[
    #  {'project_name' => 'EUCOMM',
    #    'genes_with_vectors' => hash['targeting_vectors_EUCOMM'],
    #    'genes_with_es_cells' => hash['es_cells_EUCOMM'],
    #    'genes_with_mice' => hash['mice_EUCOMM']},
    #  {'project_name' => 'KOMP',
    #    'genes_with_vectors' => hash['targeting_vectors_KOMP'],
    #    'genes_with_es_cells' => hash['es_cells_KOMP'],
    #    'genes_with_mice' => hash['mice_KOMP']}
    #]
  end

end
