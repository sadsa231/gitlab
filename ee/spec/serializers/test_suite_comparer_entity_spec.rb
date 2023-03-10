# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSuiteComparerEntity do
  include TestReportsHelper

  let(:entity) { described_class.new(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::TestSuiteComparer.new(name, base_suite, head_suite) }
  let(:name) { 'rpsec' }
  let(:base_suite) { Gitlab::Ci::Reports::TestSuite.new(name) }
  let(:head_suite) { Gitlab::Ci::Reports::TestSuite.new(name) }
  let(:test_case_success) { create_test_case_rspec_success }
  let(:test_case_failed) { create_test_case_rspec_failed }

  let(:test_case_resolved) do
    create_test_case_rspec_failed.tap do |test_case|
      test_case.instance_variable_set(:@status, Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
    end
  end

  describe '#as_json' do
    subject { entity.as_json }

    context 'when head sutie has a newly failed test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_failed)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('failed')
        expect(subject[:summary]).to include(total: 1, resolved: 0, failed: 1)
        subject[:new_failures].first.tap do |new_failure|
          expect(new_failure[:status]).to eq(test_case_failed.status)
          expect(new_failure[:name]).to eq(test_case_failed.name)
          expect(new_failure[:execution_time]).to eq(test_case_failed.execution_time)
          expect(new_failure[:system_output]).to eq(test_case_failed.system_output)
        end
        expect(subject[:resolved_failures]).to be_empty
        expect(subject[:existing_failures]).to be_empty
      end
    end

    context 'when head sutie still has a failed test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_failed)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('failed')
        expect(subject[:summary]).to include(total: 1, resolved: 0, failed: 1)
        expect(subject[:new_failures]).to be_empty
        expect(subject[:resolved_failures]).to be_empty
        subject[:existing_failures].first.tap do |existing_failure|
          expect(existing_failure[:status]).to eq(test_case_failed.status)
          expect(existing_failure[:name]).to eq(test_case_failed.name)
          expect(existing_failure[:execution_time]).to eq(test_case_failed.execution_time)
          expect(existing_failure[:system_output]).to eq(test_case_failed.system_output)
        end
      end
    end

    context 'when head sutie has a success test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_resolved)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('success')
        expect(subject[:summary]).to include(total: 1, resolved: 1, failed: 0)
        expect(subject[:new_failures]).to be_empty
        subject[:resolved_failures].first.tap do |resolved_failure|
          expect(resolved_failure[:status]).to eq(test_case_resolved.status)
          expect(resolved_failure[:name]).to eq(test_case_resolved.name)
          expect(resolved_failure[:execution_time]).to eq(test_case_resolved.execution_time)
          expect(resolved_failure[:system_output]).to eq(test_case_resolved.system_output)
        end
        expect(subject[:existing_failures]).to be_empty
      end
    end
  end
end
