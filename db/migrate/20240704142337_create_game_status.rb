class CreateGameStatus < ActiveRecord::Migration[6.1]
  def change
    create_table :game_status_lists do |t|
      t.string :team_id
      t.float :distance
      t.boolean :is_clear, default: false
      t.timestamps null: false
    end
  end
end
