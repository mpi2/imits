

create
table
solr_ikmc_projects_details_es_cells as
  select genes.id as gene_id,
  targ_rep_ikmc_projects.id as id,
  targ_rep_ikmc_projects.name as project,
  CAST( 'es_cell' AS text ) as type,
  genes.marker_symbol, targ_rep_pipelines.name as pipeline, targ_rep_ikmc_project_statuses.name as status
    --,(targ_rep_es_cells.report_to_public and targ_rep_pipelines.report_to_public) as report_to_public
  from targ_rep_es_cells
  join targ_rep_ikmc_projects on targ_rep_es_cells.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
  join targ_rep_alleles on targ_rep_alleles.id = targ_rep_es_cells.allele_id
  join genes on targ_rep_alleles.gene_id = genes.id
  join targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
  join targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id;

CREATE INDEX solr_ikmc_projects_details_es_cells_idx1 ON solr_ikmc_projects_details_es_cells (project);
CREATE INDEX solr_ikmc_projects_details_es_cells_idx2 ON solr_ikmc_projects_details_es_cells (gene_id);

create
table
solr_ikmc_projects_details_vectors as
  select genes.id as gene_id,
  targ_rep_ikmc_projects.id as id,
  targ_rep_ikmc_projects.name as project,
  CAST( 'vector' AS text ) as type,
  genes.marker_symbol, targ_rep_pipelines.name as pipeline, targ_rep_ikmc_project_statuses.name as status
    --,(targ_rep_targeting_vectors.report_to_public and targ_rep_pipelines.report_to_public) as report_to_public
  from targ_rep_targeting_vectors
  join targ_rep_ikmc_projects on targ_rep_targeting_vectors.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
  join targ_rep_alleles on targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
  join genes on targ_rep_alleles.gene_id = genes.id
  join targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
  join targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id
  ;

CREATE INDEX solr_ikmc_projects_details_vectors_idx1 ON solr_ikmc_projects_details_vectors (project);
CREATE INDEX solr_ikmc_projects_details_vectors_idx2 ON solr_ikmc_projects_details_vectors (gene_id);






create
table
solr_ikmc_projects_details_vectors_intermediate as
select * from solr_ikmc_projects_details_vectors
where not exists (
    select project from solr_ikmc_projects_details_es_cells where
    solr_ikmc_projects_details_es_cells.project = solr_ikmc_projects_details_vectors.project
);

create
table
solr_ikmc_projects_details_es_cells_intermediate as
select * from solr_ikmc_projects_details_es_cells
union
select
  gene_id,
  id,
  project,
  CAST( 'es_cell' AS text ) as type,
  marker_symbol,
  pipeline,
  status
  --,report_to_public
from solr_ikmc_projects_details_vectors_intermediate;





create
table
solr_ikmc_projects_details_all as
select
distinct
* from
solr_ikmc_projects_details_es_cells_intermediate
union
select
distinct
*
from solr_ikmc_projects_details_vectors_intermediate;



create
table
solr_ikmc_projects_details_agg as
select
string_agg(project, ';') as projects,
string_agg(pipeline, ';') as pipelines,
string_agg(status, ';') as statuses,
gene_id,
type
from
solr_ikmc_projects_details_all
group by gene_id, type;







create or replace view solr_gene_statuses as
SELECT most_advanced.mi_plan_id, most_advanced.marker_symbol, most_advanced.status_name, most_advanced.consortium, most_advanced.created_at, most_advanced.production_centre_name
FROM
(
  SELECT all_statuses.mi_plan_id AS mi_plan_id,
  genes.marker_symbol AS marker_symbol,
  all_statuses.status_name AS status_name,
  all_statuses.id,
  all_statuses.created_at,
  first_value(all_statuses.id) OVER (PARTITION BY all_statuses.gene_id order by all_statuses.order_by desc, all_statuses.created_at asc) AS most_advanced_id,
  consortia.name as consortium,
  centres.name as production_centre_name
  FROM
  (
      SELECT 'mi_plan' || mi_plan_status_stamps.id AS id,
          mi_plans.id AS mi_plan_id,
          mi_plans.gene_id,
          mi_plan_statuses.name AS status_name,
          mi_plan_statuses.order_by AS order_by,
          mi_plan_status_stamps.created_at AS created_at
      FROM mi_plans
      JOIN mi_plan_statuses ON mi_plan_statuses.id = mi_plans.status_id
      JOIN mi_plan_status_stamps ON mi_plans.id = mi_plan_status_stamps.mi_plan_id AND mi_plan_statuses.id = mi_plan_status_stamps.status_id
      UNION
      SELECT
          'mi_attempt' || mi_attempt_status_stamps.id AS id,
          mi_plans.id AS mi_plan_id,
          mi_plans.gene_id,
          mi_attempt_statuses.name AS status_name,
          (1000 + mi_attempt_statuses.order_by) AS order_by,
          mi_attempt_status_stamps.created_at AS created_at
      FROM mi_attempts
      JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
      JOIN mi_attempt_status_stamps ON mi_attempts.id = mi_attempt_status_stamps.mi_attempt_id AND mi_attempt_statuses.id = mi_attempt_status_stamps.status_id
      JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
      UNION
      SELECT 'phenotype_attempt' || phenotype_attempt_status_stamps.id AS id,
          mi_plans.id AS mi_plan_id,
          mi_plans.gene_id,
          phenotype_attempt_statuses.name AS status_name,
          (2000 + phenotype_attempt_statuses.order_by) AS order_by,
          phenotype_attempt_status_stamps.created_at AS created_at
      FROM phenotype_attempts
      JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempts.status_id
      JOIN phenotype_attempt_status_stamps ON phenotype_attempts.id = phenotype_attempt_status_stamps.phenotype_attempt_id AND phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id
      JOIN mi_plans ON mi_plans.id = phenotype_attempts.mi_plan_id

  ) AS all_statuses
  JOIN genes ON genes.id = all_statuses.gene_id
  JOIN mi_plans on mi_plans.id = all_statuses.mi_plan_id
  JOIN consortia on mi_plans.consortium_id = consortia.id
  LEFT JOIN centres on mi_plans.production_centre_id = centres.id
  ORDER BY all_statuses.order_by DESC
) AS most_advanced
WHERE most_advanced.id = most_advanced.most_advanced_id;


--create or replace view solr_genes as
--select
--  genes.id as id,
--  CAST( 'gene' AS text ) as type,
--  CAST( '-1' AS text ) as allele_id,
--
--  solr_gene_statuses.consortium as consortium,
--  solr_gene_statuses.production_centre_name as production_centre,
--  solr_gene_statuses.status_name as status,
--  solr_gene_statuses.created_at as effective_date,
--
--  COALESCE(genes.mgi_accession_id, 'unknown') as mgi_accession_id,
--
--  --solr_genes_projects.project as project_ids,
--  --solr_genes_projects.status as project_statuses,
--  --solr_genes_projects.pipeline as project_pipelines,
--  --solr_genes_projects.vproject as vector_project_ids,
--  --solr_genes_projects.vstatus as vector_project_statuses,
--
--  genes.marker_symbol as marker_symbol
--  from genes
--  left join solr_gene_statuses on genes.marker_symbol = solr_gene_statuses.marker_symbol
--  --left join solr_genes_projects on genes.id = solr_genes_projects.gene_id;



--create table solr_genes as
--select
--  genes.id as id,
--  CAST( 'gene' AS text ) as type,
--  CAST( '-1' AS text ) as allele_id,

--  solr_gene_statuses.consortium as consortium,
--  solr_gene_statuses.production_centre_name as production_centre,
--  solr_gene_statuses.status_name as status,
--  solr_gene_statuses.created_at as effective_date,

--  COALESCE(genes.mgi_accession_id, 'unknown') as mgi_accession_id,
--
--  solr_ikmc_projects_details_agg_es_cells.projects as project_ids,
--  solr_ikmc_projects_details_agg_es_cells.statuses as project_statuses,
--  solr_ikmc_projects_details_agg_es_cells.pipelines as project_pipelines,
--
--  solr_ikmc_projects_details_agg_vectors.projects as vector_project_ids,
--  solr_ikmc_projects_details_agg_vectors.statuses as vector_project_statuses,
--
--  genes.marker_symbol as marker_symbol,
--  genes.marker_type as marker_type
--  from genes
--    left join solr_gene_statuses on solr_gene_statuses.gene_id = genes.id
--    left join solr_ikmc_projects_details_agg as solr_ikmc_projects_details_agg_vectors on solr_ikmc_projects_details_agg_vectors.gene_id = genes.id and solr_ikmc_projects_details_agg_vectors.type = 'vector'
--    left join solr_ikmc_projects_details_agg as solr_ikmc_projects_details_agg_es_cells on solr_ikmc_projects_details_agg_es_cells.gene_id = genes.id and solr_ikmc_projects_details_agg_es_cells.type = 'es_cell'
--  ;
--
--CREATE INDEX solr_genes_idx ON solr_genes (id);