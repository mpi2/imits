#encoding: utf-8

Factory.define :pipeline do |pipeline|
  pipeline.sequence(:name) { |n| "Auto-generated Pipeline Name #{n}" }
  pipeline.description 'Pipeline Description'
end

Factory.define :clone do |clone|
  clone.sequence(:clone_name) {|n| "Auto-generated Clone Name #{n}" }
  clone.marker_symbol "Auto-generated Marker Symbol"
  clone.allele_name_superscript_template "Auto-generated Allele Name Superscript Template"
  clone.association :pipeline
end

Factory.define :centre do |centre|
  centre.sequence(:name) {|n| "Auto-generated Centre Name #{n}" }
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :clone
  mi_attempt.production_centre { Centre.all.sample }
end

#Specifics

Factory.define :populated_clone, :parent => :clone do |clone|
  clone.marker_symbol { (1..4).map { ('a'..'z').to_a.sample }.push((1..9).to_a.sample).join.capitalize }
  clone.allele_name_superscript_template 'tm1@(EUCOMM)Wtsi'
  clone.allele_type { ('a'..'e').to_a.sample }
end

Factory.define :populated_mi_attempt, :parent => :mi_attempt do |mi_attempt|
  mi_attempt.blast_strain { Strain::BlastStrain.all.sample }
  mi_attempt.test_cross_strain { Strain::TestCrossStrain.all.sample }
  mi_attempt.colony_background_strain { Strain::ColonyBackgroundStrain.all.sample }
  mi_attempt.colony_name { 'Auto-generated Colony Name' }

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
    mi_attempt.send(column_name) { QcStatus.all.sample }
  end
end

Factory.define :clone_EPD0127_4_E01, :parent => :clone do |clone|
  clone.clone_name 'EPD0127_4_E01'
  clone.marker_symbol 'Trafd1'
  clone.allele_name_superscript 'tm1a(EUCOMM)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'EUCOMM' }

  clone.after_create do |clone|
    Factory.create(:populated_mi_attempt,
      :clone => clone,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:populated_mi_attempt,
      :clone => clone,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:populated_mi_attempt,
      :clone => clone,
      :colony_name => 'WBAA',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'))
  end
end

Factory.define :clone_EPD0343_1_H06, :parent => :clone do |clone|
  clone.clone_name 'EPD0343_1_H06'
  clone.marker_symbol 'Myo1c'
  clone.allele_name_superscript 'tm1a(EUCOMM)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'EUCOMM' }

  clone.after_create do |clone|
    Factory.create(:populated_mi_attempt,
      :clone => clone,
      :colony_name => 'MDCF',
      :distribution_centre => Centre.find_by_name!('WTSI'),
      :production_centre => Centre.find_by_name!('WTSI'))
  end
end

Factory.define :clone_EPD0029_1_G04, :parent => :clone do |clone|
  clone.clone_name 'EPD0029_1_G04'
  clone.marker_symbol 'Gatc'
  clone.allele_name_superscript 'tm1a(KOMP)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'KOMP' }

  clone.after_create do |clone|
    Factory.create(:populated_mi_attempt,
      :clone => clone,
      :colony_name => 'MBFD',
      :distribution_centre => Centre.find_by_name!('WTSI'),
      :production_centre => Centre.find_by_name!('WTSI'))
  end
end
