require '/Users/pm9/workspace/imits_development/imits_test/script/scratch/extract_jax_allele_data.rb'
d = ExtractJaxAlleleData.new
d.extract_additional_mutations
a=d.not_matched_additional_mutations



require '/Users/pm9/workspace/imits_development/imits_test/script/scratch/extract_jax_allele_data.rb'
d = ExtractJaxAlleleData.new
d.extract_main_mutations
d.convert_main_mutation_to_allele_annotation
d.extract_additional_mutations
d.convert_additional_mutation_rule1_to_allele_annotation
d.convert_additional_mutation_rule2_to_allele_annotation
d.convert_additional_mutation_rule3_to_allele_annotation

d.add_allele_annotations_to_imits


a = d.not_matched
d.allele_annotation[][259383]