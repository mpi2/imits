rake db:migrate

# dump targeting vector genbank files fro 9.3 postgres database
\COPY (SELECT gb.allele_id, gb.created_at, gb.updated_at, gb.file_gb FROM targ_rep_genbank_files gb JOIN targ_rep_alleles a ON a.vector_genbank_file_id = gb.id) TO 'tv_genbank_files.copy'

  
# add column to postgres database 9.5
  ALTER TABLE targ_rep_genbank_files ADD COLUMN allele_id integer;

# remove targeting_vector_ids from allele table
  UPDATE targ_rep_alleles SET vector_genbank_file_id = NULL WHERE vector_genbank_file_id IS NOT NULL;
  
# delete genbank files that are not linked to the allele table
  DELETE FROM targ_rep_genbank_files 
  WHERE targ_rep_genbank_files.id IN (
    SELECT gb2.id FROM targ_rep_genbank_files gb2 
      LEFT JOIN targ_rep_alleles a ON gb2.id = a.allele_genbank_file_id
      LEFT JOIN targ_rep_alleles tv_a ON gb2.id = tv_a.vector_genbank_file_id
    WHERE a.id IS NULL AND tv_a.id IS NULL
    );


#insert data from file 
  \COPY targ_rep_genbank_files (allele_id, created_at, updated_at, file_gb) FROM 'tv_genbank_files.copy';

#delete tv genbank files for alleles that do not have tvs and mutation type = Targeted Non Conditional 
  DELETE FROM targ_rep_genbank_files
  WHERE targ_rep_genbank_files.id IN (
    SELECT gb2.id 
    FROM targ_rep_genbank_files gb2
      JOIN targ_rep_alleles a ON a.id = gb2.allele_id
      JOIN targ_rep_mutation_types m ON m.id = a.mutation_type_id
      LEFT JOIN targ_rep_targeting_vectors tv ON tv.allele_id = a.id
    WHERE m.name = 'Targeted Non Conditional' AND tv.id IS NULL
  );


#update ids in allele table
  UPDATE targ_rep_alleles SET vector_genbank_file_id = targ_rep_genbank_files.id
    FROM targ_rep_genbank_files
    WHERE targ_rep_genbank_files.allele_id = targ_rep_alleles.id;


#drop allele_id column in genbank table
  ALTER TABLE targ_rep_genbank_files DROP COLUMN allele_id RESTRICT;