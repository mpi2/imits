require "#{Rails.root}/script/reconcile_mi_attempt_distribution_centres.rb"

namespace :reconcile_mi_attempt_distribution_centres do

    desc 'Reconcile Mi Attempt Distribution Centres in Imits'
    # recognises 'KOMP Repo', 'EMMA' or 'MMRRC' for repository name
    task 'run', [:respository_name, :check_reconciled] => [:environment] do |t, args|
        # defaults for repository name and check reconciled flag
        args.with_defaults(:respository_name => 'KOMP Repo', :check_reconciled => 'false')

        # create instance of reconcile class and run it
        ReconcileMiAttemptDistributionCentres.new(args[:respository_name], args[:check_reconciled]).reconcile_all_mi_attempt_distribution_centres
    end
end