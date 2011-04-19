Factory.define :pipeline do |pipeline|
  pipeline.name 'Pipeline Name'
  pipeline.description 'Pipeline Description'
end

Factory.define :clone do |clone|
  clone.clone_name 'Clone Name'
  clone.marker_symbol 'Marker Symbol'
  clone.allele_name_superscript 'Allele Name Superscript'
  clone.association :pipeline
end

Factory.define :mi_attempt do |mi_attempt|
  mi_attempt.association :clone
end
