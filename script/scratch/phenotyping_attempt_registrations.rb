mgp_colonies = [] 
ucd_colonies = []
jax_colonies = []
norcomm_colonies = []

#File.open("mgp_phenotype_complete_colonies.csv").each do |line|
#File.open("test.csv").each do |line|
#  line.chomp!
#  mgp_colonies << line  
#end

File.open("ucd_gc_mice.csv").each do |line|
  line.chomp!
  ucd_colonies << line
end
dtcc_consortium = Consortium.find_by_name('DTCC')
ucd = Centre.find_by_name('UCD')

MiPlan.transaction do
  Audit.as_user(User.find_by_email!("vvi@sanger.ac.uk")) do
    ucd_colonies.each do |colony|
      mouse = MiAttempt.find_by_colony_name(colony)
      if mouse.eql? nil
        puts "no mouse for #{colony}"
        next
      else
        gene_id = mouse.mi_plan.gene.id
        miplan = MiPlan.where({:gene_id=>gene_id, :consortium_id => dtcc_consortium.id}).first
        if(miplan.nil?)
          raise "no mi plan found in DTCC for colony #{colony}"
        else
          puts "for colony #{colony} already found an miplan for this gene: #{miplan.gene.marker_symbol}"
        end
        if(miplan.phenotype_attempts.size > 0)
          puts "not making a phenotype attempt - plan already has one"
        else
          pa = PhenotypeAttempt.new()
          pa.mi_attempt_id = mouse.id
          pa.mi_plan_id = miplan.id
          puts "will make phenotype attempt for #{colony} - set consortium #{pa.mi_plan.consortium_id}"
          pa.save!
        end
      end
    end
  end
end
