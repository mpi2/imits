class SolrUpdate::CommandFactory
  def self.create_solr_command_to_update_in_index(object_id)
    mi_attempt_id = object_id['id']
    mi_attempt = MiAttempt.find(mi_attempt_id)

    solr_doc = SolrUpdate::DocFactory.create_for_mi_attempt(mi_attempt)

    commands = {
      'delete' => {'query' => "type:mi_attempt AND id:#{mi_attempt_id}"},
      'add' => [solr_doc],
      'commit' => {}
    }

    return commands.to_json
  end
end
