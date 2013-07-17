
# create any new ikmc_projects belonging to recently added products (targeting vectors and clones)
sql = <<-EOF
INSERT INTO targ_rep_ikmc_projects (name, pipeline_id, created_at, updated_at)
SELECT t.ikmc_project_id, t.pipeline_id, Now(), NOW() FROM
(SELECT DISTINCT ikmc_project_id, pipeline_id FROM targ_rep_es_cells WHERE ikmc_project_id IS NOT NULL AND ikmc_project_id !=''
UNION
SELECT DISTINCT ikmc_project_id, pipeline_id FROM targ_rep_targeting_vectors WHERE ikmc_project_id IS NOT NULL AND ikmc_project_id !='') AS t
LEFT JOIN targ_rep_ikmc_projects ON targ_rep_ikmc_projects.name = t.ikmc_project_id AND targ_rep_ikmc_projects.pipeline_id= t.pipeline_id
WHERE targ_rep_ikmc_projects.id IS NULL;
EOF
ActiveRecord::Base.connection.execute(sql)


# update ikmc_project foreign key on;

#clone
sql = <<-EOF

UPDATE targ_rep_es_cells SET ikmc_project_foreign_id = targ_rep_ikmc_projects.id
FROM targ_rep_ikmc_projects
WHERE
targ_rep_ikmc_projects.name = targ_rep_es_cells.ikmc_project_id
AND targ_rep_ikmc_projects.pipeline_id = targ_rep_es_cells.pipeline_id
AND targ_rep_es_cells.ikmc_project_foreign_id IS NULL;

EOF
ActiveRecord::Base.connection.execute(sql)

# targeting veectors
sql = <<-EOF
UPDATE targ_rep_targeting_vectors SET ikmc_project_foreign_id = targ_rep_ikmc_projects.id
FROM targ_rep_ikmc_projects
WHERE
targ_rep_ikmc_projects.name = targ_rep_targeting_vectors.ikmc_project_id
AND targ_rep_ikmc_projects.pipeline_id = targ_rep_targeting_vectors.pipeline_id
AND targ_rep_targeting_vectors.ikmc_project_foreign_id IS NULL;
EOF
ActiveRecord::Base.connection.execute(sql)


# update status of ikmc_projects for projects with products in tarmits
sql = <<-EOF
UPDATE targ_rep_ikmc_projects SET status_id = ikmc_project_status.best_ikmc_project_status
FROM
(SELECT
  ikmc_project_statuses.ikmc_project_id AS ikmc_project_id,
  CASE MIN(ikmc_project_statuses.ikmc_project_status_order)
    WHEN 1 THEN 14                                      -- Mice - Phenotype Data Available
    WHEN 2 THEN 13                                      -- Mice - Genotype confirmed
    WHEN 3 THEN 12                                      -- Mice - Microinjection in progress
    WHEN 4 THEN 8                                       -- ES Cells - Targeting Confirmed
    WHEN 5 THEN 5                                       -- Vector Complete
    ELSE NULL
  END AS best_ikmc_project_status
  FROM
    (SELECT targ_rep_ikmc_projects.id AS ikmc_project_id,
    CASE WHEN phenotype_attempt_statuses.name = 'Phenotyping Complete' THEN 1
      WHEN mi_attempt_statuses.name = 'Micro-injection in progress' THEN 2
      WHEN mi_attempt_statuses.name IS NOT NULL THEN 3
      WHEN targ_rep_es_cells.id IS NOT NULL THEN 4
      WHEN targ_rep_targeting_vectors.id IS NOT NULL THEN 5
      ELSE 6
    END AS ikmc_project_status_order
    FROM
    targ_rep_ikmc_projects
    LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.ikmc_project_foreign_id = targ_rep_ikmc_projects.id AND report_to_public = 't'
    LEFT JOIN targ_rep_es_cells ON targ_rep_es_cells.ikmc_project_foreign_id = targ_rep_ikmc_projects.id AND report_to_public = 't'
    LEFT JOIN (mi_attempts JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id AND mi_attempt_statuses.name != 'Micro-injection aborted' ) ON mi_attempts.es_cell_id = targ_rep_es_cells.id
    LEFT JOIN (phenotype_attempts JOIN phenotype_attempt_statuses ON phenotype_attempt_statuses.id = phenotype_attempts.status_id AND phenotype_attempt_statuses.name != 'Phenotype Attempt Aborted' ) ON phenotype_attempts.mi_attempt_id = mi_attempts.id
    ) AS ikmc_project_statuses
  GROUP BY ikmc_project_statuses.ikmc_project_id
) AS ikmc_project_status WHERE targ_rep_ikmc_projects.id = ikmc_project_status.ikmc_project_id
EOF
ActiveRecord::Base.connection.execute(sql)



# read file and update

require 'open-uri'
headers = []
data = {}

url = "http://www.sanger.ac.uk/htgt/report/get_projects?view=csvdl&file=tmp.csv"
open(url) do |file|
  headers = file.readline.strip.split(',')
  file.each_line do |line|
    row = line.strip.gsub(/\"/, '').split(',')
    project_index = headers.index('allele_id')
    status_index = headers.index('pipeline_status')
    eucomm_tools_index = headers.index('eucomm_tools')
    if row[eucomm_tools_index] = 1
      data[row[project_index]] = {'project_id' => row[project_index], 'status_id' => row[status_index], 'pipeline_id' => '7' }
    end
  end
end

sql = <<-EOF
SELECT *
FROM targ_rep_ikmc_projects
WHERE targ_rep_ikmc_projects.pipeline_id = 7 AND targ_rep_ikmc_projects.name IN (#{data.keys.join(',')})
EOF

results = ActiveRecord::Base.connection.execute(sql)

result.each do |record|

end









