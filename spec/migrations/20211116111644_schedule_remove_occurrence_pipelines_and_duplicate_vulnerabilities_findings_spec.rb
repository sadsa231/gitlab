# frozen_string_literal: true
require 'spec_helper'

require_migration!

RSpec.describe ScheduleRemoveOccurrencePipelinesAndDuplicateVulnerabilitiesFindings,
               :suppress_gitlab_schemas_validate_connection, :migration, feature_category: :vulnerability_management do
  let!(:background_migration_jobs) { table(:background_migration_jobs) }
  let!(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let!(:users) { table(:users) }
  let!(:user) { create_user! }
  let!(:project) { table(:projects).create!(id: 14219619, namespace_id: namespace.id) }
  let!(:pipelines) { table(:ci_pipelines) }
  let!(:scanners) { table(:vulnerability_scanners) }
  let!(:scanner1) { scanners.create!(project_id: project.id, external_id: 'test 1', name: 'test scanner 1') }
  let!(:scanner2) { scanners.create!(project_id: project.id, external_id: 'test 2', name: 'test scanner 2') }
  let!(:scanner3) { scanners.create!(project_id: project.id, external_id: 'test 3', name: 'test scanner 3') }
  let!(:unrelated_scanner) { scanners.create!(project_id: project.id, external_id: 'unreleated_scanner', name: 'unrelated scanner') }
  let!(:vulnerabilities) { table(:vulnerabilities) }
  let!(:vulnerability_findings) { table(:vulnerability_occurrences) }
  let!(:vulnerability_finding_pipelines) { table(:vulnerability_occurrence_pipelines) }
  let!(:vulnerability_identifiers) { table(:vulnerability_identifiers) }
  let!(:vulnerability_identifier) do
    vulnerability_identifiers.create!(
      id: 1244459,
      project_id: project.id,
      external_type: 'vulnerability-identifier',
      external_id: 'vulnerability-identifier',
      fingerprint: '0a203e8cd5260a1948edbedc76c7cb91ad6a2e45',
      name: 'vulnerability identifier')
  end

  let!(:vulnerability_for_first_duplicate) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:first_finding_duplicate) do
    create_finding!(
      id: 5606961,
      uuid: "bd95c085-71aa-51d7-9bb6-08ae669c262e",
      vulnerability_id: vulnerability_for_first_duplicate.id,
      report_type: 0,
      location_fingerprint: '00049d5119c2cb3bfb3d1ee1f6e031fe925aed75',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner1.id,
      project_id: project.id
    )
  end

  let!(:vulnerability_for_second_duplicate) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:second_finding_duplicate) do
    create_finding!(
      id: 8765432,
      uuid: "5b714f58-1176-5b26-8fd5-e11dfcb031b5",
      vulnerability_id: vulnerability_for_second_duplicate.id,
      report_type: 0,
      location_fingerprint: '00049d5119c2cb3bfb3d1ee1f6e031fe925aed75',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner2.id,
      project_id: project.id
    )
  end

  let!(:vulnerability_for_third_duplicate) do
    create_vulnerability!(
      project_id: project.id,
      author_id: user.id
    )
  end

  let!(:third_finding_duplicate) do
    create_finding!(
      id: 8832995,
      uuid: "cfe435fa-b25b-5199-a56d-7b007cc9e2d4",
      vulnerability_id: vulnerability_for_third_duplicate.id,
      report_type: 0,
      location_fingerprint: '00049d5119c2cb3bfb3d1ee1f6e031fe925aed75',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: scanner3.id,
      project_id: project.id
    )
  end

  let!(:unrelated_finding) do
    create_finding!(
      id: 9999999,
      vulnerability_id: nil,
      report_type: 1,
      location_fingerprint: 'random_location_fingerprint',
      primary_identifier_id: vulnerability_identifier.id,
      scanner_id: unrelated_scanner.id,
      project_id: project.id
    )
  end

  before do
    stub_const("#{described_class}::BATCH_SIZE", 1)

    4.times do
      create_finding_pipeline!(project_id: project.id, finding_id: first_finding_duplicate.id)
      create_finding_pipeline!(project_id: project.id, finding_id: second_finding_duplicate.id)
      create_finding_pipeline!(project_id: project.id, finding_id: third_finding_duplicate.id)
      create_finding_pipeline!(project_id: project.id, finding_id: unrelated_finding.id)
    end
  end

  around do |example|
    freeze_time { Sidekiq::Testing.fake! { example.run } }
  end

  it 'schedules background migrations' do
    migrate!

    expect(background_migration_jobs.count).to eq(4)
    expect(background_migration_jobs.first.arguments).to match_array([first_finding_duplicate.id, first_finding_duplicate.id])
    expect(background_migration_jobs.second.arguments).to match_array([second_finding_duplicate.id, second_finding_duplicate.id])
    expect(background_migration_jobs.third.arguments).to match_array([third_finding_duplicate.id, third_finding_duplicate.id])
    expect(background_migration_jobs.fourth.arguments).to match_array([unrelated_finding.id, unrelated_finding.id])

    expect(BackgroundMigrationWorker.jobs.size).to eq(4)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, first_finding_duplicate.id, first_finding_duplicate.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, second_finding_duplicate.id, second_finding_duplicate.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(6.minutes, third_finding_duplicate.id, third_finding_duplicate.id)
    expect(described_class::MIGRATION).to be_scheduled_delayed_migration(8.minutes, unrelated_finding.id, unrelated_finding.id)
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

  # rubocop:disable Metrics/ParameterLists
  def create_finding!(
    vulnerability_id:, project_id:, scanner_id:, primary_identifier_id:, id: nil,
                      name: "test", severity: 7, confidence: 7, report_type: 0,
                      project_fingerprint: '123qweasdzxc', location_fingerprint: 'test',
                      metadata_version: 'test', raw_metadata: 'test', uuid: SecureRandom.uuid)
    params = {
      vulnerability_id: vulnerability_id,
      project_id: project_id,
      name: name,
      severity: severity,
      confidence: confidence,
      report_type: report_type,
      project_fingerprint: project_fingerprint,
      scanner_id: scanner_id,
      primary_identifier_id: vulnerability_identifier.id,
      location_fingerprint: location_fingerprint,
      metadata_version: metadata_version,
      raw_metadata: raw_metadata,
      uuid: uuid
    }
    params[:id] = id unless id.nil?
    vulnerability_findings.create!(params)
  end
  # rubocop:enable Metrics/ParameterLists

  def create_user!(name: "Example User", email: "user@example.com", user_type: nil, created_at: Time.zone.now, confirmed_at: Time.zone.now)
    users.create!(
      name: name,
      email: email,
      username: name,
      projects_limit: 0,
      user_type: user_type,
      confirmed_at: confirmed_at
    )
  end

  def create_finding_pipeline!(project_id:, finding_id:)
    pipeline = pipelines.create!(project_id: project_id)
    vulnerability_finding_pipelines.create!(pipeline_id: pipeline.id, occurrence_id: finding_id)
  end
end
