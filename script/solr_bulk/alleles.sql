-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;

-- FUNCTION NAME: solr_get_allele_order_from_urls
--
-- PARAMETERS: targ_rep_es_cells.id
--
-- CORRESPONDING RUBY:
--
-- TEST:
--
-- DESCRIPTION:

CREATE OR REPLACE FUNCTION solr_get_allele_order_from_urls (int)
RETURNS text AS $$
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
          --result := result || 'http://www.eummcr.org/order.php' || ';';
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
$$ LANGUAGE plpgsql;

-- FUNCTION NAME:
--
-- PARAMETERS:
--
-- CORRESPONDING RUBY:
--
-- TEST:
--
-- DESCRIPTION:

CREATE OR REPLACE FUNCTION solr_get_allele_order_from_names (int)
RETURNS text AS $$
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
$$ LANGUAGE plpgsql;

-- VIEW NAME:
--
-- TEST:
--
-- DESCRIPTION:

CREATE
TABLE
solr_alleles as
  with relevant_es_cells as (
  select distinct targ_rep_es_cells.allele_id, targ_rep_es_cells.strain,
    targ_rep_es_cells.ikmc_project_id, targ_rep_es_cells.report_to_public, targ_rep_es_cells.mgi_allele_symbol_superscript,
    solr_get_allele_order_from_urls(targ_rep_es_cells.id) as order_from_urls,
    solr_get_allele_order_from_names(targ_rep_es_cells.id) as order_from_names
  from targ_rep_es_cells, targ_rep_pipelines
  where targ_rep_es_cells.report_to_public is true and targ_rep_es_cells.pipeline_id = targ_rep_pipelines.id
  and targ_rep_pipelines.report_to_public is true
  )
  select
  CAST( 'allele' AS text ) as type,
  targ_rep_alleles.id as id,
  CAST( 'ES Cell' AS text ) as product_type,
  targ_rep_alleles.id as allele_id,
  relevant_es_cells.order_from_names as order_from_names,
  relevant_es_cells.order_from_urls as order_from_urls,
  (select mgi_accession_id from genes where targ_rep_alleles.gene_id = genes.id) as mgi_accession_id,
  'http://localhost:3000/targ_rep/alleles/'|| targ_rep_alleles.id ||'/allele-image?simple=true' as simple_allele_image_url,
  (select marker_symbol from genes where targ_rep_alleles.gene_id = genes.id) as marker_symbol,
  'http://localhost:3000/targ_rep/alleles/'||targ_rep_alleles.id ||'/allele-image' as allele_image_url,
  'http://localhost:3000/targ_rep/alleles/'||targ_rep_alleles.id ||'/escell-clone-genbank-file' as genbank_file_url,
  (select targ_rep_mutation_types.name from targ_rep_mutation_types where targ_rep_alleles.mutation_type_id = id) as allele_type,
  relevant_es_cells.strain as strain,
  (select marker_symbol from genes where targ_rep_alleles.gene_id = genes.id)||'<sup>'||relevant_es_cells.mgi_allele_symbol_superscript||'</sup>' as allele_name,
  relevant_es_cells.ikmc_project_id as project_ids
  from targ_rep_alleles, relevant_es_cells
  where type = 'TargRep::TargetedAllele'
  and relevant_es_cells.allele_id = targ_rep_alleles.id;

CREATE INDEX solr_alleles_idx ON solr_alleles (id);
