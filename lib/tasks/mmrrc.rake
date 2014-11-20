require "#{Rails.root}/script/make_mmrrc_reports2.rb"

namespace :mmrrc do

  desc 'run the mmrrc process'
  task 'run' => [:environment] do
    #MmrrcOriginal.new.run
    MmrrcNew.new.run
  end

  #task 'folders' => [:environment] do
  #  MmrrcNew.new.get_files
  #end

end