-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

-- FUNCTION NAME:
--
-- PARAMETERS:
--
-- CORRESPONDING RUBY:
--
-- TEST:
--
-- DESCRIPTION:

create table solr_centre_map(
    centre_name varchar(40), pref varchar(255), def varchar(255)
);

-- TODO make switchable : 'http://localhost:3000/targ_rep/alleles/'
-- TODO load this from yaml file

insert into solr_centre_map(centre_name, pref, def) values ('Harwell', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('HMGU', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('ICS', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('CNB', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('Monterotondo', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('JAX', 'http://jaxmice.jax.org/list/komp_strains', 'http://jaxmice.jax.org/list/komp_strains');
insert into solr_centre_map(centre_name, pref, def) values ('Oulu', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('VETMEDUNI', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('BCM', 'mailto:jcrowe@bcm.tmc.edu?subject=Mutant mouse for MARKER_SYMBOL', '');
insert into solr_centre_map(centre_name, pref, def) values ('CNRS', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('APN', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('TCP', 'mailto:lauryl.nutter@phenogenomics.ca?subject=Mutant mouse for MARKER_SYMBOL', 'mailto:lauryl.nutter@phenogenomics.ca?subject=Mutant mouse enquiry');
insert into solr_centre_map(centre_name, pref, def) values ('MARC', '', '');
insert into solr_centre_map(centre_name, pref, def) values ('UCD', 'http://www.komp.org/geneinfo.php?project=PROJECT_ID', 'http://www.komp.org/');
insert into solr_centre_map(centre_name, pref, def) values ('WTSI', 'mailto:mouseinterest@sanger.ac.uk?subject=Mutant mouse for MARKER_SYMBOL', '');
insert into solr_centre_map(centre_name, pref, def) values ('EMMA', 'http://www.emmanet.org/mutant_types.php?keyword=MARKER_SYMBOL', '');
insert into solr_centre_map(centre_name, pref, def) values ('MMRRC', 'http://www.mmrrc.org/catalog/StrainCatalogSearchForm.php?search_query=MARKER_SYMBOL', '');
insert into solr_centre_map(centre_name, pref, def) values ('KOMP', 'http://www.komp.org/geneinfo.php?project=PROJECT_ID', 'http://www.komp.org/');

CREATE OR REPLACE FUNCTION solr_get_mi_allele_name (in int)
  RETURNS text AS $$
  DECLARE
    tmp RECORD; result text; e boolean; marker_symbol text; allele_symbol_superscript_plan text; allele_symbol_superscript_template text;mouse_allele_type text;
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

  result := marker_symbol || '<sup>' || result1 || '</sup>';
  RETURN result;

  END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION solr_get_mi_order_from_names (in int)
  RETURNS text AS $$
  DECLARE
  tmp RECORD; result text; in_config boolean;
  BEGIN
  result := '';
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
      result := result || tmp.distribution_network || ';';
    else
      result := result || tmp.name || ';';
    end if;

  END LOOP;
  RETURN result;
  END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION solr_get_mi_order_from_urls (in int)
  RETURNS text AS $$
  DECLARE
  tmp RECORD; tmp2 RECORD; result text; marker_symbol text; project_id text; tmp_result text; target_name text; in_config boolean;
  BEGIN
  result := '';

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
          result := result || tmp_result || ';';
        end if;
      END LOOP;
  END LOOP;
  RETURN result;
  END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_best_status_pa(int, boolean)
RETURNS text AS $$
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
$$ LANGUAGE plpgsql;


CREATE
VIEW
solr_mi_attempts as
  select mi_attempts.id,

  CAST( 'Mouse' AS text ) as product_type,
  CAST( 'mi_attempt' AS text ) as type,

  colony_name as colony_name,
  (select marker_symbol from genes, mi_plans where mi_plans.id = mi_attempts.mi_plan_id and mi_plans.gene_id = genes.id) as marker_symbol,
  (select name from targ_rep_es_cells where targ_rep_es_cells.id = mi_attempts.es_cell_id) as es_cell_name,
  (select allele_id from targ_rep_es_cells where targ_rep_es_cells.id = mi_attempts.es_cell_id) as allele_id,
  (select mgi_accession_id from genes, mi_plans where mi_plans.id = mi_attempts.mi_plan_id and mi_plans.gene_id = genes.id) as mgi_accession_id,
  (select centres.name from centres, mi_plans where mi_plans.id = mi_attempts.mi_plan_id and mi_plans.production_centre_id = centres.id) as production_centre,
  (select strains.name from strains where strains.id = mi_attempts.colony_background_strain_id) as strain,
  'http://localhost:3000/targ_rep/alleles/' || (select allele_id from targ_rep_es_cells where targ_rep_es_cells.id = mi_attempts.es_cell_id) || '/escell-clone-genbank-file' as genbank_file_url,
  'http://localhost:3000/targ_rep/alleles/' || (select allele_id from targ_rep_es_cells where targ_rep_es_cells.id = mi_attempts.es_cell_id) || '/allele-image' as allele_image_url,
  'http://localhost:3000/targ_rep/alleles/' || (select allele_id from targ_rep_es_cells where targ_rep_es_cells.id = mi_attempts.es_cell_id) || '/allele-image?simple=true' as simple_allele_image_url,
  (select targ_rep_mutation_types.name from targ_rep_es_cells, targ_rep_alleles, targ_rep_mutation_types where targ_rep_es_cells.id = mi_attempts.es_cell_id and
  targ_rep_es_cells.allele_id = targ_rep_alleles.id and targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id) as allele_type,
  (select ikmc_project_id from targ_rep_es_cells where targ_rep_es_cells.id = mi_attempts.es_cell_id) as project_ids,

  CAST( '' AS text ) as current_pa_status,

  solr_get_mi_allele_name(mi_attempts.id) as allele_name,
  solr_get_mi_order_from_names(mi_attempts.id) as order_from_names,
  solr_get_mi_order_from_urls(mi_attempts.id) as order_from_urls,
  get_best_status_pa(mi_attempts.id, false) as best_status_pa_cre_ex_not_required,
  get_best_status_pa(mi_attempts.id, true) as best_status_pa_cre_ex_required

  from mi_attempts, mi_attempt_statuses
  where report_to_public is true and status_id = mi_attempt_statuses.id and mi_attempt_statuses.name = 'Genotype confirmed';
