class InitialMigration < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name
      t.timestamps
    end

    create_table :lists do |t|
      t.string :name
      t.integer :group_id
      t.timestamps
    end

    create_join_table :lists, :users do |t|
      # t.index [:list_id, :user_id]
      # t.index [:user_id, :list_id]
    end

    create_table :groups do |t|
      t.integer :guid
      t.string :name
      t.integer :selected_list
      t.timestamps
    end

  end
end
