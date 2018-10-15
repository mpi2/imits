#!/usr/bin/env ruby

missing = []
invalid = []
f = open('del_bam_files.txt', 'r')
f.readlines.each do |line|
  md = /(\w*?)_(.*)\.(\w*)/.match(line.strip)
  raise "#{line}" if md.blank? || md[1].blank? || md[2].blank? || md[3].blank?

  gene = md[1]
  colony = md[2]

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(replace(colonies.name, ' ', ''),'&', '_') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.bam_file = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/del/temp/#{line.strip}" ,'rb').read
  if ! a.save
    invalid << a
  end
end


missing2 = []
invalid2 = []
f = open('hdr_bam_files.txt', 'r')
f.readlines.each do |line|
  md = /(\w*?)_(.*)\.(\w*)/.match(line.strip)
  raise "#{line}" if md.blank? || md[1].blank? || md[2].blank? || md[3].blank?

  gene = md[1]
  colony = md[2]

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(replace(colonies.name, ' ', ''),'&', '_') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing2 << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.bam_file = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/hdr/temp/#{line.strip}" ,'rb').read
  if ! a.save
    invalid2 << a
  end
end


missing3 = []
invalid3 = []
f = open('del_vcf_files.txt', 'r')
f.readlines.each do |line|
  next if line =~ /\.tbi/
  md = /(.*?)_(.*)\.vcf\.gz/.match(line.strip)
  raise "#{line}" if md.blank? || md[1].blank? || md[2].blank? 

  gene = md[1]
  colony = md[2]

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(replace(colonies.name, ' ', ''),'&', '_') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing3 << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.vcf_file = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/del/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  a.vcf_file_index = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/del/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  if ! a.save
    invalid3 << a
  end
end


missing4 = []
invalid4 = []
f = open('hdr_vcf_files.txt', 'r')
f.readlines.each do |line|
  next if line =~ /\.tbi/
  md = /(.*?)_(.*)\.vcf\.gz/.match(line.strip)
  raise "#{line}" if md.blank? || md[1].blank? || md[2].blank? 

  gene = md[1]
  colony = md[2]

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(replace(colonies.name, ' ', ''),'&', '_') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing4 << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.vcf_file = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/hdr/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  a.vcf_file_index = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/hdr/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  if ! a.save
    invalid4 << a
  end
end

Allele.where("vcf_file IS NOT NULL").each do |a|
  next if a.annotations.blank?
  puts "\n", a.id, "\n"
  a.auto_allele_description = Allele.generate_allele_description( {'allele_id' => a.id} )
  raise "Error saving allele #{a.id}" unless a.save!
end




# [259625, 263981, 258602, 265113, 263874, 264005, 264925, 259487, 258493, 258327, 264544, 264998, 263893, 258599, 264804, 264792, 263876, 258873, 265189, 264768, 259512, 263895, 265187, 263999, 258912, 263868, 265182, 258815, 265193, 264994, 259000, 259488, 259003, 264778, 265125, 264801, 258689, 264000, 264103, 258603, 258835, 259641, 264776, 258688, 264781, 258966, 264543, 258964, 259759, 263883, 259755, 259280, 265192, 259070, 263991, 258648, 265224, 259283, 264105, 264993, 258984, 258525, 258735, 264812, 264102, 263985, 265184, 263837, 259541, 264539, 258793, 264992, 264008, 263992, 259006, 263977, 265298, 265297, 259480, 259413, 265218, 258965, 264770, 263867, 263995, 265092, 264808, 258615, 258826, 263888, 264004, 264783, 263882, 263871, 263896, 265292, 265299, 264537, 258983, 264767, 264806, 259414, 258687, 264784, 264798, 258727, 258836, 259513, 263892, 263996, 265301, 264811, 264009, 265287, 263983, 264540, 265300, 258657, 265122, 258828, 264893, 258494, 258670, 263866, 265116, 265302, 259539, 265185, 265114, 263994, 259811, 263989, 263894, 265117, 263875, 265118, 264795, 259183, 259380, 264774, 265288, 258650, 264810, 263887, 263927, 264892, 264782, 258486, 265188, 265286, 263943, 258858, 259143, 258734, 258726, 258725, 259624, 259069, 263881, 258533, 258968, 258986, 263986, 263900, 258649, 258654, 264786, 264787, 264797, 264773, 264772, 265194, 258485, 265123, 258827, 264807, 263884, 264991, 259282, 263998, 259138, 263997, 263978, 263898, 264536, 265126, 264542, 263885, 264921, 264800, 259326, 259008, 264545, 264006, 264995, 264894, 264788, 264001, 259757, 264920, 264047, 263877, 263890, 258658, 259005, 264794, 258600, 264546, 265190, 258487, 264802, 258950, 265121, 263886, 258934, 263870, 264809, 265124, 265127, 263891, 264538, 265181, 264775, 263990, 259519, 264046, 264106, 265311, 263982, 258653, 263869, 263993, 265119, 258987, 258652, 258820, 258434, 263880, 259639, 264010, 259535, 265112, 264796, 263878, 264007, 263984, 265295, 258686, 258921, 258613, 258668, 264997, 265223, 259002, 263873, 263872, 259039, 259004, 264769, 265115, 263899, 258484, 264790, 263980, 259643, 264107, 265095, 264002, 265197, 264104, 258758, 264922, 264996, 258651, 258910, 259168, 259758, 265195, 258575, 265186, 264003, 258672, 258838, 258816, 265310, 258616, 264504, 258655, 264924, 265305, 258895, 263889, 265183, 265307, 265180, 265289, 264805, 258916, 264875, 265309, 258911, 264799, 264049, 264785, 258825, 258656, 265120, 264923, 258614, 264989, 259306, 265320, 259810, 263879, 259686, 259389, 258759, 259142, 259638, 263865, 258819, 259279, 258492, 264541, 259640, 258671, 258841, 259626, 265294, 258495, 259642, 265296, 264663, 264771, 265196, 264990, 263897, 258673, 265303, 259007, 259128] 


# 259391, 259174, 259001, 258985, 258967,









