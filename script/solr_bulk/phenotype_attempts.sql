-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

-- FUNCTION NAME: solr_get_pa_allele_type
--
-- PARAMETERS: phenotype_attempts.id
--
-- CORRESPONDING RUBY: in create_for_phenotype_attempt in doc_factory.rb to set allele_type (https://github.com/mpi2/imits/blob/master/app/models/solr_update/doc_factory.rb#L114)
--
-- TEST:
--
-- EQUIVALENCE TEST: test_phenotype_attempt_allele_type in ./script/solr_bulk/test/phenotype_attempts_test.rb
--
-- DESCRIPTION: generate allele_type for phenotype_attempt doc type

CREATE OR REPLACE FUNCTION solr_get_pa_allele_type (in int)
RETURNS text AS $$
DECLARE
result text; mouse_allele_type text; allele_symbol_superscript_template text; marker_symbol text; mi_attempt_id int;
BEGIN
    result := '';

    select phenotype_attempts.mi_attempt_id
      into mi_attempt_id
    from phenotype_attempts where phenotype_attempts.id = $1;

    select phenotype_attempts.mouse_allele_type
      into mouse_allele_type
    from phenotype_attempts where phenotype_attempts.id = $1;

    select targ_rep_es_cells.allele_symbol_superscript_template
      into allele_symbol_superscript_template
    from mi_attempts, targ_rep_es_cells, phenotype_attempts where phenotype_attempts.mi_attempt_id = mi_attempts.id and targ_rep_es_cells.id = mi_attempts.es_cell_id and phenotype_attempts.id = $1;

    select genes.marker_symbol
      into marker_symbol
    from genes, mi_plans, phenotype_attempts where mi_plans.id = phenotype_attempts.mi_plan_id and mi_plans.gene_id = genes.id and phenotype_attempts.id = $1;

    if char_length(mouse_allele_type) > 0 and char_length(allele_symbol_superscript_template) > 0 then
      select replace(allele_symbol_superscript_template, '@', mouse_allele_type) into result;
      result := marker_symbol || '<sup>' || result || '</sup>';
    else
      select solr_get_mi_allele_name(mi_attempt_id) into result;
    end if;

    if char_length(result) > 0 then
      select (regexp_matches(result, E'\\>(.+)?\\('))[1] into result;
    end if;

    if char_length(result) > 0 then
      result := 'Cre-excised deletion (' || result || ')';
    else
      result := 'Cre-excised deletion';
    end if;

    RETURN result;

END;
$$ LANGUAGE plpgsql;

-- FUNCTION NAME: solr_get_pa_allele_name
--
-- PARAMETERS: phenotype_attempts.id
--
-- CORRESPONDING RUBY: in create_for_phenotype_attempt in doc_factory.rb to set allele_name (https://github.com/mpi2/imits/blob/master/app/models/solr_update/doc_factory.rb#L122)
--
-- TEST:
--
-- EQUIVALENCE TEST: test_phenotype_attempt_allele_name in ./script/solr_bulk/test/phenotype_attempts_test.rb
--
-- DESCRIPTION: generate allele_name for phenotype_attempt doc type

CREATE OR REPLACE FUNCTION solr_get_pa_allele_name (int)
  RETURNS text AS $$
  DECLARE
  tmp RECORD; result text; mouse_allele_type text; allele_symbol_superscript_template text; marker_symbol text; mi_attempt_id int; cec_count int;
  BEGIN

  result := null;

  select phenotype_attempts.mi_attempt_id
    into mi_attempt_id from phenotype_attempts where phenotype_attempts.id = $1;

  select count(*) into cec_count from phenotype_attempt_status_stamps where
  phenotype_attempt_status_stamps.phenotype_attempt_id = $1 and phenotype_attempt_status_stamps.status_id = 6;

  select phenotype_attempts.mouse_allele_type
    into mouse_allele_type from phenotype_attempts where phenotype_attempts.id = $1;

  select targ_rep_es_cells.allele_symbol_superscript_template
    into allele_symbol_superscript_template from mi_attempts, targ_rep_es_cells, phenotype_attempts where phenotype_attempts.mi_attempt_id = mi_attempts.id and targ_rep_es_cells.id = mi_attempts.es_cell_id and phenotype_attempts.id = $1;

  select genes.marker_symbol
    into marker_symbol from genes, mi_plans, phenotype_attempts where mi_plans.id = phenotype_attempts.mi_plan_id and mi_plans.gene_id = genes.id and phenotype_attempts.id = $1;

  if cec_count > 0 then
    if char_length(mouse_allele_type) > 0 and char_length(allele_symbol_superscript_template) > 0 then
      select replace(allele_symbol_superscript_template, '@', mouse_allele_type) into result;
      result := marker_symbol || '<sup>' || result || '</sup>';
    else
      result := null;
    end if;
  else
    select solr_get_mi_allele_name(mi_attempt_id) into result;
  end if;

  RETURN result;
  END;
$$ LANGUAGE plpgsql;

-- FUNCTION NAME: solr_get_pa_order_from_names
--
-- PARAMETERS: phenotype_attempts.id
--
-- CORRESPONDING RUBY: in create_for_phenotype_attempt in doc_factory.rb to set order_from_names (https://github.com/mpi2/imits/blob/master/app/models/solr_update/doc_factory.rb#L130)
--
-- TEST:
--
-- EQUIVALENCE TEST: test_phenotype_attempt_order_from_names in ./script/solr_bulk/test/phenotype_attempts_test.rb
--
-- DESCRIPTION: generate order_from_names for phenotype_attempt doc type

CREATE OR REPLACE FUNCTION solr_get_pa_order_from_names (int)
  RETURNS text AS $$
  DECLARE
    tmp RECORD; result text;
  BEGIN
  result := '';

  --drop table if exists solr_get_pa_order_from_names_tmp;

  FOR tmp IN SELECT phenotype_attempt_distribution_centres.distribution_network,
  case
  when centres.name = 'UCD' then 'KOMP'
  else centres.name
  end
  FROM phenotype_attempt_distribution_centres, centres, solr_centre_map
  where phenotype_attempt_distribution_centres.phenotype_attempt_id = $1 and
  centres.id = phenotype_attempt_distribution_centres.centre_id and
  (start_date is null or end_date is null or (start_date >= current_date and end_date <= current_date)) and
  ( (solr_centre_map.centre_name = centres.name and (char_length(solr_centre_map.pref) > 0 or char_length(solr_centre_map.def) > 0)) or
    (solr_centre_map.centre_name = phenotype_attempt_distribution_centres.distribution_network and (char_length(solr_centre_map.pref) > 0 or char_length(solr_centre_map.def) > 0)))
  LOOP

    if char_length(tmp.distribution_network) > 0 then
        insert into solr_get_pa_order_from_names_tmp(phenotype_attempt_id, name) values ($1, tmp.distribution_network);
    else
        insert into solr_get_pa_order_from_names_tmp(phenotype_attempt_id, name) values ($1, tmp.name);
    end if;

    --if char_length(tmp.distribution_network) > 0 then
    --  result := result || tmp.distribution_network || ';';
    --else
    --  result := result || tmp.name || ';';
    --end if;

  END LOOP;

  select string_agg(distinct name, ';') into result from solr_get_pa_order_from_names_tmp group by phenotype_attempt_id;

  --COMMIT;

  RETURN result;
  END;
$$ LANGUAGE plpgsql;

-- FUNCTION NAME: solr_get_pa_get_order_from_urls
--
-- PARAMETERS: phenotype_attempts.id
--
-- CORRESPONDING RUBY: in create_for_phenotype_attempt in doc_factory.rb to set order_from_urls (https://github.com/mpi2/imits/blob/master/app/models/solr_update/doc_factory.rb#L130)
--
-- TEST:
--
-- EQUIVALENCE TEST: test_phenotype_attempt_order_from_urls in ./script/solr_bulk/test/phenotype_attempts_test.rb
--
-- DESCRIPTION: generate order_from_urls for phenotype_attempt doc type

CREATE OR REPLACE FUNCTION solr_get_pa_get_order_from_urls (int)
  RETURNS text AS $$
  DECLARE
  tmp RECORD; tmp2 RECORD; result text; marker_symbol text; project_id text; tmp_result text; target_name text;
  BEGIN
  result := '';

  --drop table if exists solr_get_pa_get_order_from_urls_tmp;

  select targ_rep_es_cells.ikmc_project_id
    into project_id
  from mi_attempts, targ_rep_es_cells, phenotype_attempts
  where targ_rep_es_cells.id = mi_attempts.es_cell_id and phenotype_attempts.id = $1 and mi_attempts.id = phenotype_attempts.mi_attempt_id;

  select genes.marker_symbol
    into marker_symbol
  from genes, mi_plans, phenotype_attempts
  where mi_plans.id = phenotype_attempts.mi_plan_id and mi_plans.gene_id = genes.id and phenotype_attempts.id = $1;

  FOR tmp IN SELECT phenotype_attempt_distribution_centres.distribution_network,
  case
  when centres.name = 'UCD' then 'KOMP'
  else centres.name
  end
  FROM phenotype_attempt_distribution_centres,centres where phenotype_attempt_distribution_centres.phenotype_attempt_id = $1 and
  centres.id = phenotype_attempt_distribution_centres.centre_id and
  (start_date is null or end_date is null or (start_date >= current_date and end_date <= current_date))
  LOOP
      target_name := tmp.name;

      if char_length(tmp.distribution_network) > 0 then
        target_name := tmp.distribution_network;
      end if;

      FOR tmp2 IN select pref, def, (pref like '%PROJECT_ID') as project_id_found, (pref like '%MARKER_SYMBOL') as marker_symbol_found
      from solr_centre_map where centre_name = target_name
      LOOP

        tmp_result := '';
        if char_length(tmp2.pref) > 0 and char_length(project_id) > 0 and tmp2.project_id_found is true then
            select replace(tmp2.pref, 'PROJECT_ID', project_id) into tmp_result;
        end if;

        IF char_length(tmp_result) = 0 and char_length(tmp2.pref) > 0 and char_length(marker_symbol) > 0 and tmp2.marker_symbol_found is true then
            select replace(tmp2.pref, 'MARKER_SYMBOL', marker_symbol) into tmp_result;
        end if;

        if char_length(tmp_result) = 0 and char_length(tmp2.def) > 0 then
            select tmp2.def into tmp_result;
        end if;

        if char_length(tmp_result) > 0 then
          --result := result || tmp_result || ';';
            insert into solr_get_pa_get_order_from_urls_tmp(phenotype_attempt_id, url) values ($1, tmp_result);
        end if;
      END LOOP;
  END LOOP;

  select string_agg(distinct url, ';') into result from solr_get_pa_get_order_from_urls_tmp group by phenotype_attempt_id;

  RETURN result;
  END;
$$ LANGUAGE plpgsql;

-- FUNCTION NAME: solr_get_best_status_pa_cre
--
-- PARAMETERS: phenotype_attempts.id, cre_excision_required
--
-- CORRESPONDING RUBY: in create_for_phenotype_attempt in doc_factory.rb to set best_status_pa_cre_ex_required, best_status_pa_cre_ex_not_required
-- (https://github.com/mpi2/imits/blob/master/app/models/solr_update/doc_factory.rb#L93)
--
-- TEST:
--
-- EQUIVALENCE TEST: test_phenotype_attempt_best_status_pa_cre in ./script/solr_bulk/test/phenotype_attempts_test.rb
--
-- DESCRIPTION: generate best_status_pa_cre_ex_required, best_status_pa_cre_ex_not_required for phenotype_attempt doc type

CREATE OR REPLACE FUNCTION solr_get_best_status_pa_cre (int, boolean)
RETURNS text AS $$
DECLARE
  tmp RECORD; selected_status_name text; selected_status_order_by int; selected_status_in_progress_date timestamp; tmp_in_progress_date timestamp;
BEGIN

  selected_status_name := '';
  selected_status_order_by := 0;
  selected_status_in_progress_date := null;

  FOR tmp IN select phenotype_attempt_statuses.*, phenotype_attempts.id as phenotype_attempt_id, phenotype_attempts.cre_excision_required
  from phenotype_attempts, phenotype_attempt_statuses where phenotype_attempts.id = $1 and phenotype_attempt_statuses.id = phenotype_attempts.status_id
  LOOP

    if $2 = tmp.cre_excision_required then

      select created_at into tmp_in_progress_date from phenotype_attempt_status_stamps where phenotype_attempt_id = tmp.phenotype_attempt_id and status_id = 2;

      if char_length(selected_status_name) = 0 then
        selected_status_name := tmp.name;
        selected_status_order_by := tmp.order_by;
        selected_status_in_progress_date := tmp_in_progress_date;
      end if;

      if tmp.order_by > selected_status_order_by or (tmp.order_by = selected_status_order_by and tmp_in_progress_date > selected_status_in_progress_date) then
        selected_status_name := tmp.name;
        selected_status_order_by := tmp.order_by;
        selected_status_in_progress_date := tmp_in_progress_date;
      end if;

    end if;

  END LOOP;

  RETURN selected_status_name;

END;
$$ LANGUAGE plpgsql;

CREATE temp table solr_get_pa_order_from_names_tmp ( phenotype_attempt_id int, name text ) ;        --ON COMMIT DROP;
CREATE temp table solr_get_pa_get_order_from_urls_tmp ( phenotype_attempt_id int, url text ) ;      --ON COMMIT DROP;

-- TABLE NAME: solr_phenotype_attempts
--
-- TEST:
--
-- EQUIVALENCE TEST: test_solr_phenotype_attempts in ./script/solr_bulk/test/phenotype_attempts_test.rb
--
-- DESCRIPTION: Provides the data for the phenotype_attempt docs. 

CREATE
TABLE
solr_phenotype_attempts as
select
  phenotype_attempts.id as id,
  CAST( 'Mouse' AS text ) as product_type,
  CAST( 'phenotype_attempt' AS text ) as type,
  phenotype_attempts.colony_name as colony_name,
  solr_get_pa_allele_type(phenotype_attempts.id) as allele_type,
  solr_get_pa_allele_name(phenotype_attempts.id) as allele_name,
  solr_get_pa_order_from_names(phenotype_attempts.id) as order_from_names,
  solr_get_pa_get_order_from_urls(phenotype_attempts.id) as order_from_urls,
  targ_rep_es_cells.allele_id as allele_id,
  strains.name as strain,
  genes.mgi_accession_id as mgi_accession_id,
  centres.name as production_centre,

  'http://localhost:3000/targ_rep/alleles/' || targ_rep_es_cells.allele_id || '/allele-image-cre' as allele_image_url,
  'http://localhost:3000/targ_rep/alleles/' || targ_rep_es_cells.allele_id || '/allele-image-cre?simple=true' as simple_allele_image_url,
  'http://localhost:3000/targ_rep/alleles/' || targ_rep_es_cells.allele_id || '/escell-clone-cre-genbank-file' as genbank_file_url,

  targ_rep_es_cells.ikmc_project_id as project_ids,
  genes.marker_symbol as marker_symbol,
  mi_attempts.colony_name as parent_mi_attempt_colony_name,

  solr_get_best_status_pa_cre(phenotype_attempts.id, true) as best_status_pa_cre_ex_required,
  solr_get_best_status_pa_cre(phenotype_attempts.id, false) as best_status_pa_cre_ex_not_required,

  phenotype_attempt_statuses.name as current_pa_status

  from phenotype_attempts, phenotype_attempt_status_stamps s1, mi_attempts, targ_rep_es_cells, strains, genes, mi_plans, centres, phenotype_attempt_statuses

  where
  phenotype_attempt_statuses.id = phenotype_attempts.status_id and
  mi_plans.id = phenotype_attempts.mi_plan_id and centres.id = mi_plans.production_centre_id and
  mi_plans.id = phenotype_attempts.mi_plan_id and mi_plans.gene_id = genes.id and
  phenotype_attempts.colony_background_strain_id = strains.id and
  phenotype_attempts.mi_attempt_id = mi_attempts.id and targ_rep_es_cells.id = mi_attempts.es_cell_id and
  phenotype_attempts.report_to_public is true and s1.phenotype_attempt_id = phenotype_attempts.id and s1.status_id = 6 and
  not exists(select id from phenotype_attempt_status_stamps where phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attempts.id and phenotype_attempt_status_stamps.status_id = 1);
