class AddCreditedTo < ActiveRecord::Migration

  def self.up
    add_column :mi_attempts, :accredited_to_id, :integer
    add_column :mouse_allele_mods, :accredited_to_id, :integer
    add_column :phenotyping_productions, :accredited_to_id, :integer

    sql = <<-EOF
      UPDATE mi_attempts SET accredited_to_id = mi_plan_id;

      UPDATE mouse_allele_mods SET accredited_to_id = mi_plan_id;

      UPDATE phenotyping_productions SET accredited_to_id = mi_plan_id;
    EOF

    ActiveRecord::Base.connection.execute(sql)
   end

   def self.down
     remove_column :mi_attempts, :accredited_to_id
     remove_column :mouse_allele_mods, :accredited_to_id
     remove_column :phenotyping_productions, :accredited_to_id
   end
end
