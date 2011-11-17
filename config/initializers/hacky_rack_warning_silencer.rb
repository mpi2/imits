
if Rails.env.test? 
  module Rack
    module Utils
      def escape(s)
        URI.escape(s)
      end
    end
  end
end
