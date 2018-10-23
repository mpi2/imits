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
  # a.vcf_file = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/del/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  # a.vcf_file_index = open( "/Users/albagomez/Documents/iMits/crisprcon_outputfiles/pipelineOutput/del/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
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

# Allele.where("vcf_file IS NOT NULL").each do |a|
#   next if a.annotations.blank?
#   puts "\n", a.id, "\n"
#   puts "\n" + a.id.to_s + "\n"
#   a.auto_allele_description = Allele.generate_allele_description( {'allele_id' => a.id} )
#   raise "Error saving allele #{a.id}" unless a.save!
# end

alleles.each do |a_id|
  a = Allele.find(a_id)
  next if a.annotations.blank?
  puts "\n", a.id, "\n"
  puts "\n" + a.id.to_s + "\n"
  a.auto_allele_description = Allele.generate_allele_description( {'allele_id' => a.id} )
  raise "Error saving allele #{a.id}" unless a.save!
end


alleles =  [259626, 265296, 258495, 264771, 265196, 265303, 258673, 264993, 265297, 259007, 258828, 265287, 264005, 265113, 264925, 258965, 259487, 258493, 258858, 265300, 264539, 265117, 263895, 265301, 265182, 259003, 259759, 265193, 265125, 264801, 258689, 259641, 264776, 264000, 263869, 264543, 263883, 265192, 263991, 263885, 263993, 259541, 264812, 265184, 264992, 263992, 264772, 258793, 258656, 265189, 263900, 258820, 263874, 265298, 264796, 259480, 265223, 259413, 263995, 265218, 265305, 259638, 263888, 264995, 258615, 263871, 265292, 264783, 259640, 259414, 265183, 258651, 259069, 264546, 264007, 263873, 263983, 264998, 265181, 259686, 264768, 258657, 264663, 263870, 264049, 258670, 265116, 265114, 263981, 265185, 265320, 265124, 263994, 263999, 258815, 263894, 263893, 258599, 264538, 265180, 263878, 265121, 263943, 258725, 258964, 264798, 264781, 263977, 264778, 259128, 258400, 264892, 264782, 258895, 259430, 258326, 258986, 263846, 258654, 264729, 264636, 264849, 258885, 264028, 264607, 264567, 264996, 258359, 264103, 259317, 259693, 258931, 263959, 259015, 259257, 258816, 258620, 259331, 259733, 258361, 263958, 259221, 258797, 258591, 258759, 259431, 258982, 264053, 258619, 258724, 259510, 263984, 258581, 259383, 264129, 259074, 258434, 258831, 264861, 264967, 258618, 263842, 258378, 258863, 263845, 264069, 258799, 259754, 264658, 259537, 258739, 258781, 264730, 264850, 264822, 264677, 258786, 264921, 259812, 258691, 264915, 258934, 258645, 263844, 259489, 258928, 259429, 264048, 259644, 264966, 264664, 258355, 258761, 263852, 258325, 264676, 264723, 258834, 264097, 263849, 258878, 258702, 259419, 259143, 264751, 265025, 258995, 264704, 264076, 258911, 259397, 258364, 263853, 258790, 259116, 263953, 265118, 264731, 263850, 263965, 264856, 259809, 258419, 258412, 258893, 258854, 259302, 264138, 258349, 258360, 258368, 258603, 258602, 258666, 258714, 258736, 258838, 258919, 258921, 258981, 259037, 259079, 259098, 259101, 259183, 259178, 259210, 259201, 258846, 259777, 263866, 263902, 263843, 263904, 263962, 263837, 259491, 258616, 258650, 263881, 258648, 258983, 258598, 258642, 263898, 264072, 264082, 263963, 264038, 259024, 264504, 264545, 264540, 258944, 264587, 264003, 259755, 264606, 258485, 258817, 265311, 264832, 264001, 264889, 259139, 258960, 258354, 264670, 258377, 258762, 264674, 259432, 264709, 264708, 264132, 258966, 258357, 265122, 264745, 259479, 259747, 259159, 259520, 259200, 264811, 264794, 264770, 264813, 259155, 264814, 264815, 265187, 265195, 264808, 264866, 264009, 258425, 258523, 264804, 264913, 259751, 258933, 259442, 259020, 258729, 265123, 258962, 259384, 264990, 264989, 265061, 265067, 265294, 265286, 258841, 258686, 259642, 259625, 264105, 258910, 264008, 258492, 258968, 263868, 263875, 263876, 264790, 259070, 263989, 264792, 264773, 263865, 264810, 258984, 264805, 264994, 264802, 259488, 263889, 264806, 264799, 259142, 264893, 264102, 258533, 258327, 264969, 264177, 264753, 263891, 258835, 259522, 264867, 259512, 263985, 263980, 263897, 258697, 258795, 259000, 258628, 258514, 264512, 263915, 258449, 258521, 265016, 258622, 264130, 265079, 259083, 258560, 264816, 258333, 258726, 265054, 264765, 259347, 264602, 259611, 258974, 259811, 259409, 259719, 264888, 259313, 258738, 263960, 258480, 258552, 259664, 259256, 258696, 258874, 258735, 263968, 264604, 259291, 258529, 258897, 258752, 258455, 258629, 259330, 263986, 258924, 259269, 264864, 258596, 259780, 263860, 259544, 258873, 258792, 264939, 263872, 264786, 264905, 259072, 259298, 259199, 258555, 259679, 264175, 263867, 258681, 264642, 259323, 263998, 258535, 263908, 265006, 258519, 258948, 259568, 258993, 258617, 263909, 258609, 258350, 258394, 263848, 258850, 258868, 264700, 258698, 259563, 259034, 258539, 265007, 258655, 259164, 264940, 264767, 264890, 258734, 258393, 259066, 259758, 264605, 259279, 264159, 264544, 265092, 258388, 264568, 259093, 258882, 258852, 259125, 258545, 258334, 258631, 259153, 264611, 264537, 265194, 258727, 264608, 258970, 263859, 264807, 259417, 259621, 259585, 265015, 259148, 264513, 264101, 258562, 258672, 264775, 258836, 259561, 259712, 264045, 258782, 259270, 259127, 265295, 264875, 264923, 258537, 258501, 265057, 259726, 258825, 259280, 258610, 259059, 264541, 265014, 265003, 258365, 259548, 264563, 265017, 258722, 264181, 264194, 259624, 258553, 259745, 259338, 259619, 258335, 259356, 258912, 258789, 258573, 263961, 259141, 258389, 258570, 264598, 264042, 258957, 264036, 264891, 259771, 258534, 258383, 259424, 265010, 258865, 265299, 258827, 263887, 263884, 259282, 264991, 264784, 259138, 263997, 263978, 263952, 259785, 265288, 264542, 264536, 265126, 258932, 258525, 259151, 264800, 259326, 264006, 264894, 259008, 258649, 259757, 264788, 264920, 264047, 263877, 259005, 263890, 258600, 258658, 265190, 258487, 258950, 263886, 263927, 258687, 264809, 265127, 263990, 259519, 264046, 264106, 263982, 258653, 258688, 258987, 265119, 258652, 259639, 264797, 259513, 263880, 264010, 265112, 259535, 259006, 258613, 264795, 263892, 258494, 264997, 258668, 259002, 259039, 259004, 264769, 265115, 258484, 263899, 264107, 259643, 265095, 264104, 264002, 265197, 258758, 264922, 265188, 259168, 258575, 258486, 263882, 258826, 263896, 265186, 265224, 265310, 264774, 264924, 263996, 265307, 258916, 264004, 265289, 259539, 265309, 264787, 264785, 258614, 265120, 265302, 263879, 259306, 259810, 259380, 258819, 259389, 258671, 259283] 

# 258967, 258985, 259391, 259174, 259001, 

