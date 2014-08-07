
namespace :scf do

  desc 'run the scf process'
  task 'run', [:force] => :environment do |t, args|
    args.with_defaults(:force => false)
    options = {}
    options = { :force => true } if args[:force]

    #puts "#### options:"
    #pp options

    Colony.all.each do |colony|
      colony.scf options
    end

  end

end