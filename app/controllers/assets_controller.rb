class AssetsController < ApplicationController
  def index
    @assets = Asset.order(risk_score: :desc)
  end

  def show
    @asset = Asset.find(params[:id])
    @findings = @asset.findings.includes(:vulnerability).order(due_date: :asc)
  end
end
