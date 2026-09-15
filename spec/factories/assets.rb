FactoryBot.define do
  factory :asset do
    sequence(:asset_uid) { |n| "asset-uid-#{n}" }
    sequence(:hostname) { |n| "host-#{n}.example.local" }
    ip_address { "192.168.1.10" }
    operating_system { "Microsoft Windows 11 25H2" }
    os_family { "Windows" }
    os_vendor { "Microsoft" }
    risk_score { 1000 }
    critical_vulnerability_count { 0 }
    severe_vulnerability_count { 0 }
    moderate_vulnerability_count { 0 }
  end
end
