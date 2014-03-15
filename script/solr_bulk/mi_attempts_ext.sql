
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


select id,
marker_symbol || '<sup>' || replace(allele_symbol_superscript_template_es_cell, '@',  COALESCE(allele_type_es_cell, '')) || '</sup>' as answer
from
(select id,
case
  when found > 0 then true
  else false
end as existed,
case
  when char_length(allele_symbol_superscript_plan) > 0 then
    marker_symbol || '<sup>' || allele_symbol_superscript_plan || '</sup>'
  when char_length(allele_symbol_superscript_template) > 0 and char_length(mouse_allele_type) > 0 then
    marker_symbol || '<sup>' || replace(allele_symbol_superscript_template, '@', COALESCE(mouse_allele_type, '')) || '</sup>'
  else
end as result
from
(
select
mi_attempts.id as id,
thingy.id as found,
mi_plans.allele_symbol_superscript as allele_symbol_superscript,
targ_rep_es_cells.allele_symbol_superscript_template as allele_symbol_superscript_template,
mi_attempts.mouse_allele_type as mouse_allele_type,
targ_rep_es_cells.allele_symbol_superscript_template as allele_symbol_superscript_template,
targ_rep_es_cells.allele_type as allele_type
from mi_attempts
left join targ_rep_es_cells as thingy on thingy.id = mi_attempts.es_cell_id and mi_attempts.id = mi_attempts.id
left join mi_plans on mi_plans.id = mi_attempts.mi_plan_id
left join targ_rep_es_cells on targ_rep_es_cells.id = mi_attempts.es_cell_id
left join genes on mi_plans.id = mi_attempts.mi_plan_id and mi_plans.gene_id = genes.id
)
);
