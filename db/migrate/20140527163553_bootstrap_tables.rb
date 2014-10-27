class BootstrapTables < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'

    create_table :users, id: :uuid do |t|
      t.text :name
      t.text :email, null: false

      t.uuid :manager_user_id
      t.text :manager_email

      t.timestamps
    end

    add_index :users, :manager_user_id
    add_index :users, :email, unique: true


    create_table :metrics, id: :uuid do |t|
      t.text :name, null: false
      t.text :description, null: false
      t.integer :order
      t.boolean :active, null: false, default: true
      t.boolean :required, null: false, default: false

      t.timestamps
    end

    add_index :metrics, [:active, :required, :order]


    create_table :submissions, id: :uuid do |t|
      t.uuid :user_id
      t.foreign_key :users

      t.boolean :completed, null: false, default: false
      t.timestamp :completed_at

      t.string :comments, limit: 140

      t.timestamps
    end

    add_index :submissions, :user_id
    add_index :submissions, :created_at


    create_table :submission_metrics, id: :uuid do |t|
      t.uuid :submission_id
      t.foreign_key :submissions

      t.uuid :metric_id
      t.foreign_key :metrics

      t.integer :rating
      t.text :comments, limit: 140

      t.boolean :completed, null: false, default: false
      t.timestamp :completed_at
    end

    add_index :submission_metrics, [:submission_id, :metric_id]

  end
end
