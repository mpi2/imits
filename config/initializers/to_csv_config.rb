ActionController::Renderers.add :csv do |csv, options|
  self.content_type ||= Mime::CSV
  self.response_body  = csv.respond_to?(:to_csv) ? csv.to_csv : csv
end

# Ruport CSV 1.9.2 monkey patch...

require 'ruport'

module Ruport
  class Formatter::CSV < Formatter
    def csv_writer
      @csv_writer ||= options.formatter ||
        FCSV.instance(output, options.format_options || {})
    end
  end
end
