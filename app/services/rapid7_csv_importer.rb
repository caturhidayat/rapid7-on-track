require "csv"

# Imports a Rapid7 InsightVM "vulnerability instance" CSV export.
#
# Each row describes one (asset, vulnerability) pairing; assets and
# vulnerabilities are upserted into their own catalogs, and a Finding
# row ties them together for this import.
#
# Every export is a full snapshot of what Rapid7 currently sees as
# vulnerable, keyed by "Asset Unique Identifier" + "Vulnerability Unique
# Identifier". So on each import:
#   - a pairing present in the CSV but not yet in our DB is a new finding (opened)
#   - a pairing present in both is still outstanding (metadata refreshed, reopened if it had been closed)
#   - a pairing that was open in our DB but absent from the CSV has been
#     remediated since the last export, and is closed
class Rapid7CsvImporter
  Result = Struct.new(:csv_import, :rows_processed, :closed_count, :errors, keyword_init: true)

  def initialize(file, user:)
    @file = file
    @user = user
  end

  def call
    csv_import = CsvImport.create!(user: @user, filename: original_filename, status: :processing)
    rows_processed = 0
    closed_count = 0
    errors = []
    seen_finding_ids = []

    ActiveRecord::Base.transaction do
      CSV.foreach(@file.path, headers: true) do |row|
        seen_finding_ids << import_row(row, csv_import).id
        rows_processed += 1
      rescue => e
        errors << "Row #{rows_processed + 1}: #{e.message}"
      end

      if errors.empty?
        closed_count = Finding.open.where.not(id: seen_finding_ids)
          .update_all(status: "closed", closed_at: Time.current)
      else
        raise ActiveRecord::Rollback
      end
    end

    csv_import.update!(
      status: errors.any? ? :failed : :completed,
      rows_count: rows_processed,
      error_message: errors.any? ? errors.join("\n") : nil
    )

    Result.new(csv_import: csv_import, rows_processed: rows_processed, closed_count: closed_count, errors: errors)
  end

  private

  def original_filename
    @file.respond_to?(:original_filename) ? @file.original_filename : File.basename(@file.path)
  end

  def import_row(row, csv_import)
    asset = upsert_asset(row)
    vulnerability = upsert_vulnerability(row)

    finding = Finding.find_or_initialize_by(asset: asset, vulnerability: vulnerability)
    finding.assign_attributes(
      csv_import: csv_import,
      status: "open",
      closed_at: nil,
      instance_count: row["Vulnerability Instance Count"],
      in_grace_period: to_bool(row["In Grace Period"]),
      has_malware: to_bool(row["Has Malware"]),
      due_date: row["Due Date"],
      past_due: to_bool(row["Past Due"]),
      date_added: row["Date Added"],
      first_found: row["First Found"],
      date_modified: row["Date Modified"],
      discovery_date: row["Discovery Date"],
      reintroduced: row["Reintroduced"]
    )
    finding.save!
    finding
  end

  def upsert_asset(row)
    asset = Asset.find_or_initialize_by(asset_uid: row["Asset Unique Identifier"])
    asset.assign_attributes(
      hostname: row["Hostname"],
      ip_address: row["IP Address"],
      operating_system: row["Operating System"],
      os_family: row["OS Family"],
      os_vendor: row["OS Vendor"],
      os_product: row["OS Product"],
      os_version: row["OS Version"],
      os_architecture: row["OS Architecture"],
      os_certainty: row["OS Certainty"],
      host_type: row["Host Type"],
      host_type_source: row["Host Type Source"],
      has_malware: to_bool(row["Has Malware"]),
      malware_count: row["Malware Count"],
      pci_compliant: to_bool(row["PCI Compliant"]),
      risk_score: row["Risk Score"],
      raw_risk_score: row["Raw Risk Score"],
      critical_vulnerability_count: row["Critical Vulnerability Count"],
      severe_vulnerability_count: row["Severe Vulnerability Count"],
      moderate_vulnerability_count: row["Moderate Vulnerability Count"]
    )
    asset.save!
    asset
  end

  def upsert_vulnerability(row)
    vulnerability = Vulnerability.find_or_initialize_by(vulnerability_uid: row["Vulnerability Unique Identifier"])
    vulnerability.assign_attributes(
      title: row["Vulnerability Title"],
      severity: row["Severity"],
      severity_rank: row["Severity Rank"],
      severity_score: row["Severity Score"],
      pci_severity: row["PCI Severity"],
      cvss_score: row["CVSS Score"],
      cvss_access_vector: row["CVSS Access Vector"],
      cvss_access_complexity: row["CVSS Access Complexity"],
      cvss_authentication: row["CVSS Authentication"],
      cvss_confidentiality_impact: row["CVSS Confidentiality Impact"],
      cvss_integrity_impact: row["CVSS Integrity Impact"],
      cvss_availability_impact: row["CVSS Availability Impact"],
      skill_level_rank: row["Skill Level Rank"],
      has_exploits: to_bool(row["Has Exploits"]),
      exploit_count: row["Exploit Count"],
      date_published: row["Date Published"]
    )
    vulnerability.save!
    vulnerability
  end

  def to_bool(value)
    value.to_s.strip.downcase == "true"
  end
end
