module EmiAttemptsHelper

  class Grid < Netzke::Basepack::GridPanel
    def configuration
      config_up_to_now = super
      clone_names = config_up_to_now.fetch(:clone_names)
      config_up_to_now.merge(
        :model => 'EmiAttempt',
        :columns => [
          :clone_name,
          {:name => :gene_symbol, :header => 'Gene', :read_only => true},
          {:name => :allele_name, :header => 'Allele', :read_only => true},
          {:name => :formatted_proposed_mi_date, :header => 'Proposed MI Date', :read_only => true},
          {:name => :formatted_actual_mi_date, :header => 'Actual MI Date', :read_only => true},
          {:name => :colony_name, :header => 'Colony', :read_only => true},

          { :name => :distribution_centre,
            :header => 'Distribution Centre',
            :getter => lambda {|mi_attempt| mi_attempt.distribution_centre.name},
            #:setter => lambda {|mi_attempt, centre_name| mi_attempt.set_distribution_centre_by_name centre_name },
            :editor => {
              :store => ['WOOTSEE', 'Apple'],
              :editable => false,
              :xtype => :combo,
              :force_selection => true,
              :trigger_action => :all,
            }
          }
        ],
        #:prohibit_create => true,
        #:prohibit_delete => true,
        :enable_edit_in_form => false,
        #:enable_extended_search => false,
        :scope => [:by_clone_names, clone_names ]
      )
    end
  end

  def emi_attempts_table(clone_names)
    netzke(:micro_injection_attempts, :class_name => "EmiAttemptsHelper::Grid",
      :clone_names => clone_names)
  end
end
