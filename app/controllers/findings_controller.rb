class FindingsController < ApplicationController
  def index
    @findings = Finding.includes(:asset, :vulnerability).order(due_date: :asc)
    @findings = @findings.joins(:vulnerability).where(vulnerabilities: { severity: params[:severity] }) if params[:severity].present?
    @findings = @findings.past_due if params[:past_due] == "true"
    @findings = @findings.page(params[:page]) if @findings.respond_to?(:page)
  end
end
