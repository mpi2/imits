# encoding: utf-8

module MiAttemptsHelper

  class MiAttemptsGrid < Netzke::Basepack::GridPanel

    EMMA_OPTIONS = {
      :unsuitable => 'Unsuitable for EMMA',
      :suitable => 'Suitable for EMMA',
      :suitable_sticky => 'Suitable for EMMA - STICKY',
      :unsuitable_sticky => 'Unsuitable for EMMA - STICKY',
    }

    REVERSE_EMMA_OPTIONS = EMMA_OPTIONS.invert

    action :apply do
      {
        :text => 'Save Changes',
        :icon => :tick,
        :tooltip => 'You must select this to save the changes you have made'
      }
    end

    def emma_status_column_options
      return {
        :name => :emma_status,
        :id => 'emma_status',
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

    def distribution_centre_name_column_options
      { :name => :distribution_centre_name,
        :id => 'distribution_centre_name',
        :header => 'Distribution Centre',
        :setter => lambda { |mi_attempt, centre_name|
          mi_attempt.set_distribution_centre_by_name(centre_name,
            @passed_config[:current_username])
        },
        :editable => true,
        :sortable => true,
        :sorting_scope => :sort_by_distribution_centre_name,
        :editor => {
          :store => Centre.all.collect(&:name),
          :editable => false,
          :xtype => :combo,
          :force_selection => true,
          :trigger_action => :all,
        }
      }
    end

    def define_columns
      [
        { :name => :clone_name,
          :read_only => true,
          :sortable => true,
          :sorting_scope => :sort_by_clone_name,
        },

        { :name => :gene_symbol,
          :read_only => true,
          :sortable => true,
          :sorting_scope => :sort_by_gene_symbol,
        },

        { :name => :allele_name,
          :read_only => true,
          :sortable => true,
          :sorting_scope => :sort_by_allele_name,
        },

        { :name => :actual_mi_date,
          :header => 'Actual MI Date',
          :read_only => true,
          :renderer => ['date', 'd-M-Y'],
        },

        { :name => 'status',
          :getter => proc { |relation| relation.mi_attempt_status.name },
          :sortable => true,
          :sorting_scope => :sort_by_mi_attempt_status,
        },

        { :name => :colony_name,
          :read_only => true
        },

        distribution_centre_name_column_options,

        emma_status_column_options,
      ]
    end

    js_method :on_switch_view, <<-'JS'
      function(param1, param2) {
        switchMiAttemptsGridView(param1, param2)
      }
    JS

    def self.switch_view_button(text, extra_params = {})
      return {
        :enable_toggle => true,
        :allow_depress => false,
        :toggle_group => 'mi_attempt_view_config',
        :min_width => 100,
        :text => text,
        :id => text.gsub(' ', '-').downcase + '-button',
        :handler => :on_switch_view
      }.merge(extra_params)
    end

    def switch_view_button(*args)
      self.class.switch_view_button(*args)
    end

    def view_config_buttons
      return {
        :xtype => 'buttongroup',
        :title => 'Choose a View',
        :items => [
          switch_view_button('Everything', :pressed => true),
          switch_view_button('Transfer Details'),
          switch_view_button('Litter Details'),
          switch_view_button('Chimera Mating Details'),
          switch_view_button('QC Details'),

          {
            :enable_toggle => true,
            :allow_depress => false,
            :toggle_group => 'mi_attempt_view_config',
            :min_width => 100,
            :text => 'Test Handler Event',
            :id => 'test-handler-event-button',
            :toggle_handler => :on_switch_view
          }
        ]
      }
    end

    def configuration
      super.merge(
        :model => 'MiAttempt',

        :border => true,
        :header => false,

        :clicks_to_edit => 1,
        :rows_per_page => 100,

        :tbar => [self.view_config_buttons],

        :bbar => [
          :apply.action
        ],

        :columns => self.define_columns,

        :prohibit_create => true,
        :prohibit_delete => true,
        :enable_edit_in_form => false,
        :enable_extended_search => false,
        :strong_default_attrs => {:edited_by => @passed_config[:current_username]},
        :scope => [:search, @passed_config[:search_terms]]
      )
    end
  end

  class MiAttemptsWidget < Netzke::Basepack::Panel
    def configuration
      config_up_to_now = super
      search_terms = config_up_to_now.delete(:search_terms)
      current_username = config_up_to_now.delete(:current_username)
      config_up_to_now.merge(
        :name => :micro_injection_attempts_outer,
        :layout => :fit,
        :title => 'Micro-Injection Attempts',
        :items => [
          { :name => :micro_injection_attempts,
            :class_name => 'MiAttemptsHelper::MiAttemptsGrid',
            :current_username => current_username,
            :search_terms => search_terms
          }
        ]
      )
    end
  end

  def mi_attempts_table(search_terms)
    onready = javascript_tag(<<-'EOL')
      Ext.onReady(function(){
        var outerpanel = Netzke.page.microInjectionAttemptsOuter;
        Ext.EventManager.onWindowResize(outerpanel.doLayout, outerpanel);
      });
    EOL

    netzke(:micro_injection_attempts_outer,
      :class_name => 'MiAttemptsHelper::MiAttemptsWidget',
      :current_username => current_user.user_name,
      :search_terms => search_terms) + "\n" + onready
  end
end
