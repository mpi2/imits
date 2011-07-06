DROP VIEW formatted_clones;
CREATE VIEW formatted_clones AS
       SELECT clone_name,
       	      marker_symbol,
	      allele_symbol_superscript_template AS anst,
	      allele_type,
	      REPLACE(allele_symbol_superscript_template, '@', COALESCE(allele_type, '')) AS allele_symbol_superscript
         FROM clones;

DROP VIEW formatted_mi_attempts;
CREATE VIEW formatted_mi_attempts AS
       SELECT colony_name,
              clones.allele_symbol_superscript_template AS anst,
       	      mouse_allele_type,
	      REPLACE(clones.allele_symbol_superscript_template, '@', mouse_allele_type) AS mouse_allele_symbol_superscript
       FROM mi_attempts
       INNER JOIN clones ON clones.id = mi_attempts.clone_id;

select * from formatted_clones;
select * from formatted_mi_attempts where mouse_allele_symbol_superscript IS NOT NULL;
