module MiAttemptsHelper

  class Grid < Netzke::Basepack::GridPanel
    def configuration
      config_up_to_now = super
      search_terms = config_up_to_now.fetch(:search_terms)
      config_up_to_now.merge(
        :model => 'MiAttempt',

        :border => true,
        :header => false,
        :view_config => {
          :force_fit => true,
        },
        :clicks_to_edit => :auto,

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
        :scope => proc { |relation| relation.search search_terms }
      )
    end
  end

  def mi_attempts_table(search_terms)
    netzke(:micro_injection_attempts, :class_name => "MiAttemptsHelper::Grid",
      :search_terms => search_terms)
  end
end
