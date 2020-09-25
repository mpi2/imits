file = "/Users/albagomez/Desktop/colonies_wtsi.csv"

# rows = [colony_name, mgi_accession_id, mgi_allele_symbol_superscript, allele_type background_strain_name, production_center production_consortium, phenotyping_center, phenotyping_consortium]

# targ_rep_alleles
one_per_gene = []
CSV.foreach(file, :headers => true) do |row|
  if !one_per_gene.include?(row[1])
    sql = "INSERT INTO targ_rep_alleles (gene_id, chromosome, strand, mutation_method_id, mutation_type_id, created_at, updated_at) VALUES ((SELECT id FROM genes WHERE mgi_accession_id = '#{row[1]}'), (SELECT chr FROM genes WHERE mgi_accession_id = '#{row[1]}'), (SELECT strand_name FROM genes WHERE mgi_accession_id = '#{row[1]}'), 1, 2, now(), now());"
    ActiveRecord::Base.connection.execute(sql)
    one_per_gene.push(row[1])
  end
end

# targ_rep_es_cells
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO targ_rep_es_cells (allele_id, parental_cell_line, name, comment, pipeline_id, strain, created_at, updated_at) VALUES ((SELECT a.id FROM targ_rep_alleles a JOIN genes g ON a.gene_id = g.id WHERE g.mgi_accession_id = '#{row[1]}' AND a.created_at >= '2020-08-04'), 'JM8A', 'Legacy Project Placeholder for #{row[0]}', 'Dummy ES Cell for Legacy Project', 4, '#{row[3]}', now(), now());"
  ActiveRecord::Base.connection.execute(sql)
end

# alleles (es_cell_id)
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO alleles (es_cell_id, mgi_allele_symbol_superscript, allele_type, created_at, updated_at) VALUES ((SELECT id FROM targ_rep_es_cells WHERE name = 'Legacy Project Placeholder for #{row[0]}'), '#{row[2]}', '#{row[3]}', now(), now());"
  ActiveRecord::Base.connection.execute(sql)
end

# mi_plans
plan_already_exist = []
CSV.foreach(file, :headers => true) do |row|
  begin
    puts row[1]
    sql = "INSERT INTO mi_plans (gene_id, consortium_id, status_id, priority_id, production_centre_id, created_at, updated_at, sub_project_id) VALUES ((SELECT id FROM genes WHERE mgi_accession_id = '#{row[1]}'), (SELECT id FROM consortia WHERE name = '#{row[6]}'), 1, 3, (SELECT id FROM centres WHERE name = '#{row[5]}'), now(), now(), 1);"
    ActiveRecord::Base.connection.execute(sql)
  rescue
    plan_already_exist.push(row[1])
  end
end

# mi_attempts
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO mi_attempts (es_cell_id, mi_date, status_id, external_ref, total_male_chimeras, total_chimeras, number_of_chimeras_with_glt_from_genotyping, number_of_het_offspring, report_to_public, is_active, comments, created_at, updated_at, mi_plan_id, cassette_transmission_verified, cassette_transmission_verified_auto_complete, experimental, crsp_embryo_transfer_day, haplo_essential) VALUES ((SELECT id FROM targ_rep_es_cells WHERE name = 'Legacy Project Placeholder for #{row[0]}'), '2009-07-30', 2, '#{row[0]}', 1, 1, 1, 1, false, true, 'Dummy Mi Attempt for Legacy Project', now(), now(), (SELECT p.id FROM mi_plans p JOIN genes g ON p.gene_id = g.id JOIN consortia co ON p.consortium_id = co.id JOIN centres ce ON p.production_centre_id = ce.id WHERE g.mgi_accession_id = '#{row[1]}' AND co.name = '#{row[6]}' AND ce.name = '#{row[5]}' AND p.phenotype_only = false), now(), true, false, 'Same Day', false);"
  ActiveRecord::Base.connection.execute(sql)
end

# colonies
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO colonies (name, mi_attempt_id, genotype_confirmed, report_to_public, background_strain_id, is_released_from_genotyping) VALUES ('#{row[0]}', (SELECT id FROM mi_attempts WHERE external_ref = '#{row[0]}'), true, false, (SELECT id FROM strains WHERE name = '#{row[4]}'), true);"
  ActiveRecord::Base.connection.execute(sql)
end

# alleles (colony_id)
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO alleles (mgi_allele_symbol_superscript, allele_type, created_at, updated_at, colony_id, same_as_es_cell) VALUES ('#{row[2]}', '#{row[3]}', now(), now(), (SELECT id FROM colonies WHERE name = '#{row[0]}'), true);"
  ActiveRecord::Base.connection.execute(sql)
end

# production_centre_qcs
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO production_centre_qcs (allele_id) VALUES ((SELECT a.id FROM alleles a JOIN colonies c ON a.colony_id = c.id WHERE c.name = '#{row[0]}'));"
  ActiveRecord::Base.connection.execute(sql)
end

# distribution_centre
CSV.foreach(file, :headers => true) do |row|
  sql = "INSERT INTO colony_distribution_centres (colony_id, deposited_material_id, centre_id, created_at, updated_at) VALUES ((SELECT id FROM colonies WHERE name = '#{row[0]}'), 2, (SELECT id FROM centres WHERE name = '#{row[5]}'), now(), now());"
  ActiveRecord::Base.connection.execute(sql)
end

# phenotyping_productions
CSV.foreach(file, :headers => true) do |row|
  attempt_sql = "INSERT INTO phenotype_attempt_ids VALUES (default);"
  ActiveRecord::Base.connection.execute(attempt_sql)

  sql = "INSERT INTO phenotyping_productions (mi_plan_id, status_id, colony_name, phenotyping_experiments_started, phenotyping_started, phenotyping_complete, phenotype_attempt_id, created_at, updated_at, parent_colony_id, colony_background_strain_id, late_adult_status_id) VALUES ((SELECT p.id FROM mi_plans p JOIN genes g ON p.gene_id = g.id JOIN consortia co ON p.consortium_id = co.id JOIN centres ce ON p.production_centre_id = ce.id WHERE g.mgi_accession_id = '#{row[1]}' AND co.name = '#{row[6]}' AND ce.name = '#{row[5]}' AND p.phenotype_only = false), 4, '#{row[0]}', now(), true, true, (select id from phenotype_attempt_ids ORDER BY id DESC limit 1), now(), now(), (SELECT id FROM colonies WHERE name = '#{row[0]}'), (SELECT background_strain_id FROM colonies WHERE name = '#{row[0]}'), 1);"
  ActiveRecord::Base.connection.execute(sql)
end


