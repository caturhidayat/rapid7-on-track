class CsvImportsController < ApplicationController
  def index
    @csv_imports = CsvImport.order(created_at: :desc)
  end

  def create
    unless params[:file].present?
      redirect_to csv_imports_path, alert: "Please choose a CSV file to upload."
      return
    end

    result = Rapid7CsvImporter.new(params[:file], user: Current.user).call

    if result.errors.any?
      redirect_to csv_imports_path, alert: "Import failed: #{result.errors.first}"
    else
      redirect_to csv_imports_path, notice: "Imported #{result.rows_processed} rows from #{result.csv_import.filename}."
    end
  end
end
