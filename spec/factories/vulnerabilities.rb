FactoryBot.define do
  factory :vulnerability do
    sequence(:vulnerability_uid) { |n| "vuln-uid-#{n}" }
    sequence(:title) { |n| "Sample Vulnerability #{n}" }
    severity { "Critical" }
    severity_rank { 3 }
    cvss_score { 9.8 }
    has_exploits { false }
    exploit_count { 0 }
  end
end
