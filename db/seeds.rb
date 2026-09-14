# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Default IT admin account for initial deploy. Only created if it doesn't exist yet,
# so re-running seeds never resets a password the admin has already changed.
User.find_or_create_by!(email_address: "itadmin@email.com") do |user|
  user.password = "itadmin"
  user.password_confirmation = "itadmin"
end
