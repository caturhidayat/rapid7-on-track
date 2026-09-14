class FindingsController < ApplicationController
  include Sortable

  SORTABLE_COLUMNS = {
    "asset" => "assets.hostname",
    "vulnerability" => "vulnerabilities.title",
    "severity" => "vulnerabilities.severity_rank",
    "cvss" => "vulnerabilities.cvss_score",
    "due_date" => "findings.due_date",
    "past_due" => "findings.past_due",
    "status" => "findings.status"
  }.freeze
  DEFAULT_SORT_COLUMN = "due_date"
  DEFAULT_SORT_DIRECTION = "asc"

  def index
    @findings = Finding.eager_load(:asset, :vulnerability)
    @findings = @findings.where(vulnerabilities: { severity: params[:severity] }) if params[:severity].present?
    @findings = @findings.past_due if params[:past_due] == "true"
    @findings =
      case params[:status]
      when "closed" then @findings.closed
      when "all" then @findings
      else @findings.open
      end
    @findings = @findings.order(sort_order)
  end
end
