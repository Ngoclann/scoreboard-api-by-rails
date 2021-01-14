class CreatePlayers < ActiveRecord::Migration[6.1]
  def change
    create_table :players do |t|
      t.string :username
      t.string :password
      t.bigint :wins_count
      t.bigint :loses_count
      t.timestamps
    end
  end
end
