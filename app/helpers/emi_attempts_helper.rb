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

          { :name => :actual_mi_date,
            :header => 'Actual MI Date',
            :read_only => true,
            :renderer => ['date', 'd-M-Y'],
          },

          {:name => :colony_name, :header => 'Colony Name', :read_only => true},

          { :name => :distribution_centre_name,
            :id => 'distribution_centre_name',
            :header => 'Distribution Centre',
            :setter => lambda {|mi_attempt, centre_name| mi_attempt.set_distribution_centre_by_name centre_name },
            :editable => true,
            :editor => {
              :store => Centre.all.collect(&:name),
              :editable => false,
              :xtype => :combo,
              :force_selection => true,
              :trigger_action => :all,
            }
          },

          { :name => :emma_status,
            :header => 'EMMA Status',
            :editable => true,
            :editor => {
              :store => ['force_off', 'force_on', 'on', 'off'],
              :editable => false,
              :xtype => :combo,
              :force_selection => true,
              :trigger_action => :all,
            }
          },
        ],
        :prohibit_create => true,
        :prohibit_delete => true,
        :enable_edit_in_form => false,
        :enable_extended_search => false,
        :scope => [:by_clone_names, clone_names]
      )
    end
  end

  def emi_attempts_table(clone_names)
    netzke(:micro_injection_attempts, :class_name => "EmiAttemptsHelper::Grid",
      :clone_names => clone_names)
  end
end
