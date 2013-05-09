## Independent log for debugging the NewIntermediateReport::Generate
INTERMEDIATE_REPORT_LOG = ActiveSupport::BufferedLogger.new(TarMits::Application.config.paths['intermediate_report_log'].first)