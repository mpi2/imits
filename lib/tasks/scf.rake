
namespace :scf do

  desc 'run the scf process'
  task 'run', [:force] => :environment do |t, args|
    args.with_defaults(:force => false)
    options = {}
    options = { :force => true } if ! args[:force].blank?

    Colony.all.each do |colony|
      colony.crispr_damage_analysis options
    end

  end

end