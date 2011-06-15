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

Factory.define :clone do |clone|
  clone.sequence(:clone_name) {|n| "Auto-generated Clone Name #{n}" }
  clone.marker_symbol "Auto-generated Marker Symbol"
  clone.allele_name_superscript 'tm1a(AUTO)Generated'
  clone.association :pipeline
  clone.sequence(:mgi_accession_id) {|n| "MGI:#{"%.10i" % n}"}
  clone.is_in_targ_rep true
end

Factory.define :centre do |centre|
  centre.sequence(:name) {|n| "Auto-generated Centre Name #{n}" }
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :clone
  mi_attempt.production_centre { Centre.find_by_name('WTSI') }
end

Factory.define :randomly_populated_clone, :parent => :clone do |clone|
  clone.marker_symbol { (1..4).map { ('a'..'z').to_a.sample }.push((1..9).to_a.sample).join.capitalize }
  clone.allele_name_superscript_template 'tm1@(EUCOMM)Wtsi'
  clone.allele_type { ('a'..'e').to_a.sample }
end

Factory.define :randomly_populated_mi_attempt, :parent => :mi_attempt do |mi_attempt|
  mi_attempt.blast_strain { Strain::BlastStrain.all.sample }
  mi_attempt.test_cross_strain { Strain::TestCrossStrain.all.sample }
  mi_attempt.production_centre { Centre.all.sample }
  mi_attempt.distribution_centre { Centre.all.sample }
  mi_attempt.colony_background_strain { Strain::ColonyBackgroundStrain.all.sample }
  mi_attempt.colony_name { ['MABR', 'MANB', 'MCCU', 'APCM', 'MBGY'].sample }
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
    mi_attempt.send(column_name) { QcStatus.all.sample }
  end
end

#Specifics

Factory.define :clone_EPD0127_4_E01_without_mi_attempts, :parent => :clone do |clone|
  clone.clone_name 'EPD0127_4_E01'
  clone.marker_symbol 'Trafd1'
  clone.allele_name_superscript 'tm1a(EUCOMM)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :clone_EPD0127_4_E01, :parent => :clone_EPD0127_4_E01_without_mi_attempts do |clone|
  clone.after_create do |clone|
    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'WBAA',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :production_centre => Centre.find_by_name!('ICS'))
  end
end

Factory.define :clone_EPD0343_1_H06_without_mi_attempts, :parent => :clone do |clone|
  clone.clone_name 'EPD0343_1_H06'
  clone.marker_symbol 'Myo1c'
  clone.allele_name_superscript 'tm1a(EUCOMM)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'EUCOMM' }
end

Factory.define :clone_EPD0343_1_H06, :parent => :clone_EPD0343_1_H06_without_mi_attempts do |clone|
    clone.after_create do |clone|
    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MDCF',
      :distribution_centre => Centre.find_by_name!('WTSI'),
      :production_centre => Centre.find_by_name!('WTSI'),
      :mi_date => Date.parse('2010-09-13'))
  end
end

Factory.define :clone_EPD0029_1_G04, :parent => :clone do |clone|
  clone.clone_name 'EPD0029_1_G04'
  clone.marker_symbol 'Gatc'
  clone.allele_name_superscript 'tm1a(KOMP)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'KOMP' }

  clone.after_create do |clone|
    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MBFD',
      :distribution_centre => Centre.find_by_name!('WTSI'),
      :production_centre => Centre.find_by_name!('WTSI'))
  end
end
