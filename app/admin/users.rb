# Export to CSV with the referrer_id
ActiveAdmin.register User do
  csv do
    column :id
    column :email
    column :referral_code
    column :referred
    column :created_at
    column :updated_at
  end

  actions :index, :show
  
end
