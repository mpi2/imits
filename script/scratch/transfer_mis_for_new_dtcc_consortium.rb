genes_to_subprojects = []

File.open("mis_to_move_to_dtcc_legacy.csv").each do |line|
  line.chomp!
  cols = line.split "\t"
  mgi_acc = cols[3]
  subproject_name = cols[1]
  gene = Gene.find_by_mgi_accession_id!(mgi_acc)
  subproject = MIPlan::SubProject.find_by_name!(subproject_name)
  plans = MiPlan.search({:sub_project_id => subproject.id, :gene_id => gene.id})
  raise "no plans for #{mgi_acc} and #{gene}" unless plans[0]
end


#
#MiPlan.transaction do
#  Audit.as_user(User.find_by_email!("vvi@sanger.ac.uk")) do
#  end
#end