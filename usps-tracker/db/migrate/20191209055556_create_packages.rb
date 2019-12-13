class CreatePackages < ActiveRecord::Migration[5.2]
  def change
    create_table :packages do |t|
      t.integer :status
      t.string :tracking_number
      t.string :delivered_location
      t.datetime :delivery_from
      t.datetime :delivery_to
      t.timestamps
    end
  end
end
