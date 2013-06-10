sql = <<-EOF
INSERT INTO targ_rep_ikmc_projects (name, pipeline_id, created_at, updated_at)
SELECT t.ikmc_project_id, t.pipeline_id, Now(), NOW() FROM (SELECT DISTINCT ikmc_project_id, pipeline_id FROM targ_rep_es_cells WHERE ikmc_project_id IS NOT NULL AND ikmc_project_id !=''
UNION
SELECT DISTINCT ikmc_project_id, pipeline_id FROM targ_rep_targeting_vectors WHERE ikmc_project_id IS NOT NULL AND ikmc_project_id !='') AS t;
EOF
ActiveRecord::Base.connection.execute(sql)
#ikmc_projects = TargRep::IkmcProject.all;nil
#n=0
#ikmc_projects.each do |project|
#  puts "project: #{project['name']}"
#  puts "pipeline: #{project['pipeline_id']}"

sql = <<-EOF
UPDATE targ_rep_es_cells SET ikmc_project_foreign_id = targ_rep_ikmc_projects.id
FROM targ_rep_ikmc_projects
WHERE
targ_rep_ikmc_projects.name = targ_rep_es_cells.ikmc_project_id
AND targ_rep_ikmc_projects.pipeline_id = targ_rep_es_cells.pipeline_id
AND targ_rep_es_cells.ikmc_project_id IS NOT NULL AND targ_rep_es_cells.ikmc_project_id != '';
EOF
ActiveRecord::Base.connection.execute(sql)

#  es_cells = TargRep::EsCell.where("ikmc_project_id = '#{project['name']}' AND pipeline_id = '#{project['pipeline_id']}'")
#  TargRep::EsCell.update_all({:ikmc_project_foreign_id => project['id']}, {:id => es_cells.map(&:id)})

sql = <<-EOF
UPDATE targ_rep_targeting_vectors SET ikmc_project_foreign_id = targ_rep_ikmc_projects.id
FROM targ_rep_ikmc_projects
WHERE
targ_rep_ikmc_projects.name = targ_rep_targeting_vectors.ikmc_project_id
AND targ_rep_ikmc_projects.pipeline_id = targ_rep_targeting_vectors.pipeline_id
AND targ_rep_es_cells.ikmc_project_id IS NOT NULL AND targ_rep_targeting_vectors.ikmc_project_id != '';
EOF
ActiveRecord::Base.connection.execute(sql)

#  targeting_vectors = TargRep::EsCell.where("ikmc_project_id = '#{project['ikmc_project_id']}' AND pipeline_id = '#{project['pipeline_id']}'")
#  TargRep::TargetingVector.update_all({:ikmc_project_foreign_id => project['id']}, {:id => targeting_vectors.map(&:id)})
#end;nil

