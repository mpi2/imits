
namespace :scf do

  desc 'run the scf process'
  task :run => [:environment] do

    Colony.all.each do |colony|
      # TODO: get these params inside call?
      #colony.scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1})
      #colony.scf({ :start => 139237069, :end => 139237133, :chr => 1, :strand => -1})
      colony.scf
      #colony.scf({ :start => 139237069, :end => 139237133})
    end

  end

end