# Generate schema.rb alongside development_structure.sql, so that
# editors/helpers/plugins that rely db/schema.rb can still use it,
# even though the app uses the :sql schema_format for setting up the
# test DB
task 'db:structure:dump' => ['db:schema:dump']
