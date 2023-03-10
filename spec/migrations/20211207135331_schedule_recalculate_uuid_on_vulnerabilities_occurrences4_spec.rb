# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleRecalculateUuidOnVulnerabilitiesOccurrences4, feature_category: :vulnerability_management do
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:users) { table(:users) }
  let(:user) { create_user! }
  let(:project) { table(:projects).create!(id: 123, namespace_id: namespace.id) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let(:different_scanner) { scanners.create!(project_id: project.id, external_id: 'test 2', name: 'test scanner 2') }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:vulnerabilities_findings) { table(:vulnerability_occurrences) }
  let(:vulnerability_finding_signatures) { table(:vulnerability_finding_signatures) }
  let(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let(:vulnerability_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v5',
      external_id: 'uuid-v5',
      fingerprint: '7e394d1b1eb461a7406d7b1e08f057a1cf11287a',
      name: 'Identifier for UUIDv5')
  end

  let(:different_vulnerability_identifier) do
    vulnerability_identifiers.create!(
      project_id: project.id,
      external_type: 'uuid-v4',
      external_id: 'uuid-v4',
      fingerprint: '772da93d34a1ba010bcb5efa9fb6f8e01bafcc89',
      name: 'Identifier for UUIDv4')
  end

  let!(:uuidv4_finding) do
    create_finding!(
      vulnerability_id: vulnerability_for_uuidv4.id,
      project_id: project.id,
      scanner_id: different_scanner.id,
      primary_identifier_id: different_vulnerability_identifier.id,
      location_fingerprint: Gitlab::Database::ShaAttribute.serialize('fa18f432f1d56675f4098d318739c3cd5b14eb3e'),
      uuid: 'b3cc2518-5446-4dea-871c-89d5e999c1ac'
    )
  end

  let(:vulnerability_for_uuidv4) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:uuidv5_finding) do
    create_finding!(
      vulnerability_id: vulnerability_for_uuidv5.id,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: vulnerability_identifier.id,
      location_fingerprint: Gitlab::Database::ShaAttribute.serialize('838574be0210968bf6b9f569df9c2576242cbf0a'),
      uuid: '77211ed6-7dff-5f6b-8c9a-da89ad0a9b60'
    )
  end

  let(:vulnerability_for_uuidv5) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let(:vulnerability_for_finding_with_signature) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:finding_with_signature) do
    create_finding!(
      vulnerability_id: vulnerability_for_finding_with_signature.id,
      project_id: project.id,
      scanner_id: scanner.id,
      primary_identifier_id: vulnerability_identifier.id,
      report_type: 0, # "sast"
      location_fingerprint: Gitlab::Database::ShaAttribute.serialize('123609eafffffa2207a9ca2425ba4337h34fga1b'),
      uuid: '252aa474-d689-5d2b-ab42-7bbb5a100c02'
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migrations', :aggregate_failures do
    migrate!

    expect(BackgroundMigrationWorker.jobs.size).to eq(3)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, uuidv4_finding.id, uuidv4_finding.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, uuidv5_finding.id, uuidv5_finding.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(6.minutes, finding_with_signature.id, finding_with_signature.id)
  end

  private

  def create_vulnerability!(project_id:, author_id:, title: 'test', severity: 7, confidence: 7, report_type: 0)
    vulnerabilities.create!(
      project_id: project_id,
      author_id: author_id,
      title: title,
      severity: severity,
      confidence: confidence,
      report_type: report_type
    )
  end

  def create_finding!(
    vulnerability_id:, project_id:, scanner_id:, primary_identifier_id:, location_fingerprint:, uuid:, report_type: 0)
    vulnerabilities_findings.create!(
      vulnerability_id: vulnerability_id,
      project_id: project_id,
      name: 'test',
      severity: 7,
      confidence: 7,
      report_type: report_type,
      project_fingerprint: '123qweasdzxc',
      scanner_id: scanner_id,
      primary_identifier_id: primary_identifier_id,
      location_fingerprint: location_fingerprint,
      metadata_version: 'test',
      raw_metadata: 'test',
      uuid: uuid
    )
  end

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0
    )
  end
end
