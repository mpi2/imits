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
