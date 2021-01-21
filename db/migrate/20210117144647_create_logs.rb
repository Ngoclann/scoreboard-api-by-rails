class CreateLogs < ActiveRecord::Migration[6.1]
  def up
    create_table :logs do |t|
      t.integer :point1
      t.integer :point2
      t.bigint :gameid
      t.boolean :isP1LastPoint
      t.boolean :isP2LastPoint
      t.timestamps
    end

    add_foreign_key :logs, :games, column: :gameid, primary_key: 'id'
  end

  def down
    drop_table :logs
  end
end
