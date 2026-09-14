class AssetsController < ApplicationController
  include Sortable

  SORTABLE_COLUMNS = {
    "hostname" => "assets.hostname",
    "ip_address" => "assets.ip_address",
    "operating_system" => "assets.operating_system",
    "risk_score" => "assets.risk_score",
    "critical" => "assets.critical_vulnerability_count",
    "severe" => "assets.severe_vulnerability_count",
    "moderate" => "assets.moderate_vulnerability_count"
  }.freeze
  DEFAULT_SORT_COLUMN = "risk_score"
  DEFAULT_SORT_DIRECTION = "desc"

  def index
    @assets = Asset.order(sort_order)
  end

  def show
    @asset = Asset.find(params[:id])
    @findings = @asset.findings.includes(:vulnerability).order(due_date: :asc)
  end
end
