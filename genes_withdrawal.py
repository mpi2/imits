import pandas as pd

input_genes = pd.read_csv("latest_status_per_gene_all_4.csv", encoding='utf-8', error_bad_lines=False, engine='python')
input_genes.sort_values(by=['gene_name'])

genes_phenotype_complete = []

input_genes = input_genes[input_genes.latest_plan_status != 'Inactive']
input_genes = input_genes[input_genes.latest_status != 'Inactive']
input_genes = input_genes[input_genes.latest_status != 'Withdrawn']

for index, row in input_genes.iterrows():
	if row['latest_status'] == 'Phenotyping Complete':
		genes_phenotype_complete.append(row['gene_name'])


for g in genes_phenotype_complete:
	input_genes = input_genes[input_genes.gene_name != g]

input_genes = input_genes.drop_duplicates(subset=None, keep='first', inplace=False)

input_genes.to_csv("latest_status_per_gene_no_phenotype_complete_or_inactive_or_withdrawn_4.csv", index=False, encoding='utf-8')



























