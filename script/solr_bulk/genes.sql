-- http://www.postgresql.org/message-id/14658.1175879477@sss.pgh.pa.us
SET client_min_messages=WARNING;



CREATE OR REPLACE FUNCTION solr_mi_plan_status_stamp(in int)
RETURNS int AS $$
DECLARE
result int;
BEGIN
  select mi_plan_status_stamps.id into result from mi_plans, mi_plan_status_stamps where mi_plan_id = $1 and
  mi_plans.id = $1 and mi_plan_status_stamps.status_id = mi_plans.status_id;
  RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION solr_latest_relevant_mi_attempt (in int)
RETURNS int AS $$
DECLARE
    tmp RECORD; result int;
BEGIN
    select solr_in_progress_type_mi_attempt_id(p) into result
    from solr_mi_attempts_in_progress_date
    where solr_in_progress_type_mi_plan_id(p) = $1
    order by solr_mi_attempts_in_progress_date using > limit 1;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION solr_latest_relevant_phenotype_attempt (in int)
RETURNS int AS $$
DECLARE
    tmp RECORD; result int;
BEGIN
    select solr_pa_in_progress_type_phenotype_attempt_id(p) into result
    from solr_pa_in_progress_date
    where solr_pa_in_progress_type_mi_plan_id(p) = $1
    order by solr_pa_in_progress_date using > limit 1;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION solr_mi_plans_relevant_status_stamp (in int)
RETURNS table(order_by int, ddate timestamp, status text, stamp_type text, stamp_id int, mi_plan_id int, mi_attempt_id int, phenotype_attempt_id int) AS $$
DECLARE
result int; mi_plan_status_stamp_id int; mi_attribute_status_stamp_id int; phenotype_attribute_status_stamp_id int; mi_attribute_id int; phenotype_attribute_id int;
BEGIN

select solr_latest_relevant_phenotype_attempt($1) into phenotype_attribute_id;

if phenotype_attribute_id > 0 then

  select phenotype_attempt_status_stamps.id into phenotype_attribute_status_stamp_id from
  phenotype_attempts, phenotype_attempt_status_stamps
  where phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attribute_id and phenotype_attempt_status_stamps.status_id = phenotype_attempts.status_id and phenotype_attempts.id = phenotype_attribute_id;

  return query select
    phenotype_attempt_statuses.order_by as order_by,
  CAST( phenotype_attempt_status_stamps.created_at AS timestamp ) as ddate,
    CAST( 'status' AS text ) as status,
    CAST( 'PhenotypeAttempt::StatusStamp' AS text ) as stamp_type,
    phenotype_attempt_status_stamps.id as stamp_id,
    CAST( $1 AS int ) as mi_plan_id,
    CAST( mi_attribute_id AS int ) as mi_attempt_id,
    phenotype_attempt_status_stamps.phenotype_attempt_id as phenotype_attempt_id
  from phenotype_attempt_status_stamps, phenotype_attempt_statuses
  where phenotype_attempt_status_stamps.id = phenotype_attribute_status_stamp_id
  and phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attribute_id
  and phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id;

else

select solr_latest_relevant_mi_attempt($1) into mi_attribute_id;

if mi_attribute_id > 0 then

  select mi_attempt_status_stamps.id into mi_attribute_status_stamp_id from
  mi_attempts, mi_attempt_status_stamps
  where mi_attempt_status_stamps.mi_attempt_id = mi_attribute_id and mi_attempt_status_stamps.status_id = mi_attempts.status_id and mi_attempts.id = mi_attribute_id;

  return query select
    mi_attempt_statuses.order_by as order_by,
    CAST( mi_attempt_status_stamps.created_at AS timestamp ) as ddate,
    CAST( mi_attempt_statuses.name AS text ) as status,
    CAST( 'MiAttempt::StatusStamp' AS text ) as stamp_type,
    mi_attempt_status_stamps.id as stamp_id,
    CAST( $1 AS int ) as mi_plan_id,
    CAST( mi_attempt_status_stamps.mi_attempt_id AS int ) as mi_attempt_id,
    CAST( null AS int ) as phenotype_attempt_id
  from mi_attempt_status_stamps, mi_attempt_statuses
  where mi_attempt_status_stamps.id = mi_attribute_status_stamp_id
  and mi_attempt_statuses.id = mi_attempt_status_stamps.status_id
  and mi_attempt_status_stamps.mi_attempt_id = mi_attribute_id;

else

select solr_mi_plan_status_stamp($1) into mi_plan_status_stamp_id;

  return query select
    mi_plan_statuses.order_by as order_by,
    CAST( mi_plan_status_stamps.created_at AS timestamp ) as ddate,
    CAST( mi_plan_statuses.name AS text ) as status,
    CAST( 'MiPlan::StatusStamp' AS text ) as stamp_type,
    mi_plan_status_stamps.id as stamp_id,
    CAST( $1 AS int ) as mi_plan_id,
    CAST( null AS int ) as mi_attempt_id,
    CAST( null AS int ) as phenotype_attempt_id
  from mi_plan_status_stamps, mi_plan_statuses
  where mi_plan_status_stamps.id = mi_plan_status_stamp_id
  and mi_plan_statuses.id = mi_plan_status_stamps.status_id;

end if;
end if;

END;
$$ LANGUAGE plpgsql;





CREATE OR REPLACE FUNCTION solr_genes_relevant_plan (in int)
RETURNS int AS $$
DECLARE
tmp RECORD; tmp2 RECORD; current_id int; current_order_by int; current_ddate timestamp; current_stamp_id int; current_mi_plan_id int;
BEGIN
    current_id := null;

    FOR tmp IN select * from mi_plans where mi_plans.gene_id = $1 order by id
    LOOP
        FOR tmp2 IN select * from solr_mi_plans_relevant_status_stamp(tmp.id) limit 1
        LOOP

            if current_id is null then
                current_id := tmp.id;
                current_order_by := tmp2.order_by;
                current_ddate := tmp2.ddate;
                current_stamp_id := tmp2.stamp_id;
                current_mi_plan_id := tmp2.mi_plan_id;
            else
                if (tmp2.order_by > current_order_by) or (tmp2.order_by = current_order_by and tmp2.ddate < current_ddate) then
                    current_id := tmp.id;
                    current_order_by := tmp2.order_by;
                    current_ddate := tmp2.ddate;
                    current_stamp_id := tmp2.stamp_id;
                    current_mi_plan_id := tmp2.mi_plan_id;
                end if;
            end if;

        END LOOP;
    END LOOP;

    RETURN current_id;
END;
$$ LANGUAGE plpgsql;


CREATE TYPE solr_pa_in_progress_type AS (phenotype_attempt_id int, mi_plan_id int, order_by int, in_progress_date date);

CREATE or replace FUNCTION solr_pa_in_progress_type_cmp(t1 solr_pa_in_progress_type, t2 solr_pa_in_progress_type) RETURNS int
AS $$
BEGIN
    if t1.order_by > t2.order_by then
        return 1;
    end if;

    if t1.order_by < t2.order_by then
        return -1;
    end if;

    if t2.in_progress_date::date > t1.in_progress_date::date then
        return 1;
    end if;

    if t2.in_progress_date::date < t1.in_progress_date::date then
        return -1;
    end if;

    if t1.phenotype_attempt_id < t2.phenotype_attempt_id then
        return -1;
    end if;

    if t1.phenotype_attempt_id > t2.phenotype_attempt_id then
        return 1;
    end if;

    return 0;
END $$ LANGUAGE plpgsql;

CREATE OPERATOR FAMILY solr_pa_in_progress_type_operator_family USING btree;

CREATE OPERATOR CLASS solr_pa_in_progress_type_ops DEFAULT FOR TYPE solr_pa_in_progress_type USING btree FAMILY solr_pa_in_progress_type_operator_family AS
        FUNCTION 1 solr_pa_in_progress_type_cmp(solr_pa_in_progress_type, solr_pa_in_progress_type) ;

create table solr_pa_in_progress_date (p solr_pa_in_progress_type) ;

CREATE OR REPLACE FUNCTION solr_phenotype_attempt_in_progress_date (in int)
RETURNS date AS $$
DECLARE
    tmp RECORD; result date;
BEGIN
    FOR tmp IN SELECT min(created_at) as created_at from phenotype_attempt_status_stamps where phenotype_attempt_id = $1 and status_id = 2
    LOOP
        return tmp.created_at;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

insert into solr_pa_in_progress_date
SELECT
    row(phenotype_attempts.id,
    phenotype_attempts.mi_plan_id,
    phenotype_attempt_statuses.order_by,
    solr_phenotype_attempt_in_progress_date(phenotype_attempts.id))::solr_pa_in_progress_type
from phenotype_attempts, phenotype_attempt_statuses
where phenotype_attempt_statuses.id = phenotype_attempts.status_id;

CREATE or replace FUNCTION solr_pa_in_progress_type_phenotype_attempt_id(t solr_pa_in_progress_type) RETURNS int
AS $$
BEGIN
    return t.phenotype_attempt_id;
END $$ LANGUAGE plpgsql;

CREATE or replace FUNCTION solr_pa_in_progress_type_mi_plan_id(t solr_pa_in_progress_type) RETURNS int
AS $$
BEGIN
    return t.mi_plan_id;
END $$ LANGUAGE plpgsql;

CREATE or replace FUNCTION solr_pa_in_progress_type_order_by(t solr_pa_in_progress_type) RETURNS int
AS $$
BEGIN
    return t.order_by;
END $$ LANGUAGE plpgsql;

CREATE or replace FUNCTION solr_pa_in_progress_type_in_progress_date(t solr_pa_in_progress_type) RETURNS date
AS $$
BEGIN
    return t.in_progress_date;
END $$ LANGUAGE plpgsql;



-- see http://stackoverflow.com/questions/7205878/order-by-using-clause-in-postgresql

CREATE TYPE solr_in_progress_type AS (mi_attempt_id int, mi_plan_id int, order_by int, in_progress_date date);

CREATE or replace FUNCTION solr_in_progress_type_cmp(t1 solr_in_progress_type, t2 solr_in_progress_type) RETURNS int
AS $$
BEGIN

    if t1.order_by > t2.order_by then
        return 1;
    end if;

    if t1.order_by < t2.order_by then
        return -1;
    end if;

    if t2.in_progress_date::date > t1.in_progress_date::date then
        return 1;
    end if;

    if t2.in_progress_date::date < t1.in_progress_date::date then
        return -1;
    end if;

    if t1.mi_attempt_id < t2.mi_attempt_id then
        return -1;
    end if;

    if t1.mi_attempt_id > t2.mi_attempt_id then
        return 1;
    end if;

    RAISE notice 'solr_in_progress_type_cmp compare return 0';
    return 0;
END $$ LANGUAGE plpgsql;








CREATE OPERATOR FAMILY solr_in_progress_type_operator_family USING btree;

CREATE OPERATOR CLASS solr_in_progress_type_ops DEFAULT FOR TYPE solr_in_progress_type USING btree FAMILY solr_in_progress_type_operator_family AS
        FUNCTION 1 solr_in_progress_type_cmp(solr_in_progress_type, solr_in_progress_type) ;

-- see http://www.postgresql.org/docs/9.1/interactive/xindex.html






create table solr_mi_attempts_in_progress_date (p solr_in_progress_type) ;





insert into solr_mi_attempts_in_progress_date
SELECT
    row(mi_attempts.id,
    mi_attempts.mi_plan_id,
    mi_attempt_statuses.order_by,
    solr_mi_attempt_in_progress_date(mi_attempts.id))::solr_in_progress_type
from mi_attempts, mi_attempt_statuses
where mi_attempt_statuses.id = mi_attempts.status_id;






CREATE or replace FUNCTION solr_in_progress_type_mi_attempt_id(t solr_in_progress_type) RETURNS int
AS $$
BEGIN
    return t.mi_attempt_id;
END $$ LANGUAGE plpgsql;

CREATE or replace FUNCTION solr_in_progress_type_mi_plan_id(t solr_in_progress_type) RETURNS int
AS $$
BEGIN
    return t.mi_plan_id;
END $$ LANGUAGE plpgsql;









CREATE OR REPLACE FUNCTION solr_mi_attempt_in_progress_date (in int)
RETURNS date AS $$
DECLARE
    tmp RECORD; result date;
BEGIN
    FOR tmp IN SELECT min(created_at) as created_at from mi_attempt_status_stamps where mi_attempt_id = $1 and status_id = 1
    LOOP
        return tmp.created_at;
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;






create table solr_mi_plans_relevant_status_stamp_table
(
    gene_id int,
    order_by int,
    ddate timestamp,
    status text,
    stamp_type text,
    stamp_id int,
    mi_plan_id int PRIMARY KEY,
    mi_attempt_id int,
    phenotype_attempt_id int
);


CREATE OR REPLACE FUNCTION solr_mi_plans_relevant_status_stamp_builder()
RETURNS int AS $$
DECLARE
  tmp RECORD;
  result int;
  mi_plan_status_stamp_id int;
  mi_attempt_id_var int;
  phenotype_attempt_id_var int;
BEGIN
  truncate solr_mi_plans_relevant_status_stamp_table;

  FOR tmp IN select mi_plans.id, mi_plans.gene_id from mi_plans
  LOOP

    select mi_attempt_id into mi_attempt_id_var from solr_latest_relevant_mi_attempt_table where mi_plan_id = tmp.id;

    select solr_pa_in_progress_type_phenotype_attempt_id(p) into phenotype_attempt_id_var
       from solr_pa_in_progress_date
       where solr_pa_in_progress_type_mi_plan_id(p) = tmp.id
       order by solr_pa_in_progress_date using > limit 1;

    if phenotype_attempt_id_var > 0 then

      insert into solr_mi_plans_relevant_status_stamp_table
      select
        tmp.gene_id as gene_id,
        phenotype_attempt_statuses.order_by as order_by,
        CAST( phenotype_attempt_status_stamps.created_at AS timestamp ) as ddate,
        CAST( phenotype_attempt_statuses.name AS text ) as status,
        CAST( 'PhenotypeAttempt::StatusStamp' AS text ) as stamp_type,
        phenotype_attempt_status_stamps.id as stamp_id,
        CAST( tmp.id AS int ) as mi_plan_id,
        CAST( mi_attempt_id_var AS int ) as mi_attempt_id,
        phenotype_attempt_status_stamps.phenotype_attempt_id as phenotype_attempt_id
      from phenotype_attempt_status_stamps, phenotype_attempt_statuses, phenotype_attempts
      where phenotype_attempt_status_stamps.status_id = phenotype_attempts.status_id
      and phenotype_attempt_status_stamps.phenotype_attempt_id = phenotype_attempt_id_var
      and phenotype_attempt_statuses.id = phenotype_attempt_status_stamps.status_id
      and phenotype_attempts.id = phenotype_attempt_id_var;

    elsif mi_attempt_id_var > 0 then

      insert into solr_mi_plans_relevant_status_stamp_table
        select
        tmp.gene_id as gene_id,
        mi_attempt_statuses.order_by as order_by,
        CAST( mi_attempt_status_stamps.created_at AS timestamp ) as ddate,
        CAST( mi_attempt_statuses.name AS text ) as status,
        CAST( 'MiAttempt::StatusStamp' AS text ) as stamp_type,
        mi_attempt_status_stamps.id as stamp_id,
        CAST( tmp.id AS int ) as mi_plan_id,
        CAST( mi_attempt_status_stamps.mi_attempt_id AS int ) as mi_attempt_id,
        CAST( null AS int ) as phenotype_attempt_id
      from mi_attempt_status_stamps, mi_attempt_statuses, mi_attempts
      where mi_attempt_status_stamps.status_id = mi_attempts.status_id
      and mi_attempt_statuses.id = mi_attempt_status_stamps.status_id
      and mi_attempt_status_stamps.mi_attempt_id = mi_attempt_id_var
      and mi_attempts.id = mi_attempt_id_var;

    else

      select mi_plan_status_stamps.id into mi_plan_status_stamp_id from mi_plans, mi_plan_status_stamps where mi_plan_id = tmp.id and
        mi_plans.id = tmp.id and mi_plan_status_stamps.status_id = mi_plans.status_id;

      insert into solr_mi_plans_relevant_status_stamp_table
      select
        tmp.gene_id as gene_id,
         mi_plan_statuses.order_by as order_by,
         CAST( mi_plan_status_stamps.created_at AS timestamp ) as ddate,
         CAST( mi_plan_statuses.name AS text ) as status,
         CAST( 'MiPlan::StatusStamp' AS text ) as stamp_type,
         mi_plan_status_stamps.id as stamp_id,
         CAST( tmp.id AS int ) as mi_plan_id,
         CAST( null AS int ) as mi_attempt_id,
         CAST( null AS int ) as phenotype_attempt_id
       from mi_plan_status_stamps, mi_plan_statuses
       where mi_plan_status_stamps.id = mi_plan_status_stamp_id
       and mi_plan_statuses.id = mi_plan_status_stamps.status_id;

    end if;

  end LOOP;

  select count(*) into result from solr_mi_plans_relevant_status_stamp_table;
  return result;
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
-- EQUIVALENCE TEST:
--
-- DESCRIPTION:

drop table if exists solr_genes_relevant_plan_table;

create table solr_genes_relevant_plan_table
(
    gene_id int primary key,
    mi_plan_id int
);


CREATE OR REPLACE FUNCTION solr_genes_relevant_plan_builder()
RETURNS int AS $$
DECLARE
tmp RECORD; result int;
BEGIN
    truncate solr_genes_relevant_plan_table;

    insert into solr_genes_relevant_plan_table
    select genes.id as gene_id, solr_genes_relevant_plan(genes.id) as mi_plan_id
    from genes;

    select count(*) into result from solr_genes_relevant_plan_table;
    RETURN result;
END;
$$ LANGUAGE plpgsql;


create table solr_gene_statuses as
select
    genes.id as gene_id,
    consortia.name as consortium,
    centres.name as production_centre_name,
    solr_mi_plans_relevant_status_stamp_table.status as status_name,
    solr_mi_plans_relevant_status_stamp_table.ddate as created_at
from genes
join mi_plans on genes.id = mi_plans.gene_id
left join consortia on consortia.id = mi_plans.consortium_id
left join centres on centres.id = mi_plans.production_centre_id
join solr_genes_relevant_plan_table on solr_genes_relevant_plan_table.gene_id = genes.id and mi_plans.id = solr_genes_relevant_plan_table.mi_plan_id
join solr_mi_plans_relevant_status_stamp_table on solr_mi_plans_relevant_status_stamp_table.mi_plan_id = mi_plans.id and solr_mi_plans_relevant_status_stamp_table.gene_id = genes.id
;



CREATE INDEX solr_gene_statuses_idx ON solr_gene_statuses (gene_id);





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



create table solr_latest_relevant_mi_attempt_table
(
    mi_attempt_id int, mi_plan_id int
);

CREATE OR REPLACE FUNCTION solr_latest_relevant_mi_attempt_builder()
RETURNS int AS $$
DECLARE
    tmp RECORD; result int;
BEGIN
  truncate solr_latest_relevant_mi_attempt_table;

  FOR tmp IN select mi_attempts.mi_plan_id as mi_plan_id from mi_attempts
  LOOP
    insert into solr_latest_relevant_mi_attempt_table
    select solr_in_progress_type_mi_attempt_id(p) as mi_attempt_id, tmp.mi_plan_id as mi_plan_id
    from solr_mi_attempts_in_progress_date
    where solr_in_progress_type_mi_plan_id(p) = tmp.mi_plan_id
    order by solr_mi_attempts_in_progress_date using > limit 1;
  end loop;

  select count(*) into result from solr_latest_relevant_mi_attempt_table;
  return result;
END;
$$ LANGUAGE plpgsql;




select * from solr_latest_relevant_mi_attempt_builder();

select * from solr_mi_plans_relevant_status_stamp_builder();

select * from solr_genes_relevant_plan_builder();



create table solr_genes as
select
  genes.id as id,
  CAST( 'gene' AS text ) as type,
  CAST( '-1' AS text ) as allele_id,
  solr_gene_statuses.consortium as consortium,
  solr_gene_statuses.production_centre_name as production_centre,
  COALESCE(genes.mgi_accession_id, 'unknown') as mgi_accession_id,
  solr_gene_statuses.status_name as status,
  solr_gene_statuses.created_at as effective_date,

  solr_ikmc_projects_details_agg_es_cells.projects as project_ids,
  solr_ikmc_projects_details_agg_es_cells.statuses as project_statuses,
  solr_ikmc_projects_details_agg_es_cells.pipelines as project_pipelines,

  solr_ikmc_projects_details_agg_vectors.projects as vector_project_ids,
  solr_ikmc_projects_details_agg_vectors.statuses as vector_project_statuses,

  genes.marker_symbol as marker_symbol,
  genes.marker_type as marker_type
  from genes
    left join solr_gene_statuses on solr_gene_statuses.gene_id = genes.id
    left join solr_ikmc_projects_details_agg as solr_ikmc_projects_details_agg_vectors on solr_ikmc_projects_details_agg_vectors.gene_id = genes.id and solr_ikmc_projects_details_agg_vectors.type = 'vector'
    left join solr_ikmc_projects_details_agg as solr_ikmc_projects_details_agg_es_cells on solr_ikmc_projects_details_agg_es_cells.gene_id = genes.id and solr_ikmc_projects_details_agg_es_cells.type = 'es_cell'
  ;

CREATE INDEX solr_genes_idx ON solr_genes (id);
