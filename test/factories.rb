#encoding: utf-8

Factory.define :pipeline do |pipeline|
  pipeline.sequence(:name) { |n| "Auto-generated Pipeline Name #{n}" }
  pipeline.description 'Pipeline Description'
end

Factory.define :clone do |clone|
  clone.sequence(:clone_name) {|n| "Auto-generated Clone Name #{n}" }
  clone.marker_symbol "Auto-generated Marker Symbol"
  clone.allele_name_superscript "Auto-generated Allele Name Superscript"
  clone.association :pipeline
end

Factory.define :centre do |centre|
  centre.sequence(:name) {|n| "Auto-generated Centre Name #{n}" }
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :clone
end


# Specifics
Factory.define :clone_EPD0127_4_E01, :parent => :clone do |clone|
  clone.clone_name 'EPD0127_4_E01'
  clone.marker_symbol 'Trafd1'
  clone.allele_name_superscript 'tm1a(EUCOMM)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'EUCOMM' }

  clone.after_create do |clone|
    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MBSS',
      :distribution_centre => Centre.find_by_name!('ICS'),
      :is_suitable_for_emma => true)

    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'WBAA',
      :distribution_centre => Centre.find_by_name!('ICS'))
  end
end

Factory.define :clone_EPD0343_1_H06, :parent => :clone do |clone|
  clone.clone_name 'EPD0343_1_H06'
  clone.marker_symbol 'Myo1c'
  clone.allele_name_superscript 'tm1a(EUCOMM)Wtsi'
  clone.pipeline { Pipeline.find_by_name! 'EUCOMM' }

  clone.after_create do |clone|
    Factory.create(:mi_attempt,
      :clone => clone,
      :colony_name => 'MDCF',
      :distribution_centre => Centre.find_by_name!('WTSI'))
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
      :distribution_centre => Centre.find_by_name!('WTSI'))
  end
end
