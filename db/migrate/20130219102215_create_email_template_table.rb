class CreateEmailTemplateTable < ActiveRecord::Migration
  def up
    create_table :email_templates do |t|
      t.string :status
      t.text :welcome_body
      t.text :update_body

      t.timestamps
    end
  end

  def down
    drop_table :email_templates
  end
end
