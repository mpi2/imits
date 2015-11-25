namespace :genbank_files do

  desc 'Save all Allele Genbank File Collections. This will store all Genbank files and image in the database'
  task 'update' => [:environment] do
     AlleleGenebankFileCollection.all.each{|g| g.save}
  end
end

end