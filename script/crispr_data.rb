
def extract_info_from_comments(row)
  extracted_info = {}
  production_centre = row['production_centre']
  comment = row['comment'].to_s
  allele_type = row['allele']

  multiplex = false
  oligo = false
  vector = false
  concentrations = {}
  genes = nil
  muliplex = false

  if production_centre == 'BCM'
    bcm_md = /\(multi[gene]*:([\w, ]*)\)/.match(comment)
    if bcm_md
      muliplex = true
      genes = bcm_md[1].split(',').sort{|a, b| a <=> b}.to_s
    end
  end

  if production_centre == 'TCP'
    tcp_md = /mplex/.match(comment)
    if tcp_md
      muliplex = true
    end
  end

  con_md = comment.scan /([\w :\)\(=]*[\d.]+[ ]*ng\/.[lL][ \w]*)/

  con_md.each do |md2|
    md = md2.to_s
    concentrations['guide_con'] = /([\d.]+[ ]*ng\/.[lL])/.match(md)[1] if md=~ /gRNA/ || md=~ /guide/
    concentrations['cas9_con'] = /([\d.]+[ ]*ng\/.[lL])/.match(md)[1] if md=~ /[Cc]as[ ]*9/ || md=~ /[Dd]10A/
    concentrations['oligo_con'] = /([\d.]+[ ]*ng\/.[lL])/.match(md)[1] if md=~ /[oO]ligo/
    concentrations['donor_con'] = /([\d.]+[ ]*ng\/.[lL])/.match(md)[1] if md=~ /[pP]lasmid/ || md=~ /[Vv]ector/
  end

  mutation_type = 'HR flox' if concentrations.has_key?('donor_con')
  mutation_type = 'PM' if concentrations.has_key?('oligo_con')
  mutation_type = 'indel' if row['allele'] == 'NHEJ'
  mutation_type = 'exon deletion' if row['allele'] == 'Deletion'
  mutation_type = 'PM' if row['allele'] == 'HDR'
  mutation_type = 'HR flox' if row['allele'] == 'HR'

  return {'mutation_type' => mutation_type, 'concentrations' => concentrations, 'genes' => genes, 'multiplex' => muliplex}
end


def get_process_data(row, extracted_info)
{ 'founder_info' => {   'strain' => row['blast_strian'],
                        'embryos_injected' => row['embryos_injected'],
                        'embryos_transferred' => row['embryos_transferred'],
                        'cas9_cas9n'  => row['nuclease_enzyme'] =~ /D10A/ ? 'D10A' : 'CAS9',
                        'mRNA/protein' => row['nuclease_enzyme'] =~ /Protein/ ? 'Protein' : 'mRNA'
                    },
   'gene'        => {'marker_symbol' => row['marker_symbol'],
                            'production_centre' => row['production_centre'],
                            'primary_allele' => extracted_info['mutation_type'] ,
                            'secondary_allele' => ['PM', 'HR flox', 'exon deletion'].include?(extracted_info['mutation_type']) ? 'indel' : 'n.a.',
                            'num_grnas_gene' => row['no_crisprs'],
                            'cas9_cas9n_concentraction' => extracted_info['concentrations'].has_key?('cas9_con') ? extracted_info['concentrations']['cas9_con'] : '',
                            'grna_concentraction' => extracted_info['concentrations'].has_key?('guide_con') ? extracted_info['concentrations']['guide_con'] : '',
                            'template_concentraction' => extracted_info['concentrations'].has_key?('oligo_con') ? extracted_info['concentrations']['oligo_con'] : (extracted_info['concentrations'].has_key?('donor_con') ? extracted_info['concentrations']['donor_con'] : '') ,
                            'g0_screened' => row['no_founders_assayed'],
                            'g0_glt' => row['no_assays_with_positive_results'],
                            'g0_bred' => row['founders_selected_for_breading'],
                            'num_mutant_g0' => row['no_mutant_confirmed_founders'],
                            'num_glt_f1' => row['no_glt_f1'],
                            'glt_primary_allele' => row['no_glt_f1'].to_i > 1 ? 'Y' : 'N',
                            'experimental' => row['experimental'],
                            'repeat_report_to_public' => row['repeat_report_to_public'],
                            'comments' => row['comment'],
                            'status_name' => row['status_name']
                     }
 }
end




def get_data(gene_data, founder_data, num_of_genes)
#file.write("comments,experimental,repeated,status,production_centre,marker_symbol,#genes_inj,strain, primary_allele,secondary_allele,#e_injected,#e_transferred,cas9_d10a,mrna_protein,#grnas_gene,cas9_conc,grna_conc,template_conc,#go_screened,#go_glt,#g0_bred,#mutatnt_g0,#num_mutatnt_f1,glt_primary_allele")
  data_array = []
  data_array << (gene_data.has_key?('comments') && !gene_data['comments'].blank? ? '"' + gene_data['comments'].gsub(',', '') + '"' : '')
  data_array << (gene_data.has_key?('experimental') ? gene_data['experimental'] : '')
  data_array << (gene_data.has_key?('repeat_report_to_public') ? gene_data['repeat_report_to_public'] : '')
  data_array << (gene_data.has_key?('status_name') ? gene_data['status_name'] : '')
  data_array << (gene_data.has_key?('production_centre') ? gene_data['production_centre'] : '')
  data_array << gene_data['marker_symbol']
  data_array << num_of_genes
  data_array << (!founder_data.blank? && !founder_data['strain'].blank? ? founder_data['strain'] : 'B6N')
  data_array << (gene_data.has_key?('primary_allele') ? gene_data['primary_allele'] : '')
  data_array << (gene_data.has_key?('secondary_allele') ? gene_data['secondary_allele'] : '')
  data_array << (!founder_data.blank? ? founder_data['embryos_injected'] : '')
  data_array << (!founder_data.blank? ? founder_data['embryos_transferred'] : '')
  data_array << (!founder_data.blank? ? founder_data['cas9_cas9n'] : '')
  data_array << (!founder_data.blank? ? founder_data['mRNA/protein'] : '')
  data_array << (gene_data.has_key?('num_grnas_gene') ? gene_data['num_grnas_gene'] : '')
  data_array << (gene_data.has_key?('cas9_cas9n_concentraction') ? gene_data['cas9_cas9n_concentraction'] : '')
  data_array << (gene_data.has_key?('grna_concentraction') ? gene_data['grna_concentraction'] : '')
  data_array << (gene_data.has_key?('template_concentraction') ? gene_data['template_concentraction'] : '')
  data_array << (gene_data.has_key?('g0_screened') ? gene_data['g0_screened'] : '')
  data_array << (gene_data.has_key?('g0_glt') ? gene_data['g0_glt'] : '')
  data_array << (gene_data.has_key?('num_mutant_g0') ? gene_data['num_mutant_g0'] : '')
  data_array << (gene_data.has_key?('g0_bred') ? gene_data['g0_bred'] : '')
  data_array << (gene_data.has_key?('num_glt_f1') ? gene_data['num_glt_f1'] : '')
  data_array << (gene_data.has_key?('glt_primary_allele') ? gene_data['glt_primary_allele'] : '')

  return data_array.join(',')
end

sql =<<-EOF

SELECT centres.name AS production_centre,
genes.marker_symbol AS marker_symbol,
mi_attempts.report_to_public AS repeat_report_to_public,
mi_attempts.experimental AS experimental,
mutagenesis_factors.nuclease AS nuclease_enzyme,
CASE WHEN count(targ_rep_crisprs.id) = 1  AND targ_rep_targeting_vectors.name IS NULL THEN 'NHEJ'
     WHEN count(targ_rep_crisprs.id) >= 2 AND mutagenesis_factors.nuclease IN ('CAS9 mRNA', 'CAS9 Protein') AND targ_rep_targeting_vectors.name IS NULL  THEN 'Deletion'
     WHEN count(targ_rep_crisprs.id) = 2 AND mutagenesis_factors.nuclease IN ('D10A mRNA', 'D10A Protein') AND targ_rep_targeting_vectors.name IS NULL  THEN 'NHEJ'
     WHEN count(targ_rep_crisprs.id) = 4 AND mutagenesis_factors.nuclease IN ('D10A mRNA', 'D10A Protein') AND targ_rep_targeting_vectors.name IS NULL  THEN 'Deletion'
     WHEN targ_rep_targeting_vectors.name IS NOT NULL AND targ_rep_alleles.type = 'TargRep::HdrAllele'  THEN 'HDR'
     WHEN targ_rep_targeting_vectors.name IS NOT NULL AND targ_rep_alleles.type IN ('TargRep::TargetedAllele', 'TargRep::CrisprTargetedAllele')  THEN 'HR'
     ELSE ''
END AS allele,
count(targ_rep_crisprs.id) AS no_crisprs,
targ_rep_targeting_vectors.name AS vector_name,
CASE WHEN targ_rep_alleles.type = 'TargRep::HdrAllele' THEN 'Oligos'
     WHEN targ_rep_alleles.type = 'TargRep::CrisprTargetedAllele' THEN 'Targeting Vector' ELSE ''
END AS vector_or_oligos,
mi_attempt_statuses.name AS status_name,
mi_attempts.mi_date AS mi_date,
mi_attempts.crsp_total_embryos_injected AS embryos_injected,
mi_attempts.crsp_total_embryos_survived AS embryos_survived,
mi_attempts.crsp_total_transfered AS embryos_transferred,
mi_attempts.crsp_no_founder_pups AS no_founder_pups,
mi_attempts.assay_type AS assay_type_carried_out,
mi_attempts.founder_num_assays AS no_founders_assayed,
mi_attempts.founder_num_positive_results AS no_assays_with_positive_results,
mi_attempts.crsp_total_num_mutant_founders AS no_mutant_confirmed_founders,
mi_attempts.crsp_num_founders_selected_for_breading AS founders_selected_for_breading,
count(colony_counts.id) AS no_f1,
sum(CASE WHEN trace_calls.trace_file_file_name IS NOT NULL THEN 1 ELSE 0 END) AS no_f1_loaded_scf,
sum(CASE WHEN colony_counts.unwanted_allele = true THEN 1 ELSE 0 END) AS no_f1_with_unwanted_allele,
sum(CASE WHEN colony_counts.genotype_confirmed = true THEN 1 ELSE 0 END) AS no_glt_f1,
mi_attempts.comments AS comment, max(targ_rep_crisprs.end) - min(targ_rep_crisprs.start) AS length_of_deletion


FROM mi_attempts
  JOIN mi_attempt_statuses ON mi_attempt_statuses.id = mi_attempts.status_id
  JOIN mi_plans ON mi_plans.id = mi_attempts.mi_plan_id
  JOIN centres ON centres.id = mi_plans.production_centre_id
  JOIN genes ON genes.id = mi_plans.gene_id
  JOIN mutagenesis_factors ON mutagenesis_factors.id = mi_attempts.mutagenesis_factor_id
  JOIN targ_rep_crisprs ON targ_rep_crisprs.mutagenesis_factor_id = mutagenesis_factors.id

  LEFT JOIN colonies colony_counts ON mi_attempts.id = colony_counts.mi_attempt_id
  LEFT JOIN trace_calls ON trace_calls.colony_id = colony_counts.id
  LEFT JOIN targ_rep_targeting_vectors ON targ_rep_targeting_vectors.id = mutagenesis_factors.vector_id
  LEFT JOIN targ_rep_alleles ON targ_rep_alleles.id = targ_rep_targeting_vectors.allele_id

GROUP BY production_centre, marker_symbol, mi_attempts.report_to_public, mi_attempts.experimental, nuclease_enzyme, vector_name, vector_or_oligos, mi_attempt_statuses.name, mi_date, embryos_injected, embryos_survived, embryos_transferred, no_founder_pups, no_mutant_confirmed_founders, founders_selected_for_breading, assay_type_carried_out, no_founders_assayed, no_assays_with_positive_results, no_mutant_confirmed_founders, founders_selected_for_breading, comment, mi_attempts.id, targ_rep_alleles.type
ORDER BY production_centre, marker_symbol, nuclease_enzyme, no_crisprs, vector_name, vector_or_oligos


EOF


data = ActiveRecord::Base.connection.execute(sql)

process_data = {}

data.each do |row|

  production_centre = row['production_centre']
  marker_symbol = row['marker_symbol']
  mi_date = row['mi_date']
  comment_info = extract_info_from_comments(row)
  data = get_process_data(row, comment_info)

  if comment_info['multiplex'] == true
    process_data["#{row['production_centre']}_#{comment_info['genes']}_m_#{row['mi_date']}"] = {} unless process_data.has_key? ("#{row['production_centre']}_#{comment_info['genes']}_m_#{row['mi_date']}")


    process_data["#{row['production_centre']}_#{comment_info['genes']}_m_#{row['mi_date']}"]['founder_info'] = get_process_data(row, comment_info)['founder_info']
    process_data["#{row['production_centre']}_#{comment_info['genes']}_m_#{row['mi_date']}"][marker_symbol] = get_process_data(row, comment_info)['gene']
  else
    process_data["#{row['production_centre']}_#{row['marker_symbol']}_s_#{row['mi_date']}"] = {} unless process_data.has_key? ("#{row['production_centre']}_#{row['marker_symbol']}_s_#{row['mi_date']}")

    process_data["#{row['production_centre']}_#{row['marker_symbol']}_s_#{row['mi_date']}"]['founder_info'] = get_process_data(row, comment_info)['founder_info']
    process_data["#{row['production_centre']}_#{row['marker_symbol']}_s_#{row['mi_date']}"][marker_symbol] = get_process_data(row, comment_info)['gene']
  end

end


file = File.open('../korea_crispr_data', 'w')
file.write("comments,experimental,repeated,status,production_centre,marker_symbol,#genes_inj,strain, primary_allele,secondary_allele,#e_injected,#e_transferred,cas9_d10a,mrna_protein,#grnas_gene,cas9_conc,grna_conc,template_conc,#go_screened,#go_glt,#mutant_g0,#g0_bred,#num_mutant_f1,glt_primary_allele\n")
process_data.each do |key, data2|
  founder_data = data2['founder_info']
  data2.delete('founder_info')
  i = 0
  num_of_genes = data2.keys.count

  data2.each do |gene, gene_data|
    if i == 0
      file.write "#{get_data(gene_data, founder_data, num_of_genes)}\n"
    else
      file.write "#{get_data(gene_data, nil, num_of_genes)}\n"
    end
    i+=1
  end
end

