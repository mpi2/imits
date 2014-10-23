require "#{Rails.root}/script/reconcile_phenotype_attempt_distribution_centres.rb"

namespace :reconcile_phenotype_attempt_distribution_centres do

  desc 'Reconcile Phenotype Attempt Distribution Centres in Imits'
  task 'run', [:respository_name] => [:environment] do |t, args|
    args.with_defaults(:respository_name => 'KOMP Repo') # default for repository name
    ReconcilePhenotypeAttemptDistributionCentres.new(args[:respository_name]).reconcile_all_phenotype_attempt_distribution_centres
  end
end