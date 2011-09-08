require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  context 'ApplicationController' do

    context '#params_cleaned_for_search' do
      should 'get back all params except controller, action, format and page' do
        dirty_params = {
          'controller' => 'blank',
          'action' => 'blank',
          'format' => 'blank',
          'page' => 'blank',
          :per_page => 'blank',
          :utf8 => 'blank',
          '_dc' => 'blank',

          :search => 'blank',
          'submit' => 'blank'
        }

        assert_equal({'search' => 'blank', 'submit' => 'blank'},
          @controller.send(:params_cleaned_for_search, dirty_params))
      end

      should 'convert symbol keys to strings' do
        assert_equal({'search' => 'blank', 'submit' => 'blank'},
          @controller.send(:params_cleaned_for_search, {:search => 'blank', :submit => 'blank'}))
      end

      should 'not touch passed in argument' do
        frozen_params = {'search' => 'blank', 'utf8' => 'blank'}.freeze
        @controller.send(:params_cleaned_for_search, frozen_params)
      end

      should 'process the "q" sub-hash' do
        dirty_params = {
          'controller' => 'blank',
          'submit' => 'blank',
          :q => {
            'attr1_eq' => 'blank',
            :attr2_eq => 'blank'
          }
        }

        assert_equal({'submit' => 'blank', 'attr1_eq' => 'blank', 'attr2_eq' => 'blank'},
          @controller.send(:params_cleaned_for_search, dirty_params))
      end
    end

  end
end
