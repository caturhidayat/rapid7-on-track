FactoryBot.define do
  factory :finding do
    association :asset
    association :vulnerability
    association :csv_import
    status { "open" }
    instance_count { 1 }
    past_due { false }
    due_date { 1.week.from_now }
  end
end
