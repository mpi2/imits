require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase
  context 'ApplicationController' do

    context '#cleaned_params' do
      should 'get back all params except controller, action, format and page' do
        @controller.params['controller'] = 'blank'
        @controller.params['action'    ] = 'blank'
        @controller.params['format'    ] = 'blank'
        @controller.params['page'      ] = 'blank'
        @controller.params['utf8'      ] = 'blank'

        @controller.params['search'    ] = 'blank'
        @controller.params['submit'    ] = 'blank'

        assert_equal({'search' => 'blank', 'submit' => 'blank'},
                @controller.send(:cleaned_params))
      end
    end

  end
end
