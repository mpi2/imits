-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

DROP TABLE IF EXISTS solr_options CASCADE ;
DROP view IF EXISTS solr_gene_statuses CASCADE;
DROP FUNCTION IF EXISTS solr_get_pa_allele_type (INT) CASCADE;
DROP FUNCTION IF EXISTS solr_get_pa_allele_name (INT) CASCADE;
DROP FUNCTION IF EXISTS solr_get_pa_get_order_from_urls (INT) CASCADE;
DROP FUNCTION IF EXISTS solr_get_pa_order_from_names (INT) CASCADE;
DROP FUNCTION IF EXISTS get_best_status_pa(a INT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS solr_get_best_status_pa_cre (INT, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS solr_get_mi_allele_name (INT) CASCADE;
DROP FUNCTION IF EXISTS solr_get_mi_order_from_names (INT) CASCADE;
DROP FUNCTION IF EXISTS solr_get_mi_order_from_urls (INT) CASCADE;
DROP TABLE IF EXISTS solr_centre_map CASCADE;
DROP FUNCTION IF EXISTS solr_get_allele_order_from_names(INT) CASCADE;
DROP FUNCTION IF EXISTS solr_get_allele_order_from_urls(INT) CASCADE;
DROP TABLE IF EXISTS solr_temp_projects CASCADE;
DROP TABLE IF EXISTS solr_ikmc_projects_details_es_cells_intermediate CASCADE;
DROP TABLE IF EXISTS solr_ikmc_projects_details_agg CASCADE;
DROP TABLE IF EXISTS solr_ikmc_projects_details_vectors_intermediate CASCADE;
DROP TABLE IF EXISTS solr_ikmc_projects_details_all CASCADE;
DROP TABLE IF EXISTS solr_ikmc_projects_details_es_cells CASCADE;
DROP TABLE IF EXISTS solr_ikmc_projects_details_vectors CASCADE;
DROP TABLE IF EXISTS solr_mi_attempts_in_progress_date CASCADE;
DROP TABLE IF EXISTS solr_pa_in_progress_date CASCADE;
DROP TABLE IF EXISTS solr_mi_plans_relevant_status_stamp_table CASCADE;
DROP TABLE IF EXISTS solr_latest_relevant_mi_attempt_table CASCADE;
DROP FUNCTION IF EXISTS solr_mi_plans_relevant_status_stamp_builder() CASCADE;
DROP FUNCTION IF EXISTS solr_latest_relevant_mi_attempt_builder() CASCADE;
DROP FUNCTION IF EXISTS solr_log(text) CASCADE;

--IF :delete_all THEN
    DROP TABLE IF EXISTS solr_phenotype_attempts CASCADE;
    DROP TABLE IF EXISTS solr_mi_attempts CASCADE;
    DROP view IF EXISTS solr_alleles CASCADE;
    DROP TABLE IF EXISTS solr_genes CASCADE;
--end if;