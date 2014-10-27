require "#{Rails.root}/script/reconcile_mi_attempt_distribution_centres.rb"

namespace :reconcile_mi_attempt_distribution_centres do

  desc 'Reconcile Mi Attempt Distribution Centres in Imits'
  task 'run', [:respository_name] => [:environment] do |t, args|
    args.with_defaults(:respository_name => 'KOMP Repo') # default for repository name
    ReconcileMiAttemptDistributionCentres.new(args[:respository_name]).reconcile_all_mi_attempt_distribution_centres
  end
end