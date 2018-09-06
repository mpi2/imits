#!/usr/bin/env ruby

missing = []
invalid = []
f = open('del_bam_files.txt', 'r')
f.readlines.each do |line|
  md = /(\w*?)_(.*)\.(\w*)/.match(line.strip)
  raise "#{line}" if md.blank? || md[1].blank? || md[2].blank? || md[3].blank?

  gene = md[1]
  colony = md[2]

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(colonies.name, ' ', '') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.bam_file = open( "/Users/pm9/Documents/pipelineOutput/del/temp/#{line.strip}" ,'rb').read
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

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(colonies.name, ' ', '') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing2 << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.bam_file = open( "/Users/pm9/Documents/pipelineOutput/hdr/temp/#{line.strip}" ,'rb').read
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

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(colonies.name, ' ', '') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing3 << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.vcf_file = open( "/Users/pm9/Documents/pipelineOutput/del/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  a.vcf_file_index = open( "/Users/pm9/Documents/pipelineOutput/del/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
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

  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(genes.marker_symbol, ' ', '') = '#{gene}' AND replace(colonies.name, ' ', '') = '#{colony}'")
  c = Colony.joins(mi_attempt: [mi_plan: :gene]).where("replace(colonies.name, ' ', '') = '#{colony}'") if c.blank?  
  if c.blank?
    missing4 << "#{gene}, #{colony}"
    next
  end

  a = Allele.find(c.first.alleles.first.id)
  a.vcf_file = open( "/Users/pm9/Documents/pipelineOutput/hdr/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  a.vcf_file_index = open( "/Users/pm9/Documents/pipelineOutput/hdr/#{md[1]}_#{md[2]}.vcf.gz" ,'rb').read
  if ! a.save
    invalid4 << a
  end
end

Allele.where("vcf_file IS NOT NULL").each do |a|
  next if a.annotations.blank?
  a.auto_allele_description = Allele.generate_allele_description( {'allele_id' => a.id} )
  raise "Error saving allele #{a.id}" unless a.save
end
