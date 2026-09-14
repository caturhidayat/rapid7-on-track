class VulnerabilitiesController < ApplicationController
  def index
    @vulnerabilities = Vulnerability.order(cvss_score: :desc)
  end

  def show
    @vulnerability = Vulnerability.find(params[:id])
    @findings = @vulnerability.findings.includes(:asset).order(due_date: :asc)
  end
end
