FactoryBot.define do
  factory :csv_import do
    association :user
    filename { "export.csv" }
    status { "completed" }
    rows_count { 0 }
  end
end
