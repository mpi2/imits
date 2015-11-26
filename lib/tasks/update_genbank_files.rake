namespace :genbank_files do

  desc 'Save all Allele Genbank File Collections. This will store all Genbank files and image in the database'
  task 'update' => [:environment] do
    n = 0
    while n < 10
      TargRep::AllelesGenbankFileCollection.joins('LEFT JOIN targ_rep_genbank_files ON targ_rep_genbank_files.genbank_file_collection_id = targ_rep_alleles_genbank_file_collections.id').where('targ_rep_genbank_files.id IS NOT NULL').order('id').limit(1000).offset(0) do |g|
        begin
          if g.valid?
            puts "Saving Genbank Collection ID: #{g.id}"
            g.save
          else
            puts "Invalid Genbank Collection ID: #{g.id}"
          end
        rescue
          puts "ERROR: Genbank Collection raised error ID: #{g.id}"
        end
      end
      n += 1
    end
  end
end
