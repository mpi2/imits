require "#{Rails.root}/script/reconcile_phenotype_attempt_distribution_centres.rb"

namespace :reconcile_phenotype_attempt_distribution_centres do
  desc 'Reconcile Phenotype Attempt Distribution Centres in Imits'
  # recognises 'KOMP Repo', 'EMMA' or 'MMRRC' for repository name
  task 'run', [:respository_name, :check_reconciled, :results_csv_filepath] => [:environment] do |t, args|
    # defaults for repository name, check reconciled flag, and csv results filepath
    args.with_defaults(
        :respository_name     => 'KOMP Repo',
        :check_reconciled     => 'false',
        :results_csv_filepath => "#{Rails.application.config.paths['tmp'].first}/reports/reconcile_stats/phenotype_attempt_komp_results.csv"
    )
    # create instance of reconcile class and run it
    ReconcilePhenotypeAttemptDistributionCentres.new(args[:respository_name], args[:check_reconciled], args[:results_csv_filepath]).reconcile_all_phenotype_attempt_distribution_centres
  end
end