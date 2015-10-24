class AddReferredToUser < ActiveRecord::Migration
  def change
    add_column :users, :referred, :integer
  end
end
