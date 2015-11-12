require "#{Rails.root}/script/mgi/allele_name_update.rb"

namespace :update_es_cell_alleles do

  desc 'Use MGI downloads to update ES Cell allele name and ids in Imits'
  task 'update' => [:environment] do
     MgiAlleleNameUpdate.new.es_cell_update
  end
end

namespace :update_derived_mice_alleles do

  desc 'Use MGI downloads to update Derived Mice allele name and ids in Imits'
  task 'update' => [:environment] do
     MgiAlleleNameUpdate.new.derived_mice_update
  end
end

namespace :update_mixed_allele_mice_alleles do

  desc 'Use MGI downloads to update Mixed Allele Mice allele name and ids in Imits'
  task 'update' => [:environment] do
     MgiAlleleNameUpdate.new.mixed_allele_mice_update
  end
end

namespace :update_crispr_mice_alleles do

  desc 'Use MGI downloads to update CRISPR Mice allele name and ids in Imits'
  task 'update' => [:environment] do
     MgiAlleleNameUpdate.new.crispr_mice_update
  end
end