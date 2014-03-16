-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

CREATE table solr_ikmc_projects_details_agg ( projects text, pipelines text, statuses text, gene_id int, type text );

-- FUNCTION NAME: solr_ikmc_projects_details_builder
--
-- PARAMETERS: none
--
-- DESCRIPTION: Builds project details for gene type doc.

CREATE OR REPLACE FUNCTION solr_ikmc_projects_details_builder()
RETURNS int AS $$
DECLARE
    result int;
BEGIN
    CREATE temp table solr_ikmc_projects_details_es_cells ( gene_id int, id int, project text, type text, marker_symbol text, pipeline text, status text ) ;
    CREATE temp table solr_ikmc_projects_details_vectors ( gene_id int, id int, project text, type text, marker_symbol text, pipeline text, status text ) ;
--    CREATE temp table solr_ikmc_projects_details_vectors ( gene_id int, id int, project text, type text, marker_symbol text, pipeline text, status text ) ;
    CREATE temp table solr_ikmc_projects_details_es_cells_intermediate ( gene_id int, id int, project text, type text, marker_symbol text, pipeline text, status text ) ;
    CREATE temp table solr_ikmc_projects_details_all ( gene_id int, id int, project text, type text, marker_symbol text, pipeline text, status text ) ;
    CREATE temp table allele_with_es_count_tmp ( id int, gene_id int , es_cell_count int ) ;

    INSERT INTO
    solr_ikmc_projects_details_es_cells
      SELECT genes.id AS gene_id,
      targ_rep_ikmc_projects.id AS id,
      targ_rep_ikmc_projects.name AS project,
      CAST( 'es_cell' AS text ) AS type,
      genes.marker_symbol,
      targ_rep_pipelines.name AS pipeline,
      targ_rep_ikmc_project_statuses.name AS status
        --,(targ_rep_es_cells.report_to_public and targ_rep_pipelines.report_to_public) AS report_to_public
      FROM targ_rep_es_cells
      JOIN targ_rep_ikmc_projects on targ_rep_es_cells.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
      JOIN targ_rep_alleles on targ_rep_alleles.id = targ_rep_es_cells.allele_id
      JOIN genes on targ_rep_alleles.gene_id = genes.id
      JOIN targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      JOIN targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id;

    INSERT INTO
    solr_ikmc_projects_details_es_cells
      SELECT genes.id AS gene_id,
      targ_rep_ikmc_projects.id AS id,
      targ_rep_ikmc_projects.name AS project,
      CAST( 'es_cell' AS text ) AS type,
      genes.marker_symbol,
      targ_rep_pipelines.name AS pipeline,
      targ_rep_ikmc_project_statuses.name AS status
        --,(targ_rep_targeting_vectors.report_to_public and targ_rep_pipelines.report_to_public) AS report_to_public
      FROM targ_rep_targeting_vectors
      JOIN targ_rep_ikmc_projects on targ_rep_targeting_vectors.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
      JOIN targ_rep_alleles on targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id
      JOIN genes on targ_rep_alleles.gene_id = genes.id
      JOIN targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      JOIN targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id;

      INSERT INTO allele_with_es_count_tmp
      WITH allele_with_es_count AS (
        SELECT alleles1.id AS allele_id, COALESCE(targ_rep_es_cells.count, 0) AS es_cell_count
        FROM targ_rep_alleles AS alleles1
          JOIN targ_rep_alleles AS alleles2 ON alleles1.gene_id = alleles2.gene_id AND alleles1.mutation_type_id = alleles2.mutation_type_id AND alleles1.cassette = alleles2.cassette
          LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.allele_id = alleles2.id
        GROUP BY alleles1.id having targ_rep_es_cells.count = 0)
      SELECT targ_rep_alleles.id as id, targ_rep_alleles.gene_id as gene_id, allele_with_es_count.es_cell_count as es_cell_count
      FROM targ_rep_alleles JOIN allele_with_es_count ON allele_with_es_count.allele_id = targ_rep_alleles.id
      ;

    INSERT INTO
    solr_ikmc_projects_details_vectors
      SELECT genes.id AS gene_id,
      targ_rep_ikmc_projects.id AS id,
      targ_rep_ikmc_projects.name AS project,
      CAST( 'vector' AS text ) AS type,
      genes.marker_symbol,
      targ_rep_pipelines.name AS pipeline,
      targ_rep_ikmc_project_statuses.name AS status
        --,(targ_rep_targeting_vectors.report_to_public and targ_rep_pipelines.report_to_public) AS report_to_public
      FROM targ_rep_targeting_vectors
      JOIN targ_rep_ikmc_projects on targ_rep_targeting_vectors.ikmc_project_foreign_id = targ_rep_ikmc_projects.id
      JOIN allele_with_es_count_tmp on allele_with_es_count_tmp.id = targ_rep_targeting_vectors.allele_id
      JOIN genes on allele_with_es_count_tmp.gene_id = genes.id
      JOIN targ_rep_pipelines on targ_rep_pipelines.id = targ_rep_ikmc_projects.pipeline_id
      JOIN targ_rep_ikmc_project_statuses on targ_rep_ikmc_project_statuses.id = targ_rep_ikmc_projects.status_id;

    --INSERT INTO
    --solr_ikmc_projects_details_vectors
    --SELECT * FROM solr_ikmc_projects_details_vectors

    INSERT INTO
    solr_ikmc_projects_details_es_cells_intermediate
    SELECT * FROM solr_ikmc_projects_details_es_cells
    UNION
    SELECT
      gene_id,
      id,
      project,
      CAST( 'es_cell' AS text ) AS type,
      marker_symbol,
      pipeline,
      status
    FROM solr_ikmc_projects_details_vectors;

    INSERT INTO
    solr_ikmc_projects_details_all
    SELECT
    DISTINCT
    * FROM
    solr_ikmc_projects_details_es_cells_intermediate
    UNION
    SELECT
    DISTINCT
    *
    FROM solr_ikmc_projects_details_vectors;

    INSERT INTO
    solr_ikmc_projects_details_agg
    SELECT
        string_agg(project, ';') AS projects,
        string_agg(pipeline, ';') AS pipelines,
        string_agg(status, ';') AS statuses,
        gene_id,
        type
    FROM
    solr_ikmc_projects_details_all
    GROUP BY gene_id, type;

    SELECT count(*) INTO result FROM solr_ikmc_projects_details_agg;

    --select count(*) INTO result from solr_ikmc_projects_details_vectors where gene_id = 1;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE or replace view solr_gene_statuses AS
SELECT most_advanced.mi_plan_id, most_advanced.marker_symbol, most_advanced.status_name, most_advanced.consortium, most_advanced.created_at, most_advanced.production_centre_name
FROM
(
  SELECT all_statuses.mi_plan_id AS mi_plan_id,
  genes.marker_symbol AS marker_symbol,
  all_statuses.status_name AS status_name,
  all_statuses.id,
  all_statuses.created_at,
  first_value(all_statuses.id) OVER (PARTITION BY all_statuses.gene_id order by all_statuses.order_by desc, all_statuses.created_at asc) AS most_advanced_id,
  consortia.name AS consortium,
  centres.name AS production_centre_name
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

SELECT solr_ikmc_projects_details_builder();

CREATE
table
solr_genes AS
SELECT
  genes.id AS id,
  CAST( 'gene' AS text ) AS type,
  CAST( '-1' AS text ) AS allele_id,

  solr_gene_statuses.consortium AS consortium,
  solr_gene_statuses.production_centre_name AS production_centre,
  solr_gene_statuses.status_name AS status,
  solr_gene_statuses.created_at AS effective_date,

  COALESCE(genes.mgi_accession_id, 'unknown') AS mgi_accession_id,

  solr_ikmc_projects_details_agg_es_cells.projects AS project_ids,
  solr_ikmc_projects_details_agg_es_cells.statuses AS project_statuses,
  solr_ikmc_projects_details_agg_es_cells.pipelines AS project_pipelines,

  solr_ikmc_projects_details_agg_vectors.projects AS vector_project_ids,
  solr_ikmc_projects_details_agg_vectors.statuses AS vector_project_statuses,

  genes.marker_symbol AS marker_symbol,
  genes.marker_type AS marker_type
  FROM genes
    left JOIN solr_gene_statuses on solr_gene_statuses.marker_symbol = genes.marker_symbol
    left JOIN solr_ikmc_projects_details_agg AS solr_ikmc_projects_details_agg_vectors on solr_ikmc_projects_details_agg_vectors.gene_id = genes.id and solr_ikmc_projects_details_agg_vectors.type = 'vector'
    left JOIN solr_ikmc_projects_details_agg AS solr_ikmc_projects_details_agg_es_cells on solr_ikmc_projects_details_agg_es_cells.gene_id = genes.id and solr_ikmc_projects_details_agg_es_cells.type = 'es_cell'
  ;

CREATE INDEX solr_genes_idx ON solr_genes (id);