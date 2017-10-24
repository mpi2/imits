--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.14
-- Dumped by pg_dump version 9.5.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: get_best_status_pa(integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION get_best_status_pa(integer, boolean) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
tmp RECORD; result text; order_by_const int;
BEGIN
    result := '';
    order_by_const := 0;
    FOR tmp IN select phenotype_attempt_statuses.name, phenotype_attempt_statuses.order_by
    from phenotype_attempts, phenotype_attempt_statuses where phenotype_attempts.mi_attempt_id = $1 and
    phenotype_attempt_statuses.id = phenotype_attempts.status_id and phenotype_attempts.cre_excision_required = $2
    LOOP
        if order_by_const = 0 then
            order_by_const := tmp.order_by;
            result := tmp.name;
        end if;
        if order_by_const < tmp.order_by then
            order_by_const := tmp.order_by;
            result := tmp.name;
        end if;
    END LOOP;
    RETURN result;
END;
$_$;


--
-- Name: solr_get_allele_order_from_names(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_allele_order_from_names(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tmp RECORD; result text;
BEGIN
    result := '';
    FOR tmp IN SELECT distinct targ_rep_pipelines.name, targ_rep_es_cells.ikmc_project_id, (targ_rep_es_cells.ikmc_project_id like '^VG') as ikmc_project_id_vg
    from targ_rep_pipelines, targ_rep_es_cells
    where targ_rep_es_cells.pipeline_id = targ_rep_pipelines.id and targ_rep_es_cells.id = $1
    LOOP

        if tmp.name = 'EUCOMM' or tmp.name = 'EUCOMMTools' or tmp.name = 'EUCOMMToolsCre' then
          result := result || 'EUMMCR' || ';';
        elsif tmp.name = 'KOMP-CSD' or tmp.name = 'KOMP-Regeneron' then
            result := result || 'KOMP' || ';';
        elsif tmp.name = 'mirKO' or tmp.name = 'Sanger MGP' then
            result := result || 'Wtsi' || ';';
        elsif tmp.name = 'NorCOMM' then
            result := result || 'NorCOMM' || ';';
        end if;

    END LOOP;
    RETURN result;
END;
$_$;


--
-- Name: solr_get_allele_order_from_urls(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_allele_order_from_urls(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tmp RECORD; result text; project text; marker_symbol text; mgi_accession_id text;
BEGIN
    result := '';

    select genes.marker_symbol into marker_symbol from genes, targ_rep_alleles, targ_rep_es_cells
    where targ_rep_alleles.gene_id = genes.id and targ_rep_es_cells.id = $1
    and targ_rep_alleles.id = targ_rep_es_cells.allele_id;

    select genes.mgi_accession_id into mgi_accession_id from genes, targ_rep_alleles, targ_rep_es_cells
    where targ_rep_alleles.gene_id = genes.id and targ_rep_es_cells.id = $1
    and targ_rep_alleles.id = targ_rep_es_cells.allele_id;

    FOR tmp IN SELECT distinct targ_rep_pipelines.name, targ_rep_es_cells.ikmc_project_id, (targ_rep_es_cells.ikmc_project_id like 'VG%') as ikmc_project_id_vg
    from targ_rep_pipelines, targ_rep_es_cells
    where targ_rep_es_cells.pipeline_id = targ_rep_pipelines.id and targ_rep_es_cells.id = $1
    LOOP

        if tmp.name = 'EUCOMM' or tmp.name = 'EUCOMMTools' or tmp.name = 'EUCOMMToolsCre' then
          result := result || 'http://www.eummcr.org/order?add=' || mgi_accession_id || '&material=es_cells' || ';';
        elsif tmp.name = 'KOMP-CSD' or tmp.name = 'KOMP-Regeneron' then
            if char_length(tmp.ikmc_project_id) > 0 then
              if tmp.ikmc_project_id_vg then
                project := tmp.ikmc_project_id;
              else
                project := 'CSD' || tmp.ikmc_project_id;
              end if;
              result := result || 'http://www.komp.org/geneinfo.php?project=' || project || ';';
            else
              result := result || 'http://www.komp.org/' || ';';
            end if;
        elsif tmp.name = 'mirKO' or tmp.name = 'Sanger MGP' then
            result := result || 'mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for ' || marker_symbol || ';';
        elsif tmp.name = 'NorCOMM' then
            result := result || 'http://www.phenogenomics.ca/services/cmmr/escell_services.html' || ';';
        end if;

    END LOOP;
    RETURN result;
END;
$_$;


--
-- Name: solr_get_best_status_pa_cre(integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_best_status_pa_cre(integer, boolean) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: solr_get_mi_allele_name(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_mi_allele_name(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    tmp RECORD; result text; e boolean; marker_symbol text; marker_symbol2 text; allele_symbol_superscript_plan text; allele_symbol_superscript_template text;mouse_allele_type text;
    result1 text; result2 text; result3 text; allele_symbol_superscript_template_es_cell text; allele_type_es_cell text;
  BEGIN
  result := '';

  select exists(select targ_rep_es_cells.id from targ_rep_es_cells, mi_attempts where targ_rep_es_cells.id = mi_attempts.es_cell_id and mi_attempts.id = $1) into e;
  select mi_plans.allele_symbol_superscript into allele_symbol_superscript_plan from mi_plans, mi_attempts where mi_plans.id = mi_attempts.mi_plan_id and mi_attempts.id = $1;
  select targ_rep_es_cells.allele_symbol_superscript_template into allele_symbol_superscript_template from targ_rep_es_cells, mi_attempts where targ_rep_es_cells.id = mi_attempts.es_cell_id and mi_attempts.id = $1;
  select mi_attempts.mouse_allele_type into mouse_allele_type from mi_attempts where mi_attempts.id = $1;
  select genes.marker_symbol into marker_symbol from genes, mi_plans, mi_attempts where mi_plans.id = mi_attempts.mi_plan_id and mi_plans.gene_id = genes.id and mi_attempts.id = $1;
  select targ_rep_es_cells.allele_symbol_superscript_template into allele_symbol_superscript_template_es_cell from targ_rep_es_cells, mi_attempts where targ_rep_es_cells.id = mi_attempts.es_cell_id and mi_attempts.id = $1;
  select targ_rep_es_cells.allele_type into allele_type_es_cell from targ_rep_es_cells, mi_attempts where targ_rep_es_cells.id = mi_attempts.es_cell_id and mi_attempts.id = $1;

  select genes.marker_symbol into marker_symbol2
  from genes, mi_attempts, targ_rep_es_cells, targ_rep_alleles
  where targ_rep_es_cells.id = mi_attempts.es_cell_id
  and targ_rep_es_cells.allele_id = targ_rep_alleles.id
  and targ_rep_alleles.gene_id = genes.id
  and mi_attempts.id = $1;

  if e then
    if char_length(allele_symbol_superscript_plan) then
      result := marker_symbol || '<sup>' || allele_symbol_superscript_plan || '</sup>';
      RETURN result;
    elsif char_length(allele_symbol_superscript_template) > 0 and char_length(mouse_allele_type) > 0 then
      select replace(allele_symbol_superscript_template, '@', COALESCE(mouse_allele_type, '')) into result1;
      result := marker_symbol || '<sup>' || result1 || '</sup>';
      RETURN result;
    end if;
  end if;

  select replace(allele_symbol_superscript_template_es_cell, '@',  COALESCE(allele_type_es_cell, '')) into result1;

  result := marker_symbol2 || '<sup>' || result1 || '</sup>';
  RETURN result;

  END;
$_$;


--
-- Name: solr_get_mi_order_from_names(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_mi_order_from_names(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
  tmp RECORD; result text; in_config boolean;
  BEGIN
  result := '';

  truncate solr_get_mi_order_from_names_tmp;

  --drop table if exists solr_get_mi_order_from_names_tmp;

  FOR tmp IN SELECT mi_attempt_distribution_centres.distribution_network,
  case
  when centres.name = 'UCD' then 'KOMP'
  else centres.name
  end
  FROM mi_attempt_distribution_centres, centres, solr_centre_map
  where mi_attempt_distribution_centres.mi_attempt_id = $1 and
  centres.id = mi_attempt_distribution_centres.centre_id and
  (start_date is null or end_date is null or (start_date >= current_date and end_date <= current_date)) and
  ( (solr_centre_map.centre_name = centres.name and (char_length(solr_centre_map.pref) > 0 or char_length(solr_centre_map.def) > 0)) or
    (solr_centre_map.centre_name = mi_attempt_distribution_centres.distribution_network and (char_length(solr_centre_map.pref) > 0 or char_length(solr_centre_map.def) > 0)))
  LOOP

    select exists(select centre_name from solr_centre_map where centre_name = tmp.name) into in_config;
    continue when not in_config;

    if char_length(tmp.distribution_network) > 0 then
      --result := result || tmp.distribution_network || ';';
      insert into solr_get_mi_order_from_names_tmp ( name ) values ( tmp.distribution_network );
    else
      --result := result || tmp.name || ';';
      insert into solr_get_mi_order_from_names_tmp ( name ) values ( tmp.name );
    end if;

  END LOOP;

  --select distinct name || ';' into result from solr_get_mi_order_from_names_tmp;
  select string_agg(distinct name, ';') into result from solr_get_mi_order_from_names_tmp;

  RETURN result;
  END;
$_$;


--
-- Name: solr_get_mi_order_from_urls(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_mi_order_from_urls(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
  tmp RECORD; tmp2 RECORD; result text; marker_symbol text; project_id text; tmp_result text; target_name text; in_config boolean;
  BEGIN
  result := '';

  truncate solr_get_mi_order_from_urls_tmp;

  select targ_rep_es_cells.ikmc_project_id
    into project_id
  from mi_attempts, targ_rep_es_cells
  where targ_rep_es_cells.id = mi_attempts.es_cell_id and mi_attempts.id = $1;

  select genes.marker_symbol
    into marker_symbol
  from genes, mi_plans, mi_attempts
  where mi_plans.id = mi_attempts.mi_plan_id and mi_plans.gene_id = genes.id and mi_attempts.id = $1;

  FOR tmp IN SELECT mi_attempt_distribution_centres.distribution_network,
  case
  when centres.name = 'UCD' then 'KOMP'
  else centres.name
  end
  FROM mi_attempt_distribution_centres,centres where mi_attempt_distribution_centres.mi_attempt_id = $1 and
  centres.id = mi_attempt_distribution_centres.centre_id and
  (start_date is null or end_date is null or (start_date >= current_date and end_date <= current_date))
  LOOP
      target_name := tmp.name;

      select exists(select centre_name from solr_centre_map where centre_name = tmp.name) into in_config;
      continue when not in_config;

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
          insert into solr_get_mi_order_from_urls_tmp ( url ) values (tmp_result);
        end if;
      END LOOP;
  END LOOP;

  --select distinct url || ';' into result from solr_get_mi_order_from_urls_tmp;
  select string_agg(distinct url, ';') into result from solr_get_mi_order_from_urls_tmp;

  RETURN result;
  END;
$_$;


--
-- Name: solr_get_pa_allele_name(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_pa_allele_name(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: solr_get_pa_allele_type(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_pa_allele_type(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
$_$;


--
-- Name: solr_get_pa_get_order_from_urls(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_pa_get_order_from_urls(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
  tmp RECORD; tmp2 RECORD; result text; marker_symbol text; project_id text; tmp_result text; target_name text;
  BEGIN
  result := '';

  truncate solr_get_pa_get_order_from_urls_tmp;

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
            insert into solr_get_pa_get_order_from_urls_tmp(phenotype_attempt_id, url) values ($1, tmp_result);
        end if;
      END LOOP;
  END LOOP;

  select string_agg(distinct url, ';') into result from solr_get_pa_get_order_from_urls_tmp group by phenotype_attempt_id;

  RETURN result;
  END;
$_$;


--
-- Name: solr_get_pa_order_from_names(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_get_pa_order_from_names(integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$
  DECLARE
    tmp RECORD; result text;
  BEGIN
  result := '';

  truncate solr_get_pa_order_from_names_tmp;

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

  END LOOP;

  select string_agg(distinct name, ';') into result from solr_get_pa_order_from_names_tmp group by phenotype_attempt_id;

  RETURN result;
  END;
$_$;


--
-- Name: solr_ikmc_projects_details_builder(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION solr_ikmc_projects_details_builder() RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: allele_annotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE allele_annotations (
    id integer NOT NULL,
    allele_id integer NOT NULL,
    mod_type character varying(255) NOT NULL,
    chr character varying(255) NOT NULL,
    start integer NOT NULL,
    "end" integer NOT NULL,
    ref_seq text,
    alt_seq text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: allele_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE allele_annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: allele_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE allele_annotations_id_seq OWNED BY allele_annotations.id;


--
-- Name: alleles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE alleles (
    id integer NOT NULL,
    es_cell_id integer,
    allele_confirmed boolean DEFAULT false NOT NULL,
    mgi_allele_symbol_without_impc_abbreviation boolean,
    mgi_allele_symbol_superscript character varying(255),
    allele_symbol_superscript_template character varying(255),
    mgi_allele_accession_id character varying(255),
    allele_type character varying(255),
    genbank_file_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    colony_id integer,
    auto_allele_description text,
    allele_description text,
    mutant_fa text,
    genbank_transition character varying(255),
    same_as_es_cell boolean,
    allele_subtype character varying(255),
    "contains_lacZ" boolean DEFAULT false
);


--
-- Name: alleles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE alleles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alleles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE alleles_id_seq OWNED BY alleles.id;


--
-- Name: audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE audits (
    id integer NOT NULL,
    auditable_id integer,
    auditable_type character varying(255),
    associated_id integer,
    associated_type character varying(255),
    user_id integer,
    user_type character varying(255),
    username character varying(255),
    action character varying(255),
    audited_changes text,
    version integer DEFAULT 0,
    comment character varying(255),
    remote_address character varying(255),
    created_at timestamp without time zone
);


--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE audits_id_seq OWNED BY audits.id;


--
-- Name: centres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE centres (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    contact_name character varying(100),
    contact_email character varying(100),
    code character varying(255),
    superscript character varying(255)
);


--
-- Name: centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE centres_id_seq OWNED BY centres.id;


--
-- Name: colonies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE colonies (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    mi_attempt_id integer,
    genotype_confirmed boolean DEFAULT false,
    report_to_public boolean DEFAULT true,
    mouse_allele_mod_id integer,
    background_strain_id integer,
    is_released_from_genotyping boolean DEFAULT false,
    genotyping_comment text
);


--
-- Name: colonies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE colonies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colonies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE colonies_id_seq OWNED BY colonies.id;


--
-- Name: colony_distribution_centres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE colony_distribution_centres (
    id integer NOT NULL,
    colony_id integer NOT NULL,
    deposited_material_id integer NOT NULL,
    distribution_network character varying(255),
    centre_id integer NOT NULL,
    start_date date,
    end_date date,
    reconciled character varying(255) DEFAULT 'not checked'::character varying NOT NULL,
    reconciled_at timestamp without time zone,
    available boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: colony_distribution_centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE colony_distribution_centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: colony_distribution_centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE colony_distribution_centres_id_seq OWNED BY colony_distribution_centres.id;


--
-- Name: consortia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE consortia (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    funding character varying(255),
    participants text,
    contact character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: consortia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE consortia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consortia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE consortia_id_seq OWNED BY consortia.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contacts (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    report_to_public boolean DEFAULT true
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: deleter_strains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deleter_strains (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    excision_type character varying(255)
);


--
-- Name: deleter_strains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deleter_strains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deleter_strains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deleter_strains_id_seq OWNED BY deleter_strains.id;


--
-- Name: deposited_materials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deposited_materials (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: deposited_materials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deposited_materials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deposited_materials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deposited_materials_id_seq OWNED BY deposited_materials.id;


--
-- Name: email_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE email_templates (
    id integer NOT NULL,
    status character varying(255),
    welcome_body text,
    update_body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE email_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE email_templates_id_seq OWNED BY email_templates.id;


--
-- Name: es_cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE es_cells (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    allele_symbol_superscript_template character varying(75),
    allele_type character varying(2),
    pipeline_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    gene_id integer NOT NULL,
    parental_cell_line character varying(255),
    ikmc_project_id character varying(100),
    mutation_subtype character varying(100),
    allele_id integer NOT NULL
);


--
-- Name: es_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE es_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: es_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE es_cells_id_seq OWNED BY es_cells.id;


--
-- Name: gene_private_annotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gene_private_annotations (
    id integer NOT NULL,
    gene_id integer NOT NULL,
    idg boolean DEFAULT false,
    cmg_tier1 boolean DEFAULT false,
    cmg_tier2 boolean DEFAULT false
);


--
-- Name: gene_private_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gene_private_annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gene_private_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gene_private_annotations_id_seq OWNED BY gene_private_annotations.id;


--
-- Name: genes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE genes (
    id integer NOT NULL,
    marker_symbol character varying(75) NOT NULL,
    mgi_accession_id character varying(40),
    ikmc_projects_count integer,
    conditional_es_cells_count integer,
    non_conditional_es_cells_count integer,
    deletion_es_cells_count integer,
    other_targeted_mice_count integer,
    other_condtional_mice_count integer,
    mutation_published_as_lethal_count integer,
    publications_for_gene_count integer,
    go_annotations_for_gene_count integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    chr character varying(2),
    start_coordinates integer,
    end_coordinates integer,
    strand_name character varying(255),
    vega_ids character varying(255),
    ncbi_ids character varying(255),
    ensembl_ids character varying(255),
    ccds_ids character varying(255),
    marker_type character varying(255),
    feature_type character varying(255),
    synonyms character varying(255),
    komp_repo_geneid integer,
    marker_name character varying(255),
    cm_position character varying(255),
    human_marker_symbol character varying(255),
    human_entrez_gene_id character varying(255),
    human_homolo_gene_id character varying(255)
);


--
-- Name: genes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE genes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: genes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE genes_id_seq OWNED BY genes.id;


--
-- Name: intermediate_report; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE intermediate_report (
    id integer NOT NULL,
    consortium character varying(255) NOT NULL,
    sub_project character varying(255) NOT NULL,
    priority character varying(255),
    production_centre character varying(255) NOT NULL,
    gene character varying(75) NOT NULL,
    mgi_accession_id character varying(40),
    overall_status character varying(50),
    mi_plan_status character varying(50),
    mi_attempt_status character varying(50),
    phenotype_attempt_status character varying(50),
    ikmc_project_id character varying(255),
    mutation_sub_type character varying(100),
    allele_symbol character varying(255) NOT NULL,
    genetic_background character varying(255) NOT NULL,
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    genotype_confirmed_date date,
    micro_injection_aborted_date date,
    phenotype_attempt_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    distinct_genotype_confirmed_es_cells integer,
    distinct_old_non_genotype_confirmed_es_cells integer,
    mi_plan_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    total_pipeline_efficiency_gene_count integer,
    gc_pipeline_efficiency_gene_count integer,
    is_bespoke_allele boolean,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_colony_name character varying(255),
    mi_attempt_consortium character varying(255),
    mi_attempt_production_centre character varying(255),
    phenotype_attempt_colony_name character varying(255)
);


--
-- Name: intermediate_report_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_id_seq OWNED BY intermediate_report.id;


--
-- Name: intermediate_report_summary_by_centre; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE intermediate_report_summary_by_centre (
    id integer NOT NULL,
    catagory character varying(255) NOT NULL,
    approach character varying(255) NOT NULL,
    allele_type character varying(255) NOT NULL,
    mi_plan_id integer,
    mi_attempt_id integer,
    modified_mouse_allele_mod_id integer,
    mouse_allele_mod_id integer,
    phenotyping_production_id integer,
    production_centre character varying(255),
    gene character varying(255),
    mgi_accession_id character varying(255),
    mi_attempt_external_ref character varying(255),
    mi_attempt_colony_name character varying(255),
    mouse_allele_mod_colony_name character varying(255),
    phenotyping_production_colony_name character varying(255),
    mi_plan_status character varying(255),
    gene_interest_date date,
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_status character varying(255),
    micro_injection_aborted_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    founder_obtained_date date,
    genotype_confirmed_date date,
    mouse_allele_mod_status character varying(255),
    mouse_allele_mod_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_status character varying(255),
    phenotyping_registered_date date,
    phenotyping_rederivation_started_date date,
    phenotyping_rederivation_complete_date date,
    phenotyping_experiments_started_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    created_at date
);


--
-- Name: intermediate_report_summary_by_centre_and_consortia; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE intermediate_report_summary_by_centre_and_consortia (
    id integer NOT NULL,
    catagory character varying(255) NOT NULL,
    approach character varying(255) NOT NULL,
    allele_type character varying(255) NOT NULL,
    mi_plan_id integer,
    mi_attempt_id integer,
    modified_mouse_allele_mod_id integer,
    mouse_allele_mod_id integer,
    phenotyping_production_id integer,
    consortium character varying(255),
    production_centre character varying(255),
    gene character varying(255),
    mgi_accession_id character varying(255),
    mi_attempt_external_ref character varying(255),
    mi_attempt_colony_name character varying(255),
    mouse_allele_mod_colony_name character varying(255),
    phenotyping_production_colony_name character varying(255),
    mi_plan_status character varying(255),
    gene_interest_date date,
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_status character varying(255),
    micro_injection_aborted_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    founder_obtained_date date,
    genotype_confirmed_date date,
    mouse_allele_mod_status character varying(255),
    mouse_allele_mod_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_status character varying(255),
    phenotyping_registered_date date,
    phenotyping_rederivation_started_date date,
    phenotyping_rederivation_complete_date date,
    phenotyping_experiments_started_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    created_at date
);


--
-- Name: intermediate_report_summary_by_centre_and_consortia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_summary_by_centre_and_consortia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_summary_by_centre_and_consortia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_summary_by_centre_and_consortia_id_seq OWNED BY intermediate_report_summary_by_centre_and_consortia.id;


--
-- Name: intermediate_report_summary_by_centre_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_summary_by_centre_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_summary_by_centre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_summary_by_centre_id_seq OWNED BY intermediate_report_summary_by_centre.id;


--
-- Name: intermediate_report_summary_by_consortia; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE intermediate_report_summary_by_consortia (
    id integer NOT NULL,
    catagory character varying(255) NOT NULL,
    approach character varying(255) NOT NULL,
    allele_type character varying(255) NOT NULL,
    mi_plan_id integer,
    mi_attempt_id integer,
    modified_mouse_allele_mod_id integer,
    mouse_allele_mod_id integer,
    phenotyping_production_id integer,
    consortium character varying(255),
    gene character varying(255),
    mgi_accession_id character varying(255),
    mi_attempt_external_ref character varying(255),
    mi_attempt_colony_name character varying(255),
    mouse_allele_mod_colony_name character varying(255),
    phenotyping_production_colony_name character varying(255),
    mi_plan_status character varying(255),
    gene_interest_date date,
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_status character varying(255),
    micro_injection_aborted_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    founder_obtained_date date,
    genotype_confirmed_date date,
    mouse_allele_mod_status character varying(255),
    mouse_allele_mod_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_status character varying(255),
    phenotyping_registered_date date,
    phenotyping_rederivation_started_date date,
    phenotyping_rederivation_complete_date date,
    phenotyping_experiments_started_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    created_at date
);


--
-- Name: intermediate_report_summary_by_consortia_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_summary_by_consortia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_summary_by_consortia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_summary_by_consortia_id_seq OWNED BY intermediate_report_summary_by_consortia.id;


--
-- Name: intermediate_report_summary_by_gene; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE intermediate_report_summary_by_gene (
    id integer NOT NULL,
    catagory character varying(255) NOT NULL,
    approach character varying(255) NOT NULL,
    allele_type character varying(255) NOT NULL,
    mi_plan_id integer,
    mi_attempt_id integer,
    modified_mouse_allele_mod_id integer,
    mouse_allele_mod_id integer,
    phenotyping_production_id integer,
    gene character varying(255),
    mgi_accession_id character varying(255),
    mi_attempt_external_ref character varying(255),
    mi_attempt_colony_name character varying(255),
    mouse_allele_mod_colony_name character varying(255),
    phenotyping_production_colony_name character varying(255),
    mi_plan_status character varying(255),
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_status character varying(255),
    micro_injection_aborted_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    founder_obtained_date date,
    genotype_confirmed_date date,
    mouse_allele_mod_status character varying(255),
    mouse_allele_mod_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_status character varying(255),
    phenotyping_registered_date date,
    phenotyping_rederivation_started_date date,
    phenotyping_rederivation_complete_date date,
    phenotyping_experiments_started_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    created_at date
);


--
-- Name: intermediate_report_summary_by_gene_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_summary_by_gene_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_summary_by_gene_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_summary_by_gene_id_seq OWNED BY intermediate_report_summary_by_gene.id;


--
-- Name: intermediate_report_summary_by_mi_plan; Type: TABLE; Schema: public; Owner: -
--

CREATE UNLOGGED TABLE intermediate_report_summary_by_mi_plan (
    id integer NOT NULL,
    catagory character varying(255) NOT NULL,
    approach character varying(255) NOT NULL,
    allele_type character varying(255) NOT NULL,
    mi_plan_id integer,
    mi_attempt_id integer,
    modified_mouse_allele_mod_id integer,
    mouse_allele_mod_id integer,
    phenotyping_production_id integer,
    consortium character varying(255),
    production_centre character varying(255),
    sub_project character varying(255),
    priority character varying(255),
    gene character varying(255),
    mgi_accession_id character varying(255),
    mi_attempt_external_ref character varying(255),
    mi_attempt_colony_name character varying(255),
    mouse_allele_mod_colony_name character varying(255),
    phenotyping_production_colony_name character varying(255),
    mi_plan_status character varying(255),
    assigned_date date,
    assigned_es_cell_qc_in_progress_date date,
    assigned_es_cell_qc_complete_date date,
    aborted_es_cell_qc_failed_date date,
    mi_attempt_status character varying(255),
    micro_injection_aborted_date date,
    micro_injection_in_progress_date date,
    chimeras_obtained_date date,
    founder_obtained_date date,
    genotype_confirmed_date date,
    mouse_allele_mod_status character varying(255),
    mouse_allele_mod_registered_date date,
    rederivation_started_date date,
    rederivation_complete_date date,
    cre_excision_started_date date,
    cre_excision_complete_date date,
    phenotyping_status character varying(255),
    phenotyping_registered_date date,
    phenotyping_rederivation_started_date date,
    phenotyping_rederivation_complete_date date,
    phenotyping_experiments_started_date date,
    phenotyping_started_date date,
    phenotyping_complete_date date,
    phenotype_attempt_aborted_date date,
    mi_aborted_count integer,
    mi_aborted_max_date date,
    allele_mod_aborted_count integer,
    allele_mod_aborted_max_date date,
    created_at date
);


--
-- Name: intermediate_report_summary_by_mi_plan_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE intermediate_report_summary_by_mi_plan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: intermediate_report_summary_by_mi_plan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE intermediate_report_summary_by_mi_plan_id_seq OWNED BY intermediate_report_summary_by_mi_plan.id;


--
-- Name: mi_attempt_status_stamps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_attempt_status_stamps (
    id integer NOT NULL,
    mi_attempt_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_attempt_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempt_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempt_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempt_status_stamps_id_seq OWNED BY mi_attempt_status_stamps.id;


--
-- Name: mi_attempt_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_attempt_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    order_by integer,
    code character varying(10) NOT NULL
);


--
-- Name: mi_attempt_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempt_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempt_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempt_statuses_id_seq OWNED BY mi_attempt_statuses.id;


--
-- Name: mi_attempts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_attempts (
    id integer NOT NULL,
    es_cell_id integer,
    mi_date date NOT NULL,
    status_id integer NOT NULL,
    external_ref character varying(125),
    updated_by_id integer,
    blast_strain_id integer,
    total_blasts_injected integer,
    total_transferred integer,
    number_surrogates_receiving integer,
    total_pups_born integer,
    total_female_chimeras integer,
    total_male_chimeras integer,
    total_chimeras integer,
    number_of_males_with_0_to_39_percent_chimerism integer,
    number_of_males_with_40_to_79_percent_chimerism integer,
    number_of_males_with_80_to_99_percent_chimerism integer,
    number_of_males_with_100_percent_chimerism integer,
    test_cross_strain_id integer,
    date_chimeras_mated date,
    number_of_chimera_matings_attempted integer,
    number_of_chimera_matings_successful integer,
    number_of_chimeras_with_glt_from_cct integer,
    number_of_chimeras_with_glt_from_genotyping integer,
    number_of_chimeras_with_0_to_9_percent_glt integer,
    number_of_chimeras_with_10_to_49_percent_glt integer,
    number_of_chimeras_with_50_to_99_percent_glt integer,
    number_of_chimeras_with_100_percent_glt integer,
    total_f1_mice_from_matings integer,
    number_of_cct_offspring integer,
    number_of_het_offspring integer,
    number_of_live_glt_offspring integer,
    report_to_public boolean DEFAULT true NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    comments text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mi_plan_id integer NOT NULL,
    legacy_es_cell_id integer,
    cassette_transmission_verified date,
    cassette_transmission_verified_auto_complete boolean,
    mutagenesis_factor_id integer,
    crsp_total_embryos_injected integer,
    crsp_total_embryos_survived integer,
    crsp_total_transfered integer,
    crsp_no_founder_pups integer,
    crsp_num_founders_selected_for_breading integer,
    allele_id integer,
    founder_num_assays integer,
    assay_type text,
    experimental boolean DEFAULT false NOT NULL,
    allele_target character varying(255),
    parent_colony_id integer,
    mrna_nuclease character varying(255),
    mrna_nuclease_concentration double precision,
    protein_nuclease character varying(255),
    protein_nuclease_concentration double precision,
    delivery_method character varying(255),
    voltage double precision,
    number_of_pulses integer,
    crsp_embryo_transfer_day character varying(255) DEFAULT 'Same Day'::character varying,
    crsp_embryo_2_cell integer
);


--
-- Name: mi_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_attempts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_attempts_id_seq OWNED BY mi_attempts.id;


--
-- Name: mi_plan_es_cell_qcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plan_es_cell_qcs (
    id integer NOT NULL,
    number_starting_qc integer,
    number_passing_qc integer,
    mi_plan_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mi_plan_es_cell_qcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_es_cell_qcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_es_cell_qcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_es_cell_qcs_id_seq OWNED BY mi_plan_es_cell_qcs.id;


--
-- Name: mi_plan_es_qc_comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plan_es_qc_comments (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_es_qc_comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_es_qc_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_es_qc_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_es_qc_comments_id_seq OWNED BY mi_plan_es_qc_comments.id;


--
-- Name: mi_plan_priorities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plan_priorities (
    id integer NOT NULL,
    name character varying(10) NOT NULL,
    description character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_priorities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_priorities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_priorities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_priorities_id_seq OWNED BY mi_plan_priorities.id;


--
-- Name: mi_plan_status_stamps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plan_status_stamps (
    id integer NOT NULL,
    mi_plan_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_status_stamps_id_seq OWNED BY mi_plan_status_stamps.id;


--
-- Name: mi_plan_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plan_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description character varying(255),
    order_by integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    code character varying(10) NOT NULL
);


--
-- Name: mi_plan_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_statuses_id_seq OWNED BY mi_plan_statuses.id;


--
-- Name: mi_plan_sub_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plan_sub_projects (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: mi_plan_sub_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plan_sub_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plan_sub_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plan_sub_projects_id_seq OWNED BY mi_plan_sub_projects.id;


--
-- Name: mi_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mi_plans (
    id integer NOT NULL,
    gene_id integer NOT NULL,
    consortium_id integer NOT NULL,
    status_id integer NOT NULL,
    priority_id integer,
    production_centre_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    number_of_es_cells_starting_qc integer,
    number_of_es_cells_passing_qc integer,
    sub_project_id integer NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    is_bespoke_allele boolean DEFAULT false NOT NULL,
    is_conditional_allele boolean DEFAULT false NOT NULL,
    is_deletion_allele boolean DEFAULT false NOT NULL,
    is_cre_knock_in_allele boolean DEFAULT false NOT NULL,
    is_cre_bac_allele boolean DEFAULT false NOT NULL,
    comment text,
    withdrawn boolean DEFAULT false NOT NULL,
    es_qc_comment_id integer,
    phenotype_only boolean DEFAULT false,
    completion_note character varying(100),
    recovery boolean,
    conditional_tm1c boolean DEFAULT false NOT NULL,
    ignore_available_mice boolean DEFAULT false NOT NULL,
    number_of_es_cells_received integer,
    es_cells_received_on date,
    es_cells_received_from_id integer,
    point_mutation boolean DEFAULT false NOT NULL,
    conditional_point_mutation boolean DEFAULT false NOT NULL,
    allele_symbol_superscript text,
    report_to_public boolean DEFAULT true NOT NULL,
    completion_comment text,
    mutagenesis_via_crispr_cas9 boolean DEFAULT false
);


--
-- Name: mi_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mi_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mi_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mi_plans_id_seq OWNED BY mi_plans.id;


--
-- Name: mouse_allele_mod_status_stamps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mouse_allele_mod_status_stamps (
    id integer NOT NULL,
    mouse_allele_mod_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mouse_allele_mod_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mouse_allele_mod_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mouse_allele_mod_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mouse_allele_mod_status_stamps_id_seq OWNED BY mouse_allele_mod_status_stamps.id;


--
-- Name: mouse_allele_mod_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mouse_allele_mod_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    order_by integer NOT NULL,
    code character varying(4) NOT NULL
);


--
-- Name: mouse_allele_mod_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mouse_allele_mod_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mouse_allele_mod_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mouse_allele_mod_statuses_id_seq OWNED BY mouse_allele_mod_statuses.id;


--
-- Name: mouse_allele_mods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mouse_allele_mods (
    id integer NOT NULL,
    mi_plan_id integer NOT NULL,
    status_id integer NOT NULL,
    rederivation_started boolean DEFAULT false NOT NULL,
    rederivation_complete boolean DEFAULT false NOT NULL,
    number_of_cre_matings_started integer DEFAULT 0 NOT NULL,
    number_of_cre_matings_successful integer DEFAULT 0 NOT NULL,
    cre_excision boolean DEFAULT true NOT NULL,
    tat_cre boolean DEFAULT false,
    deleter_strain_id integer,
    is_active boolean DEFAULT true NOT NULL,
    report_to_public boolean DEFAULT true NOT NULL,
    phenotype_attempt_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    allele_id integer,
    parent_colony_id integer
);


--
-- Name: mouse_allele_mods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mouse_allele_mods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mouse_allele_mods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mouse_allele_mods_id_seq OWNED BY mouse_allele_mods.id;


--
-- Name: mutagenesis_factor_donors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mutagenesis_factor_donors (
    id integer NOT NULL,
    mutagenesis_factor_id integer NOT NULL,
    vector_id integer,
    concentration double precision,
    preparation character varying(255),
    oligo_sequence_fa text
);


--
-- Name: mutagenesis_factor_donors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mutagenesis_factor_donors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mutagenesis_factor_donors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mutagenesis_factor_donors_id_seq OWNED BY mutagenesis_factor_donors.id;


--
-- Name: mutagenesis_factors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mutagenesis_factors (
    id integer NOT NULL,
    external_ref character varying(255),
    individually_set_grna_concentrations boolean DEFAULT false NOT NULL,
    guides_generated_in_plasmid boolean DEFAULT false NOT NULL,
    grna_concentration double precision,
    no_g0_where_mutation_detected integer,
    no_nhej_g0_mutants integer,
    no_deletion_g0_mutants integer,
    no_hr_g0_mutants integer,
    no_hdr_g0_mutants integer,
    no_hdr_g0_mutants_all_donors_inserted integer,
    no_hdr_g0_mutants_subset_donors_inserted integer
);


--
-- Name: mutagenesis_factors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mutagenesis_factors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mutagenesis_factors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mutagenesis_factors_id_seq OWNED BY mutagenesis_factors.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE notifications (
    id integer NOT NULL,
    welcome_email_sent timestamp without time zone,
    welcome_email_text text,
    last_email_sent timestamp without time zone,
    last_email_text text,
    gene_id integer NOT NULL,
    contact_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE notifications_id_seq OWNED BY notifications.id;


--
-- Name: phenotype_attempt_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotype_attempt_ids (
    id integer NOT NULL
);


--
-- Name: phenotype_attempt_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotype_attempt_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotype_attempt_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotype_attempt_ids_id_seq OWNED BY phenotype_attempt_ids.id;


--
-- Name: phenotyping_production_late_adult_status_stamps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotyping_production_late_adult_status_stamps (
    id integer NOT NULL,
    phenotyping_production_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: phenotyping_production_late_adult_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotyping_production_late_adult_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotyping_production_late_adult_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotyping_production_late_adult_status_stamps_id_seq OWNED BY phenotyping_production_late_adult_status_stamps.id;


--
-- Name: phenotyping_production_late_adult_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotyping_production_late_adult_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    order_by character varying(255),
    "integer" character varying(255),
    code character varying(10),
    string character varying(10),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: phenotyping_production_late_adult_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotyping_production_late_adult_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotyping_production_late_adult_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotyping_production_late_adult_statuses_id_seq OWNED BY phenotyping_production_late_adult_statuses.id;


--
-- Name: phenotyping_production_status_stamps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotyping_production_status_stamps (
    id integer NOT NULL,
    phenotyping_production_id integer NOT NULL,
    status_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: phenotyping_production_status_stamps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotyping_production_status_stamps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotyping_production_status_stamps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotyping_production_status_stamps_id_seq OWNED BY phenotyping_production_status_stamps.id;


--
-- Name: phenotyping_production_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotyping_production_statuses (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    order_by integer NOT NULL,
    code character varying(4) NOT NULL
);


--
-- Name: phenotyping_production_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotyping_production_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotyping_production_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotyping_production_statuses_id_seq OWNED BY phenotyping_production_statuses.id;


--
-- Name: phenotyping_production_tissue_distribution_centres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotyping_production_tissue_distribution_centres (
    id integer NOT NULL,
    start_date date,
    end_date date,
    phenotyping_production_id integer NOT NULL,
    deposited_material character varying(255) NOT NULL,
    centre_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: phenotyping_production_tissue_distribution_centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotyping_production_tissue_distribution_centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotyping_production_tissue_distribution_centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotyping_production_tissue_distribution_centres_id_seq OWNED BY phenotyping_production_tissue_distribution_centres.id;


--
-- Name: phenotyping_productions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE phenotyping_productions (
    id integer NOT NULL,
    mi_plan_id integer NOT NULL,
    status_id integer NOT NULL,
    colony_name character varying(255),
    phenotyping_experiments_started date,
    phenotyping_started boolean DEFAULT false NOT NULL,
    phenotyping_complete boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    report_to_public boolean DEFAULT true NOT NULL,
    phenotype_attempt_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ready_for_website date,
    parent_colony_id integer,
    colony_background_strain_id integer,
    rederivation_started boolean DEFAULT false NOT NULL,
    rederivation_complete boolean DEFAULT false NOT NULL,
    cohort_production_centre_id integer,
    selected_for_late_adult_phenotyping boolean DEFAULT false,
    late_adult_phenotyping_started boolean DEFAULT false,
    late_adult_phenotyping_complete boolean DEFAULT false,
    late_adult_is_active boolean DEFAULT true,
    late_adult_report_to_public boolean DEFAULT true,
    late_adult_phenotyping_experiments_started date,
    late_adult_status_id integer
);


--
-- Name: phenotyping_productions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE phenotyping_productions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: phenotyping_productions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE phenotyping_productions_id_seq OWNED BY phenotyping_productions.id;


--
-- Name: pipelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pipelines (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pipelines_id_seq OWNED BY pipelines.id;


--
-- Name: production_centre_qcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE production_centre_qcs (
    id integer NOT NULL,
    allele_id integer,
    five_prime_screen character varying(255),
    three_prime_screen character varying(255),
    loxp_screen character varying(255),
    loss_of_allele character varying(255),
    vector_integrity character varying(255),
    southern_blot character varying(255),
    five_prime_lr_pcr character varying(255),
    five_prime_cassette_integrity character varying(255),
    tv_backbone_assay character varying(255),
    neo_count_qpcr character varying(255),
    lacz_count_qpcr character varying(255),
    neo_sr_pcr character varying(255),
    loa_qpcr character varying(255),
    homozygous_loa_sr_pcr character varying(255),
    lacz_sr_pcr character varying(255),
    mutant_specific_sr_pcr character varying(255),
    loxp_confirmation character varying(255),
    three_prime_lr_pcr character varying(255),
    critical_region_qpcr character varying(255),
    loxp_srpcr character varying(255),
    loxp_srpcr_and_sequencing character varying(255)
);


--
-- Name: production_centre_qcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE production_centre_qcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_centre_qcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE production_centre_qcs_id_seq OWNED BY production_centre_qcs.id;


--
-- Name: production_goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE production_goals (
    id integer NOT NULL,
    consortium_id integer,
    year integer,
    month integer,
    mi_goal integer,
    gc_goal integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    crispr_mi_goal integer,
    crispr_gc_goal integer,
    total_mi_goal integer,
    total_gc_goal integer
);


--
-- Name: production_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE production_goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE production_goals_id_seq OWNED BY production_goals.id;


--
-- Name: qc_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE qc_results (
    id integer NOT NULL,
    description character varying(50) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: qc_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE qc_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: qc_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE qc_results_id_seq OWNED BY qc_results.id;


--
-- Name: reagent_names; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE reagent_names (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description text
);


--
-- Name: reagent_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reagent_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagent_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reagent_names_id_seq OWNED BY reagent_names.id;


--
-- Name: reagents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE reagents (
    id integer NOT NULL,
    mi_attempt_id integer NOT NULL,
    reagent_id integer NOT NULL,
    concentration double precision
);


--
-- Name: reagents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE reagents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reagents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE reagents_id_seq OWNED BY reagents.id;


--
-- Name: report_caches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE report_caches (
    id integer NOT NULL,
    name text NOT NULL,
    data text NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    format text NOT NULL
);


--
-- Name: report_caches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE report_caches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_caches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_caches_id_seq OWNED BY report_caches.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: strains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE strains (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mgi_strain_accession_id character varying(100),
    mgi_strain_name character varying(100),
    background_strain boolean DEFAULT false,
    test_cross_strain boolean DEFAULT false,
    blast_strain boolean DEFAULT false
);


--
-- Name: strains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE strains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: strains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE strains_id_seq OWNED BY strains.id;


--
-- Name: targ_rep_allele_sequence_annotations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_allele_sequence_annotations (
    id integer NOT NULL,
    mutation_type character varying(255),
    expected character varying(255),
    actual character varying(255),
    comment text,
    oligos_start_coordinate integer,
    oligos_end_coordinate integer,
    mutation_length integer,
    genomic_start_coordinate integer,
    genomic_end_coordinate integer,
    allele_id integer
);


--
-- Name: targ_rep_allele_sequence_annotations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_allele_sequence_annotations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_allele_sequence_annotations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_allele_sequence_annotations_id_seq OWNED BY targ_rep_allele_sequence_annotations.id;


--
-- Name: targ_rep_alleles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_alleles (
    id integer NOT NULL,
    gene_id integer,
    assembly character varying(255) DEFAULT 'GRCm38'::character varying NOT NULL,
    chromosome character varying(2) NOT NULL,
    strand character varying(1) NOT NULL,
    homology_arm_start integer,
    homology_arm_end integer,
    loxp_start integer,
    loxp_end integer,
    cassette_start integer,
    cassette_end integer,
    cassette character varying(100),
    backbone character varying(100),
    subtype_description character varying(255),
    floxed_start_exon character varying(255),
    floxed_end_exon character varying(255),
    project_design_id integer,
    reporter character varying(255),
    mutation_method_id integer,
    mutation_type_id integer,
    mutation_subtype_id integer,
    cassette_type character varying(50),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    intron integer,
    type character varying(255) DEFAULT 'TargRep::TargetedAllele'::character varying,
    has_issue boolean DEFAULT false NOT NULL,
    issue_description text,
    sequence text,
    taqman_critical_del_assay_id character varying(255),
    taqman_upstream_del_assay_id character varying(255),
    taqman_downstream_del_assay_id character varying(255),
    wildtype_oligos_sequence character varying(255),
    allele_genbank_file_id integer,
    vector_genbank_file_id integer
);


--
-- Name: targ_rep_alleles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_alleles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_alleles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_alleles_id_seq OWNED BY targ_rep_alleles.id;


--
-- Name: targ_rep_centre_pipelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_centre_pipelines (
    id integer NOT NULL,
    name character varying(255),
    centres text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_centre_pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_centre_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_centre_pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_centre_pipelines_id_seq OWNED BY targ_rep_centre_pipelines.id;


--
-- Name: targ_rep_crisprs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_crisprs (
    id integer NOT NULL,
    mutagenesis_factor_id integer NOT NULL,
    sequence character varying(255) NOT NULL,
    chr character varying(255),
    start integer,
    "end" integer,
    created_at timestamp without time zone,
    truncated_guide boolean DEFAULT false,
    grna_concentration double precision
);


--
-- Name: targ_rep_crisprs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_crisprs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_crisprs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_crisprs_id_seq OWNED BY targ_rep_crisprs.id;


--
-- Name: targ_rep_distribution_qcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_distribution_qcs (
    id integer NOT NULL,
    five_prime_sr_pcr character varying(255),
    three_prime_sr_pcr character varying(255),
    karyotype_low double precision,
    karyotype_high double precision,
    copy_number character varying(255),
    five_prime_lr_pcr character varying(255),
    three_prime_lr_pcr character varying(255),
    thawing character varying(255),
    loa character varying(255),
    loxp character varying(255),
    lacz character varying(255),
    chr1 character varying(255),
    chr8a character varying(255),
    chr8b character varying(255),
    chr11a character varying(255),
    chr11b character varying(255),
    chry character varying(255),
    es_cell_id integer,
    es_cell_distribution_centre_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    loxp_srpcr character varying(255),
    unspecified_repository_testing character varying(255),
    neo_qpcr character varying(255)
);


--
-- Name: targ_rep_distribution_qcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_distribution_qcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_distribution_qcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_distribution_qcs_id_seq OWNED BY targ_rep_distribution_qcs.id;


--
-- Name: targ_rep_es_cell_distribution_centres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_es_cell_distribution_centres (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_es_cell_distribution_centres_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_es_cell_distribution_centres_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_es_cell_distribution_centres_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_es_cell_distribution_centres_id_seq OWNED BY targ_rep_es_cell_distribution_centres.id;


--
-- Name: targ_rep_es_cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_es_cells (
    id integer NOT NULL,
    allele_id integer NOT NULL,
    targeting_vector_id integer,
    parental_cell_line character varying(255),
    name character varying(100) NOT NULL,
    comment character varying(255),
    contact character varying(255),
    ikmc_project_id character varying(255),
    pipeline_id integer,
    report_to_public boolean DEFAULT true NOT NULL,
    strain character varying(25),
    user_qc_map_test character varying(255),
    user_qc_karyotype character varying(255),
    user_qc_tv_backbone_assay character varying(255),
    user_qc_loxp_confirmation character varying(255),
    user_qc_southern_blot character varying(255),
    user_qc_loss_of_wt_allele character varying(255),
    user_qc_neo_count_qpcr character varying(255),
    user_qc_lacz_sr_pcr character varying(255),
    user_qc_mutant_specific_sr_pcr character varying(255),
    user_qc_five_prime_cassette_integrity character varying(255),
    user_qc_neo_sr_pcr character varying(255),
    user_qc_five_prime_lr_pcr character varying(255),
    user_qc_three_prime_lr_pcr character varying(255),
    user_qc_comment text,
    mutation_subtype character varying(100),
    legacy_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    production_centre_auto_update boolean DEFAULT true,
    user_qc_loxp_srpcr_and_sequencing character varying(255),
    user_qc_karyotype_spread character varying(255),
    user_qc_karyotype_pcr character varying(255),
    user_qc_mouse_clinic_id integer,
    user_qc_chr1 character varying(255),
    user_qc_chr11 character varying(255),
    user_qc_chr8 character varying(255),
    user_qc_chry character varying(255),
    user_qc_lacz_qpcr character varying(255),
    ikmc_project_foreign_id integer
);


--
-- Name: targ_rep_mutation_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_mutation_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    allele_code character varying(5)
);


--
-- Name: targ_rep_es_cell_mutation_types; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW targ_rep_es_cell_mutation_types AS
 SELECT es.id AS es_cell_id,
    types.name AS mutation_type
   FROM ((targ_rep_es_cells es
     LEFT JOIN targ_rep_alleles al ON ((es.allele_id = al.id)))
     LEFT JOIN targ_rep_mutation_types types ON ((al.mutation_type_id = types.id)));


--
-- Name: targ_rep_es_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_es_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_es_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_es_cells_id_seq OWNED BY targ_rep_es_cells.id;


--
-- Name: targ_rep_genbank_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_genbank_files (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    file_gb text
);


--
-- Name: targ_rep_genbank_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_genbank_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_genbank_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_genbank_files_id_seq OWNED BY targ_rep_genbank_files.id;


--
-- Name: targ_rep_genotype_primers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_genotype_primers (
    id integer NOT NULL,
    sequence character varying(255) NOT NULL,
    name character varying(255),
    genomic_start_coordinate integer,
    genomic_end_coordinate integer,
    mutagenesis_factor_id integer,
    allele_id integer
);


--
-- Name: targ_rep_genotype_primers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_genotype_primers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_genotype_primers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_genotype_primers_id_seq OWNED BY targ_rep_genotype_primers.id;


--
-- Name: targ_rep_ikmc_project_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_ikmc_project_statuses (
    id integer NOT NULL,
    name character varying(255),
    product_type character varying(255),
    order_by integer
);


--
-- Name: targ_rep_ikmc_project_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_ikmc_project_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_ikmc_project_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_ikmc_project_statuses_id_seq OWNED BY targ_rep_ikmc_project_statuses.id;


--
-- Name: targ_rep_ikmc_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_ikmc_projects (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    status_id integer,
    pipeline_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_ikmc_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_ikmc_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_ikmc_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_ikmc_projects_id_seq OWNED BY targ_rep_ikmc_projects.id;


--
-- Name: targ_rep_mutation_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_mutation_methods (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    allele_prefix character varying(5)
);


--
-- Name: targ_rep_mutation_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_mutation_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_mutation_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_mutation_methods_id_seq OWNED BY targ_rep_mutation_methods.id;


--
-- Name: targ_rep_mutation_subtypes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_mutation_subtypes (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: targ_rep_mutation_subtypes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_mutation_subtypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_mutation_subtypes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_mutation_subtypes_id_seq OWNED BY targ_rep_mutation_subtypes.id;


--
-- Name: targ_rep_mutation_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_mutation_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_mutation_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_mutation_types_id_seq OWNED BY targ_rep_mutation_types.id;


--
-- Name: targ_rep_pipelines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_pipelines (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    legacy_id integer,
    report_to_public boolean DEFAULT true,
    gene_trap boolean DEFAULT false
);


--
-- Name: targ_rep_pipelines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_pipelines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_pipelines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_pipelines_id_seq OWNED BY targ_rep_pipelines.id;


--
-- Name: targ_rep_sequence_annotation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_sequence_annotation (
    id integer NOT NULL,
    coordinate_start integer,
    expected_sequence character varying(255),
    actual_sequence character varying(255),
    allele_id integer
);


--
-- Name: targ_rep_sequence_annotation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_sequence_annotation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_sequence_annotation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_sequence_annotation_id_seq OWNED BY targ_rep_sequence_annotation.id;


--
-- Name: targ_rep_targeting_vectors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE targ_rep_targeting_vectors (
    id integer NOT NULL,
    allele_id integer NOT NULL,
    name character varying(255) NOT NULL,
    ikmc_project_id character varying(255),
    intermediate_vector character varying(255),
    report_to_public boolean NOT NULL,
    pipeline_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ikmc_project_foreign_id integer,
    mgi_allele_name_prediction character varying(40),
    allele_type_prediction character varying(10),
    production_centre_auto_update boolean DEFAULT true NOT NULL
);


--
-- Name: targ_rep_targeting_vectors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE targ_rep_targeting_vectors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: targ_rep_targeting_vectors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE targ_rep_targeting_vectors_id_seq OWNED BY targ_rep_targeting_vectors.id;


--
-- Name: trace_call_vcf_modifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE trace_call_vcf_modifications (
    id integer NOT NULL,
    trace_call_id integer NOT NULL,
    mod_type character varying(255) NOT NULL,
    chr character varying(255) NOT NULL,
    start integer NOT NULL,
    "end" integer NOT NULL,
    ref_seq text NOT NULL,
    alt_seq text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: trace_call_vcf_modifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trace_call_vcf_modifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trace_call_vcf_modifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trace_call_vcf_modifications_id_seq OWNED BY trace_call_vcf_modifications.id;


--
-- Name: trace_calls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE trace_calls (
    id integer NOT NULL,
    colony_id integer NOT NULL,
    file_alignment text,
    file_filtered_analysis_vcf text,
    file_variant_effect_output_txt text,
    file_reference_fa text,
    file_mutant_fa text,
    file_primer_reads_fa text,
    file_alignment_data_yaml text,
    file_trace_output text,
    file_trace_error text,
    file_exception_details text,
    file_return_code integer,
    file_merged_variants_vcf text,
    is_het boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    trace_file_file_name character varying(255),
    trace_file_content_type character varying(255),
    trace_file_file_size integer,
    trace_file_updated_at timestamp without time zone,
    exon_id character varying(255)
);


--
-- Name: trace_calls_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trace_calls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trace_calls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trace_calls_id_seq OWNED BY trace_calls.id;


--
-- Name: trace_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE trace_files (
    id integer NOT NULL,
    style character varying(255),
    file_contents bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    trace_call_id integer NOT NULL
);


--
-- Name: trace_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE trace_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: trace_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE trace_files_id_seq OWNED BY trace_files.id;


--
-- Name: tracking_goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tracking_goals (
    id integer NOT NULL,
    production_centre_id integer,
    date date,
    goal_type character varying(255),
    goal integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    consortium_id integer,
    crispr_goal integer DEFAULT 0,
    total_goal integer DEFAULT 0
);


--
-- Name: tracking_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tracking_goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracking_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tracking_goals_id_seq OWNED BY tracking_goals.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(128) DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp without time zone,
    production_centre_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    name character varying(255),
    is_contactable boolean DEFAULT false,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    es_cell_distribution_centre_id integer,
    legacy_id integer,
    admin boolean DEFAULT false,
    active boolean DEFAULT true,
    filter_by_centre_id character varying(255)
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY allele_annotations ALTER COLUMN id SET DEFAULT nextval('allele_annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY alleles ALTER COLUMN id SET DEFAULT nextval('alleles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits ALTER COLUMN id SET DEFAULT nextval('audits_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY centres ALTER COLUMN id SET DEFAULT nextval('centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY colonies ALTER COLUMN id SET DEFAULT nextval('colonies_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY colony_distribution_centres ALTER COLUMN id SET DEFAULT nextval('colony_distribution_centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY consortia ALTER COLUMN id SET DEFAULT nextval('consortia_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deleter_strains ALTER COLUMN id SET DEFAULT nextval('deleter_strains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposited_materials ALTER COLUMN id SET DEFAULT nextval('deposited_materials_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_templates ALTER COLUMN id SET DEFAULT nextval('email_templates_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY es_cells ALTER COLUMN id SET DEFAULT nextval('es_cells_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gene_private_annotations ALTER COLUMN id SET DEFAULT nextval('gene_private_annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY genes ALTER COLUMN id SET DEFAULT nextval('genes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report ALTER COLUMN id SET DEFAULT nextval('intermediate_report_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_centre ALTER COLUMN id SET DEFAULT nextval('intermediate_report_summary_by_centre_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_centre_and_consortia ALTER COLUMN id SET DEFAULT nextval('intermediate_report_summary_by_centre_and_consortia_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_consortia ALTER COLUMN id SET DEFAULT nextval('intermediate_report_summary_by_consortia_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_gene ALTER COLUMN id SET DEFAULT nextval('intermediate_report_summary_by_gene_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_mi_plan ALTER COLUMN id SET DEFAULT nextval('intermediate_report_summary_by_mi_plan_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_status_stamps ALTER COLUMN id SET DEFAULT nextval('mi_attempt_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_statuses ALTER COLUMN id SET DEFAULT nextval('mi_attempt_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts ALTER COLUMN id SET DEFAULT nextval('mi_attempts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_cell_qcs ALTER COLUMN id SET DEFAULT nextval('mi_plan_es_cell_qcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_qc_comments ALTER COLUMN id SET DEFAULT nextval('mi_plan_es_qc_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_priorities ALTER COLUMN id SET DEFAULT nextval('mi_plan_priorities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps ALTER COLUMN id SET DEFAULT nextval('mi_plan_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_statuses ALTER COLUMN id SET DEFAULT nextval('mi_plan_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_sub_projects ALTER COLUMN id SET DEFAULT nextval('mi_plan_sub_projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans ALTER COLUMN id SET DEFAULT nextval('mi_plans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mod_status_stamps ALTER COLUMN id SET DEFAULT nextval('mouse_allele_mod_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mod_statuses ALTER COLUMN id SET DEFAULT nextval('mouse_allele_mod_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods ALTER COLUMN id SET DEFAULT nextval('mouse_allele_mods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mutagenesis_factor_donors ALTER COLUMN id SET DEFAULT nextval('mutagenesis_factor_donors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mutagenesis_factors ALTER COLUMN id SET DEFAULT nextval('mutagenesis_factors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications ALTER COLUMN id SET DEFAULT nextval('notifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_ids ALTER COLUMN id SET DEFAULT nextval('phenotype_attempt_ids_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_late_adult_status_stamps ALTER COLUMN id SET DEFAULT nextval('phenotyping_production_late_adult_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_late_adult_statuses ALTER COLUMN id SET DEFAULT nextval('phenotyping_production_late_adult_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_status_stamps ALTER COLUMN id SET DEFAULT nextval('phenotyping_production_status_stamps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_statuses ALTER COLUMN id SET DEFAULT nextval('phenotyping_production_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_tissue_distribution_centres ALTER COLUMN id SET DEFAULT nextval('phenotyping_production_tissue_distribution_centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_productions ALTER COLUMN id SET DEFAULT nextval('phenotyping_productions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pipelines ALTER COLUMN id SET DEFAULT nextval('pipelines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY production_centre_qcs ALTER COLUMN id SET DEFAULT nextval('production_centre_qcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY production_goals ALTER COLUMN id SET DEFAULT nextval('production_goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY qc_results ALTER COLUMN id SET DEFAULT nextval('qc_results_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reagent_names ALTER COLUMN id SET DEFAULT nextval('reagent_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY reagents ALTER COLUMN id SET DEFAULT nextval('reagents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_caches ALTER COLUMN id SET DEFAULT nextval('report_caches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY strains ALTER COLUMN id SET DEFAULT nextval('strains_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_allele_sequence_annotations ALTER COLUMN id SET DEFAULT nextval('targ_rep_allele_sequence_annotations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_alleles ALTER COLUMN id SET DEFAULT nextval('targ_rep_alleles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_centre_pipelines ALTER COLUMN id SET DEFAULT nextval('targ_rep_centre_pipelines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_crisprs ALTER COLUMN id SET DEFAULT nextval('targ_rep_crisprs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_distribution_qcs ALTER COLUMN id SET DEFAULT nextval('targ_rep_distribution_qcs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cell_distribution_centres ALTER COLUMN id SET DEFAULT nextval('targ_rep_es_cell_distribution_centres_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cells ALTER COLUMN id SET DEFAULT nextval('targ_rep_es_cells_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genbank_files ALTER COLUMN id SET DEFAULT nextval('targ_rep_genbank_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genotype_primers ALTER COLUMN id SET DEFAULT nextval('targ_rep_genotype_primers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_ikmc_project_statuses ALTER COLUMN id SET DEFAULT nextval('targ_rep_ikmc_project_statuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_ikmc_projects ALTER COLUMN id SET DEFAULT nextval('targ_rep_ikmc_projects_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_methods ALTER COLUMN id SET DEFAULT nextval('targ_rep_mutation_methods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_subtypes ALTER COLUMN id SET DEFAULT nextval('targ_rep_mutation_subtypes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_types ALTER COLUMN id SET DEFAULT nextval('targ_rep_mutation_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_pipelines ALTER COLUMN id SET DEFAULT nextval('targ_rep_pipelines_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_sequence_annotation ALTER COLUMN id SET DEFAULT nextval('targ_rep_sequence_annotation_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_targeting_vectors ALTER COLUMN id SET DEFAULT nextval('targ_rep_targeting_vectors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_call_vcf_modifications ALTER COLUMN id SET DEFAULT nextval('trace_call_vcf_modifications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_calls ALTER COLUMN id SET DEFAULT nextval('trace_calls_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_files ALTER COLUMN id SET DEFAULT nextval('trace_files_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracking_goals ALTER COLUMN id SET DEFAULT nextval('tracking_goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: allele_annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY allele_annotations
    ADD CONSTRAINT allele_annotations_pkey PRIMARY KEY (id);


--
-- Name: alleles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY alleles
    ADD CONSTRAINT alleles_pkey PRIMARY KEY (id);


--
-- Name: audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY centres
    ADD CONSTRAINT centres_pkey PRIMARY KEY (id);


--
-- Name: colonies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY colonies
    ADD CONSTRAINT colonies_pkey PRIMARY KEY (id);


--
-- Name: colony_distribution_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY colony_distribution_centres
    ADD CONSTRAINT colony_distribution_centres_pkey PRIMARY KEY (id);


--
-- Name: consortia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY consortia
    ADD CONSTRAINT consortia_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: deleter_strains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deleter_strains
    ADD CONSTRAINT deleter_strains_pkey PRIMARY KEY (id);


--
-- Name: deposited_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deposited_materials
    ADD CONSTRAINT deposited_materials_pkey PRIMARY KEY (id);


--
-- Name: email_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: es_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY es_cells
    ADD CONSTRAINT es_cells_pkey PRIMARY KEY (id);


--
-- Name: gene_private_annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gene_private_annotations
    ADD CONSTRAINT gene_private_annotations_pkey PRIMARY KEY (id);


--
-- Name: genes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY genes
    ADD CONSTRAINT genes_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report
    ADD CONSTRAINT intermediate_report_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_summary_by_centre_and_consortia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_centre_and_consortia
    ADD CONSTRAINT intermediate_report_summary_by_centre_and_consortia_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_summary_by_centre_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_centre
    ADD CONSTRAINT intermediate_report_summary_by_centre_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_summary_by_consortia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_consortia
    ADD CONSTRAINT intermediate_report_summary_by_consortia_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_summary_by_gene_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_gene
    ADD CONSTRAINT intermediate_report_summary_by_gene_pkey PRIMARY KEY (id);


--
-- Name: intermediate_report_summary_by_mi_plan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY intermediate_report_summary_by_mi_plan
    ADD CONSTRAINT intermediate_report_summary_by_mi_plan_pkey PRIMARY KEY (id);


--
-- Name: mi_attempt_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_status_stamps
    ADD CONSTRAINT mi_attempt_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: mi_attempt_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_statuses
    ADD CONSTRAINT mi_attempt_statuses_pkey PRIMARY KEY (id);


--
-- Name: mi_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_es_cell_qcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_cell_qcs
    ADD CONSTRAINT mi_plan_es_cell_qcs_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_es_qc_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_qc_comments
    ADD CONSTRAINT mi_plan_es_qc_comments_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_priorities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_priorities
    ADD CONSTRAINT mi_plan_priorities_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps
    ADD CONSTRAINT mi_plan_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_statuses
    ADD CONSTRAINT mi_plan_statuses_pkey PRIMARY KEY (id);


--
-- Name: mi_plan_sub_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_sub_projects
    ADD CONSTRAINT mi_plan_sub_projects_pkey PRIMARY KEY (id);


--
-- Name: mi_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_pkey PRIMARY KEY (id);


--
-- Name: mouse_allele_mod_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mod_status_stamps
    ADD CONSTRAINT mouse_allele_mod_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: mouse_allele_mod_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mod_statuses
    ADD CONSTRAINT mouse_allele_mod_statuses_pkey PRIMARY KEY (id);


--
-- Name: mouse_allele_mods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods
    ADD CONSTRAINT mouse_allele_mods_pkey PRIMARY KEY (id);


--
-- Name: mutagenesis_factor_vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mutagenesis_factor_donors
    ADD CONSTRAINT mutagenesis_factor_vectors_pkey PRIMARY KEY (id);


--
-- Name: mutagenesis_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mutagenesis_factors
    ADD CONSTRAINT mutagenesis_factors_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: phenotype_attempt_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotype_attempt_ids
    ADD CONSTRAINT phenotype_attempt_ids_pkey PRIMARY KEY (id);


--
-- Name: phenotyping_production_late_adult_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_late_adult_status_stamps
    ADD CONSTRAINT phenotyping_production_late_adult_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: phenotyping_production_late_adult_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_late_adult_statuses
    ADD CONSTRAINT phenotyping_production_late_adult_statuses_pkey PRIMARY KEY (id);


--
-- Name: phenotyping_production_status_stamps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_status_stamps
    ADD CONSTRAINT phenotyping_production_status_stamps_pkey PRIMARY KEY (id);


--
-- Name: phenotyping_production_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_statuses
    ADD CONSTRAINT phenotyping_production_statuses_pkey PRIMARY KEY (id);


--
-- Name: phenotyping_production_tissue_distribution_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_tissue_distribution_centres
    ADD CONSTRAINT phenotyping_production_tissue_distribution_centres_pkey PRIMARY KEY (id);


--
-- Name: phenotyping_productions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_productions
    ADD CONSTRAINT phenotyping_productions_pkey PRIMARY KEY (id);


--
-- Name: pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pipelines
    ADD CONSTRAINT pipelines_pkey PRIMARY KEY (id);


--
-- Name: production_centre_qcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY production_centre_qcs
    ADD CONSTRAINT production_centre_qcs_pkey PRIMARY KEY (id);


--
-- Name: production_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY production_goals
    ADD CONSTRAINT production_goals_pkey PRIMARY KEY (id);


--
-- Name: qc_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY qc_results
    ADD CONSTRAINT qc_results_pkey PRIMARY KEY (id);


--
-- Name: reagent_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reagent_names
    ADD CONSTRAINT reagent_names_pkey PRIMARY KEY (id);


--
-- Name: reagents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reagents
    ADD CONSTRAINT reagents_pkey PRIMARY KEY (id);


--
-- Name: report_caches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_caches
    ADD CONSTRAINT report_caches_pkey PRIMARY KEY (id);


--
-- Name: strains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY strains
    ADD CONSTRAINT strains_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_allele_sequence_annotations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_allele_sequence_annotations
    ADD CONSTRAINT targ_rep_allele_sequence_annotations_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_alleles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_alleles
    ADD CONSTRAINT targ_rep_alleles_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_centre_pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_centre_pipelines
    ADD CONSTRAINT targ_rep_centre_pipelines_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_crisprs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_crisprs
    ADD CONSTRAINT targ_rep_crisprs_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_distribution_qcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_distribution_qcs
    ADD CONSTRAINT targ_rep_distribution_qcs_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_es_cell_distribution_centres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cell_distribution_centres
    ADD CONSTRAINT targ_rep_es_cell_distribution_centres_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_es_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cells
    ADD CONSTRAINT targ_rep_es_cells_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_genbank_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genbank_files
    ADD CONSTRAINT targ_rep_genbank_files_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_genotype_primers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genotype_primers
    ADD CONSTRAINT targ_rep_genotype_primers_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_ikmc_project_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_ikmc_project_statuses
    ADD CONSTRAINT targ_rep_ikmc_project_statuses_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_ikmc_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_ikmc_projects
    ADD CONSTRAINT targ_rep_ikmc_projects_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_mutation_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_methods
    ADD CONSTRAINT targ_rep_mutation_methods_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_mutation_subtypes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_subtypes
    ADD CONSTRAINT targ_rep_mutation_subtypes_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_mutation_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_mutation_types
    ADD CONSTRAINT targ_rep_mutation_types_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_pipelines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_pipelines
    ADD CONSTRAINT targ_rep_pipelines_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_sequence_annotation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_sequence_annotation
    ADD CONSTRAINT targ_rep_sequence_annotation_pkey PRIMARY KEY (id);


--
-- Name: targ_rep_targeting_vectors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_targeting_vectors
    ADD CONSTRAINT targ_rep_targeting_vectors_pkey PRIMARY KEY (id);


--
-- Name: trace_call_vcf_modifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_call_vcf_modifications
    ADD CONSTRAINT trace_call_vcf_modifications_pkey PRIMARY KEY (id);


--
-- Name: trace_calls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_calls
    ADD CONSTRAINT trace_calls_pkey PRIMARY KEY (id);


--
-- Name: trace_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_files
    ADD CONSTRAINT trace_files_pkey PRIMARY KEY (id);


--
-- Name: tracking_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tracking_goals
    ADD CONSTRAINT tracking_goals_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: associated_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX associated_index ON audits USING btree (associated_id, associated_type);


--
-- Name: auditable_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX auditable_index ON audits USING btree (auditable_id, auditable_type);


--
-- Name: es_cells_allele_id_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX es_cells_allele_id_fk ON targ_rep_es_cells USING btree (allele_id);


--
-- Name: es_cells_pipeline_id_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX es_cells_pipeline_id_fk ON targ_rep_es_cells USING btree (pipeline_id);


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_created_at ON audits USING btree (created_at);


--
-- Name: index_centres_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_centres_on_name ON centres USING btree (name);


--
-- Name: index_consortia_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_consortia_on_name ON consortia USING btree (name);


--
-- Name: index_contacts_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contacts_on_email ON contacts USING btree (email);


--
-- Name: index_deposited_materials_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_deposited_materials_on_name ON deposited_materials USING btree (name);


--
-- Name: index_distribution_qcs_centre_es_cell; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_distribution_qcs_centre_es_cell ON targ_rep_distribution_qcs USING btree (es_cell_distribution_centre_id, es_cell_id);


--
-- Name: index_es_cells_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_es_cells_on_name ON es_cells USING btree (name);


--
-- Name: index_genes_on_marker_symbol; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_genes_on_marker_symbol ON genes USING btree (marker_symbol);


--
-- Name: index_genes_on_mgi_accession_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_genes_on_mgi_accession_id ON genes USING btree (mgi_accession_id);


--
-- Name: index_mi_attempt_statuses_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mi_attempt_statuses_on_name ON mi_attempt_statuses USING btree (name);


--
-- Name: index_mi_attempts_on_colony_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mi_attempts_on_colony_name ON mi_attempts USING btree (external_ref);


--
-- Name: index_mi_plan_es_qc_comments_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mi_plan_es_qc_comments_on_name ON mi_plan_es_qc_comments USING btree (name);


--
-- Name: index_mi_plan_priorities_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mi_plan_priorities_on_name ON mi_plan_priorities USING btree (name);


--
-- Name: index_mi_plan_statuses_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mi_plan_statuses_on_name ON mi_plan_statuses USING btree (name);


--
-- Name: index_one_status_stamp_per_status_and_mi_attempt; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_status_stamp_per_status_and_mi_attempt ON mi_attempt_status_stamps USING btree (status_id, mi_attempt_id);


--
-- Name: index_one_status_stamp_per_status_and_mi_plan; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_status_stamp_per_status_and_mi_plan ON mi_plan_status_stamps USING btree (status_id, mi_plan_id);


--
-- Name: index_pipelines_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pipelines_on_name ON pipelines USING btree (name);


--
-- Name: index_production_goals_on_consortium_id_and_year_and_month; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_production_goals_on_consortium_id_and_year_and_month ON production_goals USING btree (consortium_id, year, month);


--
-- Name: index_qc_results_on_description; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_qc_results_on_description ON qc_results USING btree (description);


--
-- Name: index_report_caches_on_name_and_format; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_report_caches_on_name_and_format ON report_caches USING btree (name, format);


--
-- Name: index_strains_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_strains_on_name ON strains USING btree (name);


--
-- Name: index_targ_rep_pipelines_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_targ_rep_pipelines_on_name ON targ_rep_pipelines USING btree (name);


--
-- Name: index_targvec; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_targvec ON targ_rep_targeting_vectors USING btree (name);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: irsc_allele_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_allele_type ON intermediate_report_summary_by_consortia USING btree (allele_type);


--
-- Name: irsc_approach; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_approach ON intermediate_report_summary_by_consortia USING btree (approach);


--
-- Name: irsc_catagory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_catagory ON intermediate_report_summary_by_consortia USING btree (catagory);


--
-- Name: irsc_mi_attempts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_mi_attempts ON intermediate_report_summary_by_consortia USING btree (mi_attempt_id);


--
-- Name: irsc_mi_plans; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_mi_plans ON intermediate_report_summary_by_consortia USING btree (mi_plan_id);


--
-- Name: irsc_mouse_allele_mods; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_mouse_allele_mods ON intermediate_report_summary_by_consortia USING btree (mouse_allele_mod_id);


--
-- Name: irsc_phenotyping_productions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsc_phenotyping_productions ON intermediate_report_summary_by_consortia USING btree (phenotyping_production_id);


--
-- Name: irscc_allele_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_allele_type ON intermediate_report_summary_by_centre_and_consortia USING btree (allele_type);


--
-- Name: irscc_approach; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_approach ON intermediate_report_summary_by_centre_and_consortia USING btree (approach);


--
-- Name: irscc_catagory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_catagory ON intermediate_report_summary_by_centre_and_consortia USING btree (catagory);


--
-- Name: irscc_mi_attempts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_mi_attempts ON intermediate_report_summary_by_centre_and_consortia USING btree (mi_attempt_id);


--
-- Name: irscc_mi_plans; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_mi_plans ON intermediate_report_summary_by_centre_and_consortia USING btree (mi_plan_id);


--
-- Name: irscc_mouse_allele_mods; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_mouse_allele_mods ON intermediate_report_summary_by_centre_and_consortia USING btree (mouse_allele_mod_id);


--
-- Name: irscc_phenotyping_productions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscc_phenotyping_productions ON intermediate_report_summary_by_centre_and_consortia USING btree (phenotyping_production_id);


--
-- Name: irscen_allele_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_allele_type ON intermediate_report_summary_by_centre USING btree (allele_type);


--
-- Name: irscen_approach; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_approach ON intermediate_report_summary_by_centre USING btree (approach);


--
-- Name: irscen_catagory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_catagory ON intermediate_report_summary_by_centre USING btree (catagory);


--
-- Name: irscen_gene_centre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_gene_centre ON intermediate_report_summary_by_centre USING btree (gene, production_centre);


--
-- Name: irscen_gene_centre_consortia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_gene_centre_consortia ON intermediate_report_summary_by_centre_and_consortia USING btree (gene, production_centre, consortium);


--
-- Name: irscen_gene_consortia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_gene_consortia ON intermediate_report_summary_by_consortia USING btree (gene, consortium);


--
-- Name: irscen_mi_attempts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_mi_attempts ON intermediate_report_summary_by_centre USING btree (mi_attempt_id);


--
-- Name: irscen_mi_plans; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_mi_plans ON intermediate_report_summary_by_centre USING btree (mi_plan_id);


--
-- Name: irscen_mouse_allele_mods; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_mouse_allele_mods ON intermediate_report_summary_by_centre USING btree (mouse_allele_mod_id);


--
-- Name: irscen_phenotyping_productions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irscen_phenotyping_productions ON intermediate_report_summary_by_centre USING btree (phenotyping_production_id);


--
-- Name: irsg_allele_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_allele_type ON intermediate_report_summary_by_gene USING btree (allele_type);


--
-- Name: irsg_approach; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_approach ON intermediate_report_summary_by_gene USING btree (approach);


--
-- Name: irsg_catagory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_catagory ON intermediate_report_summary_by_gene USING btree (catagory);


--
-- Name: irsg_gene; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_gene ON intermediate_report_summary_by_gene USING btree (gene);


--
-- Name: irsg_mi_attempts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_mi_attempts ON intermediate_report_summary_by_gene USING btree (mi_attempt_id);


--
-- Name: irsg_mi_plans; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_mi_plans ON intermediate_report_summary_by_gene USING btree (mi_plan_id);


--
-- Name: irsg_mouse_allele_mods; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_mouse_allele_mods ON intermediate_report_summary_by_gene USING btree (mouse_allele_mod_id);


--
-- Name: irsg_phenotyping_productions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsg_phenotyping_productions ON intermediate_report_summary_by_gene USING btree (phenotyping_production_id);


--
-- Name: irsmp_allele_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_allele_type ON intermediate_report_summary_by_mi_plan USING btree (allele_type);


--
-- Name: irsmp_approach; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_approach ON intermediate_report_summary_by_mi_plan USING btree (approach);


--
-- Name: irsmp_catagory; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_catagory ON intermediate_report_summary_by_mi_plan USING btree (catagory);


--
-- Name: irsmp_mi_attempts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_mi_attempts ON intermediate_report_summary_by_mi_plan USING btree (mi_attempt_id);


--
-- Name: irsmp_mi_plans; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_mi_plans ON intermediate_report_summary_by_mi_plan USING btree (mi_plan_id);


--
-- Name: irsmp_mouse_allele_mods; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_mouse_allele_mods ON intermediate_report_summary_by_mi_plan USING btree (mouse_allele_mod_id);


--
-- Name: irsmp_phenotyping_productions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX irsmp_phenotyping_productions ON intermediate_report_summary_by_mi_plan USING btree (phenotyping_production_id);


--
-- Name: mi_plan_logical_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mi_plan_logical_key ON mi_plans USING btree (gene_id, consortium_id, production_centre_id, sub_project_id, is_bespoke_allele, is_conditional_allele, is_deletion_allele, is_cre_knock_in_allele, is_cre_bac_allele, conditional_tm1c, phenotype_only, mutagenesis_via_crispr_cas9);


--
-- Name: mouse_allele_mod_colony_name_uniqueness_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX mouse_allele_mod_colony_name_uniqueness_index ON colonies USING btree (name, mi_attempt_id, mouse_allele_mod_id);


--
-- Name: targ_rep_index_es_cells_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX targ_rep_index_es_cells_on_name ON targ_rep_es_cells USING btree (name);


--
-- Name: targeting_vectors_allele_id_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX targeting_vectors_allele_id_fk ON targ_rep_targeting_vectors USING btree (allele_id);


--
-- Name: targeting_vectors_pipeline_id_fk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX targeting_vectors_pipeline_id_fk ON targ_rep_targeting_vectors USING btree (pipeline_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: user_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_index ON audits USING btree (user_id, user_type);


--
-- Name: colonies_mi_attempt_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY colonies
    ADD CONSTRAINT colonies_mi_attempt_fk FOREIGN KEY (mi_attempt_id) REFERENCES mi_attempts(id);


--
-- Name: colonies_mouse_allele_mod_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY colonies
    ADD CONSTRAINT colonies_mouse_allele_mod_fk FOREIGN KEY (mouse_allele_mod_id) REFERENCES mouse_allele_mods(id);


--
-- Name: fk_late_adult_pp_status_stamps_pp; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_late_adult_status_stamps
    ADD CONSTRAINT fk_late_adult_pp_status_stamps_pp FOREIGN KEY (phenotyping_production_id) REFERENCES phenotyping_productions(id);


--
-- Name: fk_late_adult_pp_status_stamps_status; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_late_adult_status_stamps
    ADD CONSTRAINT fk_late_adult_pp_status_stamps_status FOREIGN KEY (status_id) REFERENCES phenotyping_production_late_adult_statuses(id);


--
-- Name: fk_mouse_allele_mods; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mod_status_stamps
    ADD CONSTRAINT fk_mouse_allele_mods FOREIGN KEY (mouse_allele_mod_id) REFERENCES mouse_allele_mods(id);


--
-- Name: fk_phenotyinging_production_late_adult_status; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_productions
    ADD CONSTRAINT fk_phenotyinging_production_late_adult_status FOREIGN KEY (late_adult_status_id) REFERENCES phenotyping_production_late_adult_statuses(id);


--
-- Name: fk_phenotyping_productions; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_status_stamps
    ADD CONSTRAINT fk_phenotyping_productions FOREIGN KEY (phenotyping_production_id) REFERENCES phenotyping_productions(id);


--
-- Name: fk_tdc_centre; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_tissue_distribution_centres
    ADD CONSTRAINT fk_tdc_centre FOREIGN KEY (centre_id) REFERENCES centres(id);


--
-- Name: fk_tdc_phenotyinging_production; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_tissue_distribution_centres
    ADD CONSTRAINT fk_tdc_phenotyinging_production FOREIGN KEY (phenotyping_production_id) REFERENCES phenotyping_productions(id);


--
-- Name: mi_attempt_status_stamps_mi_attempt_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempt_status_stamps
    ADD CONSTRAINT mi_attempt_status_stamps_mi_attempt_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_attempt_statuses(id);


--
-- Name: mi_attempts_blast_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_blast_strain_id_fk FOREIGN KEY (blast_strain_id) REFERENCES strains(id);


--
-- Name: mi_attempts_mi_attempt_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_mi_attempt_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_attempt_statuses(id);


--
-- Name: mi_attempts_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mi_attempts_targ_rep_allele_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_targ_rep_allele_id_fk FOREIGN KEY (allele_id) REFERENCES targ_rep_alleles(id);


--
-- Name: mi_attempts_test_cross_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_test_cross_strain_id_fk FOREIGN KEY (test_cross_strain_id) REFERENCES strains(id);


--
-- Name: mi_attempts_updated_by_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_attempts
    ADD CONSTRAINT mi_attempts_updated_by_id_fk FOREIGN KEY (updated_by_id) REFERENCES users(id);


--
-- Name: mi_plan_es_cell_qcs_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_es_cell_qcs
    ADD CONSTRAINT mi_plan_es_cell_qcs_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mi_plan_status_stamps_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps
    ADD CONSTRAINT mi_plan_status_stamps_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mi_plan_status_stamps_mi_plan_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plan_status_stamps
    ADD CONSTRAINT mi_plan_status_stamps_mi_plan_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_plan_statuses(id);


--
-- Name: mi_plans_consortium_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_consortium_id_fk FOREIGN KEY (consortium_id) REFERENCES consortia(id);


--
-- Name: mi_plans_es_qc_comment_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_es_qc_comment_id_fk FOREIGN KEY (es_qc_comment_id) REFERENCES mi_plan_es_qc_comments(id);


--
-- Name: mi_plans_gene_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_gene_id_fk FOREIGN KEY (gene_id) REFERENCES genes(id);


--
-- Name: mi_plans_mi_plan_priority_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_mi_plan_priority_id_fk FOREIGN KEY (priority_id) REFERENCES mi_plan_priorities(id);


--
-- Name: mi_plans_mi_plan_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_mi_plan_status_id_fk FOREIGN KEY (status_id) REFERENCES mi_plan_statuses(id);


--
-- Name: mi_plans_production_centre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_production_centre_id_fk FOREIGN KEY (production_centre_id) REFERENCES centres(id);


--
-- Name: mi_plans_sub_project_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mi_plans
    ADD CONSTRAINT mi_plans_sub_project_id_fk FOREIGN KEY (sub_project_id) REFERENCES mi_plan_sub_projects(id);


--
-- Name: mouse_allele_mod_status_stamps_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mod_status_stamps
    ADD CONSTRAINT mouse_allele_mod_status_stamps_status_id_fk FOREIGN KEY (status_id) REFERENCES mouse_allele_mod_statuses(id);


--
-- Name: mouse_allele_mods_deleter_strain_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods
    ADD CONSTRAINT mouse_allele_mods_deleter_strain_id_fk FOREIGN KEY (deleter_strain_id) REFERENCES strains(id);


--
-- Name: mouse_allele_mods_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods
    ADD CONSTRAINT mouse_allele_mods_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: mouse_allele_mods_phenotype_attempt_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods
    ADD CONSTRAINT mouse_allele_mods_phenotype_attempt_id_fk FOREIGN KEY (phenotype_attempt_id) REFERENCES phenotype_attempt_ids(id);


--
-- Name: mouse_allele_mods_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods
    ADD CONSTRAINT mouse_allele_mods_status_id_fk FOREIGN KEY (status_id) REFERENCES mouse_allele_mod_statuses(id);


--
-- Name: mouse_allele_mods_targ_rep_allele_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mouse_allele_mods
    ADD CONSTRAINT mouse_allele_mods_targ_rep_allele_id_fk FOREIGN KEY (allele_id) REFERENCES targ_rep_alleles(id);


--
-- Name: notifications_contact_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_contact_id_fk FOREIGN KEY (contact_id) REFERENCES contacts(id);


--
-- Name: notifications_gene_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_gene_id_fk FOREIGN KEY (gene_id) REFERENCES genes(id);


--
-- Name: phenotyping_production_status_stamps_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_production_status_stamps
    ADD CONSTRAINT phenotyping_production_status_stamps_status_id_fk FOREIGN KEY (status_id) REFERENCES phenotyping_production_statuses(id);


--
-- Name: phenotyping_productions_mi_plan_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_productions
    ADD CONSTRAINT phenotyping_productions_mi_plan_id_fk FOREIGN KEY (mi_plan_id) REFERENCES mi_plans(id);


--
-- Name: phenotyping_productions_phenotype_attempt_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_productions
    ADD CONSTRAINT phenotyping_productions_phenotype_attempt_id_fk FOREIGN KEY (phenotype_attempt_id) REFERENCES phenotype_attempt_ids(id);


--
-- Name: phenotyping_productions_status_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY phenotyping_productions
    ADD CONSTRAINT phenotyping_productions_status_id_fk FOREIGN KEY (status_id) REFERENCES phenotyping_production_statuses(id);


--
-- Name: targ_rep_allele_sequence_annotations_allele_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_allele_sequence_annotations
    ADD CONSTRAINT targ_rep_allele_sequence_annotations_allele_id_fk FOREIGN KEY (allele_id) REFERENCES targ_rep_alleles(id);


--
-- Name: targ_rep_es_cells_user_qc_mouse_clinic_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_es_cells
    ADD CONSTRAINT targ_rep_es_cells_user_qc_mouse_clinic_id_fk FOREIGN KEY (user_qc_mouse_clinic_id) REFERENCES centres(id);


--
-- Name: targ_rep_genotype_primers_allele_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genotype_primers
    ADD CONSTRAINT targ_rep_genotype_primers_allele_id_fk FOREIGN KEY (allele_id) REFERENCES targ_rep_alleles(id);


--
-- Name: targ_rep_genotype_primers_mutagenesis_factor_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY targ_rep_genotype_primers
    ADD CONSTRAINT targ_rep_genotype_primers_mutagenesis_factor_id_fk FOREIGN KEY (mutagenesis_factor_id) REFERENCES mutagenesis_factors(id);


--
-- Name: trace_call_vcf_modifications_trace_calls_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_call_vcf_modifications
    ADD CONSTRAINT trace_call_vcf_modifications_trace_calls_fk FOREIGN KEY (trace_call_id) REFERENCES trace_calls(id);


--
-- Name: trace_calls_colonies_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY trace_calls
    ADD CONSTRAINT trace_calls_colonies_fk FOREIGN KEY (colony_id) REFERENCES colonies(id);


--
-- Name: users_es_cell_distribution_centre_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_es_cell_distribution_centre_id_fk FOREIGN KEY (es_cell_distribution_centre_id) REFERENCES targ_rep_es_cell_distribution_centres(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO schema_migrations (version) VALUES ('20110315000000');

INSERT INTO schema_migrations (version) VALUES ('20110419101838');

INSERT INTO schema_migrations (version) VALUES ('20110419105759');

INSERT INTO schema_migrations (version) VALUES ('20110419120000');

INSERT INTO schema_migrations (version) VALUES ('20110420010000');

INSERT INTO schema_migrations (version) VALUES ('20110421095045');

INSERT INTO schema_migrations (version) VALUES ('20110421140001');

INSERT INTO schema_migrations (version) VALUES ('20110421140011');

INSERT INTO schema_migrations (version) VALUES ('20110421150000');

INSERT INTO schema_migrations (version) VALUES ('20110527121721');

INSERT INTO schema_migrations (version) VALUES ('20110721091844');

INSERT INTO schema_migrations (version) VALUES ('20110725141713');

INSERT INTO schema_migrations (version) VALUES ('20110727110911');

INSERT INTO schema_migrations (version) VALUES ('20110802094958');

INSERT INTO schema_migrations (version) VALUES ('20110915000000');

INSERT INTO schema_migrations (version) VALUES ('20110921000001');

INSERT INTO schema_migrations (version) VALUES ('20110922103626');

INSERT INTO schema_migrations (version) VALUES ('20111014000000');

INSERT INTO schema_migrations (version) VALUES ('20111018103514');

INSERT INTO schema_migrations (version) VALUES ('20111026000000');

INSERT INTO schema_migrations (version) VALUES ('20111101000000');

INSERT INTO schema_migrations (version) VALUES ('20111101173922');

INSERT INTO schema_migrations (version) VALUES ('20111121113850');

INSERT INTO schema_migrations (version) VALUES ('20111123172943');

INSERT INTO schema_migrations (version) VALUES ('20111201183938');

INSERT INTO schema_migrations (version) VALUES ('20111202105057');

INSERT INTO schema_migrations (version) VALUES ('20111208000000');

INSERT INTO schema_migrations (version) VALUES ('20111209081222');

INSERT INTO schema_migrations (version) VALUES ('20111209084000');

INSERT INTO schema_migrations (version) VALUES ('20111215090406');

INSERT INTO schema_migrations (version) VALUES ('20111220165606');

INSERT INTO schema_migrations (version) VALUES ('20120109122259');

INSERT INTO schema_migrations (version) VALUES ('20120112154903');

INSERT INTO schema_migrations (version) VALUES ('20120206184229');

INSERT INTO schema_migrations (version) VALUES ('20120209111757');

INSERT INTO schema_migrations (version) VALUES ('20120214105538');

INSERT INTO schema_migrations (version) VALUES ('20120215164706');

INSERT INTO schema_migrations (version) VALUES ('20120301123306');

INSERT INTO schema_migrations (version) VALUES ('20120313170227');

INSERT INTO schema_migrations (version) VALUES ('20120313171943');

INSERT INTO schema_migrations (version) VALUES ('20120323153009');

INSERT INTO schema_migrations (version) VALUES ('20120323162146');

INSERT INTO schema_migrations (version) VALUES ('20120328110402');

INSERT INTO schema_migrations (version) VALUES ('20120411132445');

INSERT INTO schema_migrations (version) VALUES ('20120508123747');

INSERT INTO schema_migrations (version) VALUES ('20120515144152');

INSERT INTO schema_migrations (version) VALUES ('20120517151408');

INSERT INTO schema_migrations (version) VALUES ('20120522123605');

INSERT INTO schema_migrations (version) VALUES ('20120524110807');

INSERT INTO schema_migrations (version) VALUES ('20120524111009');

INSERT INTO schema_migrations (version) VALUES ('20120612153941');

INSERT INTO schema_migrations (version) VALUES ('20120613132955');

INSERT INTO schema_migrations (version) VALUES ('20120615105644');

INSERT INTO schema_migrations (version) VALUES ('20120615105954');

INSERT INTO schema_migrations (version) VALUES ('20120618150335');

INSERT INTO schema_migrations (version) VALUES ('20120627135453');

INSERT INTO schema_migrations (version) VALUES ('20120710161237');

INSERT INTO schema_migrations (version) VALUES ('20120716095705');

INSERT INTO schema_migrations (version) VALUES ('20120716095723');

INSERT INTO schema_migrations (version) VALUES ('20120720150932');

INSERT INTO schema_migrations (version) VALUES ('20120721093257');

INSERT INTO schema_migrations (version) VALUES ('20120723110726');

INSERT INTO schema_migrations (version) VALUES ('20120724163920');

INSERT INTO schema_migrations (version) VALUES ('20120725145204');

INSERT INTO schema_migrations (version) VALUES ('20120731091856');

INSERT INTO schema_migrations (version) VALUES ('20120807115108');

INSERT INTO schema_migrations (version) VALUES ('20120917153914');

INSERT INTO schema_migrations (version) VALUES ('20120924160841');

INSERT INTO schema_migrations (version) VALUES ('20120926124146');

INSERT INTO schema_migrations (version) VALUES ('20121017152352');

INSERT INTO schema_migrations (version) VALUES ('20121030082321');

INSERT INTO schema_migrations (version) VALUES ('20121030084149');

INSERT INTO schema_migrations (version) VALUES ('20121030084658');

INSERT INTO schema_migrations (version) VALUES ('20121030085127');

INSERT INTO schema_migrations (version) VALUES ('20121030085445');

INSERT INTO schema_migrations (version) VALUES ('20121030091506');

INSERT INTO schema_migrations (version) VALUES ('20121030112955');

INSERT INTO schema_migrations (version) VALUES ('20121030120806');

INSERT INTO schema_migrations (version) VALUES ('20121030120918');

INSERT INTO schema_migrations (version) VALUES ('20121030121338');

INSERT INTO schema_migrations (version) VALUES ('20121030122923');

INSERT INTO schema_migrations (version) VALUES ('20121031124856');

INSERT INTO schema_migrations (version) VALUES ('20121105082318');

INSERT INTO schema_migrations (version) VALUES ('20121105114415');

INSERT INTO schema_migrations (version) VALUES ('20121106130926');

INSERT INTO schema_migrations (version) VALUES ('20121106154008');

INSERT INTO schema_migrations (version) VALUES ('20121107080657');

INSERT INTO schema_migrations (version) VALUES ('20121109144055');

INSERT INTO schema_migrations (version) VALUES ('20121113112851');

INSERT INTO schema_migrations (version) VALUES ('20121123145151');

INSERT INTO schema_migrations (version) VALUES ('20121129000000');

INSERT INTO schema_migrations (version) VALUES ('20121203164954');

INSERT INTO schema_migrations (version) VALUES ('20130102155346');

INSERT INTO schema_migrations (version) VALUES ('20130103092321');

INSERT INTO schema_migrations (version) VALUES ('20130103113250');

INSERT INTO schema_migrations (version) VALUES ('20130107104030');

INSERT INTO schema_migrations (version) VALUES ('20130109114249');

INSERT INTO schema_migrations (version) VALUES ('20130110103728');

INSERT INTO schema_migrations (version) VALUES ('20130110140730');

INSERT INTO schema_migrations (version) VALUES ('20130118115026');

INSERT INTO schema_migrations (version) VALUES ('20130123092333');

INSERT INTO schema_migrations (version) VALUES ('20130123114424');

INSERT INTO schema_migrations (version) VALUES ('20130130121045');

INSERT INTO schema_migrations (version) VALUES ('20130205114839');

INSERT INTO schema_migrations (version) VALUES ('20130219102215');

INSERT INTO schema_migrations (version) VALUES ('20130307114011');

INSERT INTO schema_migrations (version) VALUES ('20130318163354');

INSERT INTO schema_migrations (version) VALUES ('20130322100056');

INSERT INTO schema_migrations (version) VALUES ('20130322154023');

INSERT INTO schema_migrations (version) VALUES ('20130326153718');

INSERT INTO schema_migrations (version) VALUES ('20130403100056');

INSERT INTO schema_migrations (version) VALUES ('20130417142254');

INSERT INTO schema_migrations (version) VALUES ('20130422152724');

INSERT INTO schema_migrations (version) VALUES ('20130423142230');

INSERT INTO schema_migrations (version) VALUES ('20130424100316');

INSERT INTO schema_migrations (version) VALUES ('20130502132202');

INSERT INTO schema_migrations (version) VALUES ('20130502150234');

INSERT INTO schema_migrations (version) VALUES ('20130510104125');

INSERT INTO schema_migrations (version) VALUES ('20130510111914');

INSERT INTO schema_migrations (version) VALUES ('20130510144848');

INSERT INTO schema_migrations (version) VALUES ('20130520101048');

INSERT INTO schema_migrations (version) VALUES ('20130521115232');

INSERT INTO schema_migrations (version) VALUES ('20130523144937');

INSERT INTO schema_migrations (version) VALUES ('20130523154950');

INSERT INTO schema_migrations (version) VALUES ('20130523161221');

INSERT INTO schema_migrations (version) VALUES ('20130524110125');

INSERT INTO schema_migrations (version) VALUES ('20130528083431');

INSERT INTO schema_migrations (version) VALUES ('20130528131803');

INSERT INTO schema_migrations (version) VALUES ('20130528142149');

INSERT INTO schema_migrations (version) VALUES ('20130610142149');

INSERT INTO schema_migrations (version) VALUES ('20130615170525');

INSERT INTO schema_migrations (version) VALUES ('20130625115302');

INSERT INTO schema_migrations (version) VALUES ('20130628145302');

INSERT INTO schema_migrations (version) VALUES ('20130708264213');

INSERT INTO schema_migrations (version) VALUES ('20130718140000');

INSERT INTO schema_migrations (version) VALUES ('20130725112052');

INSERT INTO schema_migrations (version) VALUES ('20130801140814');

INSERT INTO schema_migrations (version) VALUES ('20130805152114');

INSERT INTO schema_migrations (version) VALUES ('20130806153714');

INSERT INTO schema_migrations (version) VALUES ('20130827134214');

INSERT INTO schema_migrations (version) VALUES ('20130827163214');

INSERT INTO schema_migrations (version) VALUES ('20130918163214');

INSERT INTO schema_migrations (version) VALUES ('20131015114400');

INSERT INTO schema_migrations (version) VALUES ('20131016114401');

INSERT INTO schema_migrations (version) VALUES ('20131016134400');

INSERT INTO schema_migrations (version) VALUES ('20131118000000');

INSERT INTO schema_migrations (version) VALUES ('20131127132202');

INSERT INTO schema_migrations (version) VALUES ('20131203111237');

INSERT INTO schema_migrations (version) VALUES ('20131206144401');

INSERT INTO schema_migrations (version) VALUES ('20131209100237');

INSERT INTO schema_migrations (version) VALUES ('20131219140237');

INSERT INTO schema_migrations (version) VALUES ('20131219164213');

INSERT INTO schema_migrations (version) VALUES ('20140110150335');

INSERT INTO schema_migrations (version) VALUES ('20140113132202');

INSERT INTO schema_migrations (version) VALUES ('20140113150335');

INSERT INTO schema_migrations (version) VALUES ('20140123134728');

INSERT INTO schema_migrations (version) VALUES ('20140204145302');

INSERT INTO schema_migrations (version) VALUES ('20140207124917');

INSERT INTO schema_migrations (version) VALUES ('20140304165417');

INSERT INTO schema_migrations (version) VALUES ('20140317115302');

INSERT INTO schema_migrations (version) VALUES ('20140318095417');

INSERT INTO schema_migrations (version) VALUES ('20140320152942');

INSERT INTO schema_migrations (version) VALUES ('20140324135302');

INSERT INTO schema_migrations (version) VALUES ('20140324145302');

INSERT INTO schema_migrations (version) VALUES ('20140426101200');

INSERT INTO schema_migrations (version) VALUES ('20140431165000');

INSERT INTO schema_migrations (version) VALUES ('20140431165001');

INSERT INTO schema_migrations (version) VALUES ('20140502125417');

INSERT INTO schema_migrations (version) VALUES ('20140507103001');

INSERT INTO schema_migrations (version) VALUES ('20140604104000');

INSERT INTO schema_migrations (version) VALUES ('20140609121100');

INSERT INTO schema_migrations (version) VALUES ('20140617141100');

INSERT INTO schema_migrations (version) VALUES ('20140710144500');

INSERT INTO schema_migrations (version) VALUES ('20140715152200');

INSERT INTO schema_migrations (version) VALUES ('20140717000000');

INSERT INTO schema_migrations (version) VALUES ('20140717140000');

INSERT INTO schema_migrations (version) VALUES ('20140718140000');

INSERT INTO schema_migrations (version) VALUES ('20140729092848');

INSERT INTO schema_migrations (version) VALUES ('20140730103053');

INSERT INTO schema_migrations (version) VALUES ('20140731090000');

INSERT INTO schema_migrations (version) VALUES ('20140804112200');

INSERT INTO schema_migrations (version) VALUES ('20140805121100');

INSERT INTO schema_migrations (version) VALUES ('20140812142200');

INSERT INTO schema_migrations (version) VALUES ('20140815152200');

INSERT INTO schema_migrations (version) VALUES ('20140818161100');

INSERT INTO schema_migrations (version) VALUES ('20140901093510');

INSERT INTO schema_migrations (version) VALUES ('20140904123936');

INSERT INTO schema_migrations (version) VALUES ('20140908114401');

INSERT INTO schema_migrations (version) VALUES ('20141008115302');

INSERT INTO schema_migrations (version) VALUES ('20141022103936');

INSERT INTO schema_migrations (version) VALUES ('20141023111500');

INSERT INTO schema_migrations (version) VALUES ('20141028115302');

INSERT INTO schema_migrations (version) VALUES ('20141031141000');

INSERT INTO schema_migrations (version) VALUES ('20141103165100');

INSERT INTO schema_migrations (version) VALUES ('20141206144401');

INSERT INTO schema_migrations (version) VALUES ('20141218120401');

INSERT INTO schema_migrations (version) VALUES ('20150121134401');

INSERT INTO schema_migrations (version) VALUES ('20150123133119');

INSERT INTO schema_migrations (version) VALUES ('20150209095302');

INSERT INTO schema_migrations (version) VALUES ('20150303141000');

INSERT INTO schema_migrations (version) VALUES ('20150309141000');

INSERT INTO schema_migrations (version) VALUES ('20150309151000');

INSERT INTO schema_migrations (version) VALUES ('20150317151000');

INSERT INTO schema_migrations (version) VALUES ('20150529151000');

INSERT INTO schema_migrations (version) VALUES ('20150612115302');

INSERT INTO schema_migrations (version) VALUES ('20150707115302');

INSERT INTO schema_migrations (version) VALUES ('20150724125302');

INSERT INTO schema_migrations (version) VALUES ('20150728125302');

INSERT INTO schema_migrations (version) VALUES ('20150806125302');

INSERT INTO schema_migrations (version) VALUES ('20150812125302');

INSERT INTO schema_migrations (version) VALUES ('20151009125302');

INSERT INTO schema_migrations (version) VALUES ('20160308125302');

INSERT INTO schema_migrations (version) VALUES ('20160401112530');

INSERT INTO schema_migrations (version) VALUES ('20160602105302');

INSERT INTO schema_migrations (version) VALUES ('20160904105302');

INSERT INTO schema_migrations (version) VALUES ('20160905125302');

INSERT INTO schema_migrations (version) VALUES ('20161005125302');

INSERT INTO schema_migrations (version) VALUES ('20170528125302');

INSERT INTO schema_migrations (version) VALUES ('20170530125302');

INSERT INTO schema_migrations (version) VALUES ('20170630325302');

INSERT INTO schema_migrations (version) VALUES ('20170728325302');

INSERT INTO schema_migrations (version) VALUES ('20170808141602');

INSERT INTO schema_migrations (version) VALUES ('20170913141602');

INSERT INTO schema_migrations (version) VALUES ('20170927101602');

INSERT INTO schema_migrations (version) VALUES ('20171024111602');