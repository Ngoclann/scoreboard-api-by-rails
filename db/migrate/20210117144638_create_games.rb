class CreateGames < ActiveRecord::Migration[6.1]
  def up
    create_table :games do |t|
      t.bigint :player1
      t.bigint :player2
      t.bigint :winner
      t.boolean :isPlaying
      t.timestamps
    end

    add_foreign_key :games, :players, column: :player1, primary_key: 'id'
    add_foreign_key :games, :players, column: :player2, primary_key: 'id'
  end

  def down
    drop_table :games
  end
end
