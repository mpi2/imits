require "#{Rails.root}/script/update_real_alleles.rb"

namespace :update_real_alleles do

  desc 'Update Real Alleles in Imits'
  task 'run' => [:environment] do
     UpdateRealAlleles.new.run
  end
end