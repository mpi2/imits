\COPY ( WITH mi_attempt_status_summary AS ( SELECT miss.mi_attempt_id, mias.name AS miip, mias_chimeras.name AS chimeras, mias_genotype.name AS genotype     FROM mi_attempt_status_stamps miss     LEFT JOIN mi_attempt_statuses mias ON mias.id = miss.status_id AND mias.name = 'Micro-injection in progress'     LEFT JOIN mi_attempt_statuses mias_chimeras ON mias_chimeras.id = miss.status_id AND mias_chimeras.name = 'Chimeras/Founder obtained'     LEFT JOIN mi_attempt_statuses mias_genotype ON mias_genotype.id = miss.status_id AND mias_genotype.name = 'Genotype confirmed'     GROUP BY miss.mi_attempt_id, mias.name, mias_chimeras.name, mias_genotype.name ) SELECT genes.marker_symbol,      COUNT( mi_attempt_status_summary.miip ) - COUNT( mi_attempt_status_summary.chimeras ) AS in_progresss, COUNT( mi_attempt_status_summary.chimeras ) - COUNT( mi_attempt_status_summary.genotype ) AS chimeras, COUNT( mi_attempt_status_summary.genotype ) AS genotype,     CASE WHEN COUNT( mi_attempt_status_summary.genotype ) > 0 THEN 'GLT'     WHEN COUNT( mi_attempt_status_summary.chimeras ) > 0 THEN 'Chimeras/Founder obtained'     ELSE 'Mi started' END AS gene_status FROM mi_attempts      JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id     JOIN genes ON mi_plans.gene_id = genes.id     JOIN mi_attempt_status_summary ON mi_attempt_status_summary.mi_attempt_id = mi_attempts.id WHERE mi_attempts.mi_date < now() - INTERVAL '180 DAY' GROUP BY genes.marker_symbol) TO 'intractome_gene_summary.csv' WITH CSV HEADER;


