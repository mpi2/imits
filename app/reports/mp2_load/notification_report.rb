class Mp2Load::NotificationReport

  attr_accessor :notifications

  def notifications
    @gene_statues ||= ActiveRecord::Base.connection.execute(self.class.notification_sql)
  end

  def process_data(data)
    process_data = []

    data.each do |row|
      processed_row = row.dup
      process_data << processed_row
    end

    return process_data
  end
  private :process_data

  class << self

    def show_columns
      [{'title' => 'mgi_accession_id', 'field' => 'mgi_accession_id'},
       {'title' => 'marker_symbol', 'field' => 'marker_symbol'},
       {'title' => 'email', 'field' => 'email'},
       {'title' => 'gene_contact_created_at', 'field' => 'gene_contact_created_at'},
       {'title' => 'contact_created_at', 'field' => 'contact_created_at'}
       ]
    end

    def notification_sql
      <<-EOF
        SELECT genes.mgi_accession_id AS mgi_accession_id, genes.marker_symbol AS marker_symbol, notifications.created_at AS gene_contact_created_at,
               contacts.email AS email, contacts.created_at AS contact_created_at
        FROM notifications
          JOIN genes ON genes.id = notifications.gene_id
          JOIN contacts ON contacts.id = notifications.contact_id
      EOF
    end
  end

end