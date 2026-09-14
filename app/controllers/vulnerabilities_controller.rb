class VulnerabilitiesController < ApplicationController
  include Sortable

  SORTABLE_COLUMNS = {
    "title" => "vulnerabilities.title",
    "severity" => "vulnerabilities.severity_rank",
    "cvss" => "vulnerabilities.cvss_score",
    "has_exploits" => "vulnerabilities.has_exploits",
    "affected_assets" => "findings_count"
  }.freeze
  DEFAULT_SORT_COLUMN = "cvss"
  DEFAULT_SORT_DIRECTION = "desc"

  def index
    @vulnerabilities = Vulnerability
      .left_joins(:findings)
      .select("vulnerabilities.*, COUNT(findings.id) AS findings_count")
      .group("vulnerabilities.id")
      .order(sort_order)
  end

  def show
    @vulnerability = Vulnerability.find(params[:id])
    @findings = @vulnerability.findings.includes(:asset).order(due_date: :asc)
  end
end
