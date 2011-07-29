#encoding: utf-8

Factory.define :user do |user|
  user.sequence(:email) { |n| "user#{n}@example.com" }
  user.password 'password'
  user.production_centre { Centre.find_by_name('WTSI') }
end

Factory.define :pipeline do |pipeline|
  pipeline.sequence(:name) { |n| "Auto-generated Pipeline Name #{n}" }
  pipeline.description 'Pipeline Description'
end

Factory.define :gene do |gene|
  gene.sequence(:marker_symbol) { |n| "Auto-generated Symbol #{n}" }
  gene.sequence(:mgi_accession_id) { |n| "MGI:#{"%.10i" % n}" }
end

Factory.define :es_cell do |es_cell|
  es_cell.sequence(:name) { |n| "Auto-generated ES Cell Name #{n}" }
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.association(:pipeline) { Pipeline.find_by_name! 'EUCOMM' }
  es_cell.association(:gene)
end

Factory.define :centre do |centre|
  centre.sequence(:name) { |n| "Auto-generated Centre Name #{n}" }
end

Factory.define :consortium do |consortium|
  consortium.sequence(:name) { |n| "Auto-generated Consortium Name #{n}" }
end

Factory.define :mi_plan do |mi_plan|
  mi_plan.association(:gene)
  mi_plan.association(:consortium)
  mi_plan.mi_plan_status   { MiPlanStatus.find_by_name! 'Interest' }
  mi_plan.mi_plan_priority { MiPlanPriority.find_by_name! 'High' }
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :es_cell
  mi_attempt.production_centre { Centre.find_by_name('WTSI') }
  mi_attempt.consortium { Consortium.find_by_name('EUCOMM-EUMODIC') }
end

Factory.define :randomly_populated_gene, :parent => :gene do |gene|
  gene.marker_symbol { (1..4).map { ('a'..'z').to_a.sample }.push((1..9).to_a.sample).join.capitalize }
end

Factory.define :randomly_populated_es_cell, :parent => :es_cell do |es_cell|
  es_cell.allele_symbol_superscript_template 'tm1@(EUCOMM)Wtsi'
  es_cell.allele_type { ('a'..'e').to_a.sample }
  es_cell.association :gene, :factory => :randomly_populated_gene
end

Factory.define :randomly_populated_mi_attempt, :parent => :mi_attempt do |mi_attempt|
  mi_attempt.blast_strain { Strain::BlastStrain.all.sample }
  mi_attempt.test_cross_strain { Strain::TestCrossStrain.all.sample }
  mi_attempt.production_centre { Centre.all.sample }
  mi_attempt.distribution_centre { Centre.all.sample }
  mi_attempt.colony_background_strain { Strain::ColonyBackgroundStrain.all.sample }
  mi_attempt.colony_name { (1..4).to_a.map { ('A'..'Z').to_a.sample }.join }
  mi_attempt.mi_attempt_status { MiAttemptStatus.all.sample }

  MiAttempt.columns.each do |column|
    next if ['id', 'created_at', 'updated_at'].include?(column.name.to_s)
    next if column.name.match(/_id$/)

    if column.type == :integer
      mi_attempt.send(column.name) { rand(20) }
    elsif column.type == :date
      mi_attempt.send(column.name) { Date.today.beginning_of_month + rand(29).days }
    elsif column.type == :boolean
      mi_attempt.send(column.name) { [true, false].sample }
    end
  end

  MiAttempt::QC_FIELDS.each do |column_name|
    mi_attempt.send(column_name) { QcResult.all.sample }
  end
end

#Specifics

Factory.define :gene_cbx1, :parent => :gene do |gene|
  gene.marker_symbol 'Cbx1'
  gene.mgi_accession_id 'MGI:105369'
end

Factory.define :gene_trafd1, :parent => :gene do |gene|
  gene.marker_symbol 'Trafd1'
  gene.mgi_accession_id 'MGI:1923551'
end

Factory.define :es_cell_EPD0127_4_E01_without_mi_attempts, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0127_4_E01'
  es_cell.association(:gene, :factory => :gene_trafd1)
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :es_cell_EPD0127_4_E01, :parent => :es_cell_EPD0127_4_E01_without_mi_attempts do |es_cell|
  es_cell.after_create do |es_cell|
    Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'),
      :emma_status => 'unsuitable_sticky')

    Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'WBAA',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'))
  end
end

Factory.define :es_cell_EPD0343_1_H06_without_mi_attempts, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0343_1_H06'
  es_cell.association :gene, :marker_symbol => 'Myo1c'
  es_cell.allele_symbol_superscript 'tm1a(EUCOMM)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :es_cell_EPD0343_1_H06, :parent => :es_cell_EPD0343_1_H06_without_mi_attempts do |es_cell|
  es_cell.after_create do |es_cell|
    Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MDCF',
      :distribution_centre => Centre.find_by_name!('WTSI'),
      :production_centre => Centre.find_by_name!('WTSI'),
      :mi_date => Date.parse('2010-09-13'))
  end
end

Factory.define :es_cell_EPD0029_1_G04, :parent => :es_cell do |es_cell|
  es_cell.name 'EPD0029_1_G04'
  es_cell.association :gene, :marker_symbol => 'Gatc'
  es_cell.allele_symbol_superscript 'tm1a(KOMP)Wtsi'
  es_cell.pipeline { Pipeline.find_by_name! 'KOMP' }

  es_cell.after_create do |es_cell|
    Factory.create(:mi_attempt,
      :es_cell => es_cell,
      :colony_name => 'MBFD',
      :distribution_centre => Centre.find_by_name!('WTSI'),
      :production_centre => Centre.find_by_name!('WTSI'))
  end
end
