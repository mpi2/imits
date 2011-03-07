# encoding: utf-8

module MiAttemptsHelper

  class InnerGrid < Netzke::Basepack::GridPanel

    EMMA_OPTIONS = {
      :unsuitable => 'Unsuitable for EMMA',
      :suitable => 'Suitable for EMMA',
      :suitable_sticky => 'Suitable for EMMA - STICKY',
      :unsuitable_sticky => 'Unsuitable for EMMA - STICKY',
    }

    REVERSE_EMMA_OPTIONS = EMMA_OPTIONS.invert

    def self.emma_status_column_options
      return {
        :name => :emma_status,
        :header => 'EMMA Status',
        :editable => true,
        :getter => lambda { |relation| EMMA_OPTIONS[relation.emma_status] },
        :setter => lambda { |relation, value| relation.emma_status = REVERSE_EMMA_OPTIONS[value] },
        :width => 175,
        :editor => {
          :mode => :local,
          :store => EMMA_OPTIONS.values,
          :editable => false,
          :xtype => :combo,
          :force_selection => true,
          :trigger_action => :all,
        },
      }
    end

    def self.distribution_centre_name_column_options
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
      }
    end

    def configuration
      config_up_to_now = super
      search_terms = config_up_to_now.delete(:search_terms)
      config_up_to_now.merge(
        :model => 'MiAttempt',

        :border => true,
        :header => false,

        :clicks_to_edit => 1,
        :rows_per_page => 100,

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

          self.class.distribution_centre_name_column_options,

          self.class.emma_status_column_options,
        ],
        :prohibit_create => true,
        :prohibit_delete => true,
        :enable_edit_in_form => false,
        :enable_extended_search => false,
        :scope => proc { |relation| relation.search search_terms }
      )
    end
  end

  class OuterGrid < Netzke::Basepack::Panel
    def configuration
      config_up_to_now = super
      search_terms = config_up_to_now.delete(:search_terms)
      config_up_to_now.merge(
        :name => :micro_injection_attempts_outer,
        :layout => :fit,
        :title => 'Micro-Injection Attempts',
        :items => [
          { :name => :micro_injection_attempts,
            :class_name => 'MiAttemptsHelper::InnerGrid',
            :search_terms => search_terms
          }
        ]
      )
    end

    js_method(:on_render, <<-JS)
      function(container) {
        Ext.EventManager.onWindowResize(this.doLayout, this);
        #{js_full_class_name}.superclass.onRender.call(this, container);
      }
    JS
  end

  def mi_attempts_table(search_terms)
    netzke(:micro_injection_attempts_outer,
      :class_name => 'MiAttemptsHelper::OuterGrid',
      :search_terms => search_terms)
  end
end
