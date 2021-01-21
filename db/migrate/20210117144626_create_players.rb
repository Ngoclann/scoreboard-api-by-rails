class CreatePlayers < ActiveRecord::Migration[6.1]
  def up
    create_table :players do |t|
      t.string :name
      t.string :username
      t.string :password
      t.bigint :point
      t.integer :wincount
      t.integer :losecount
      t.boolean :isLogin
      t.boolean :isAdmin
    end
  end

  def down
    drop_table :players
  end
end
