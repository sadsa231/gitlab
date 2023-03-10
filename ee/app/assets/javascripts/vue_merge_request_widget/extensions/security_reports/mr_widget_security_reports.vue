<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import MrWidgetRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import toast from '~/vue_shared/plugins/global_toast';
import { BV_SHOW_MODAL, BV_HIDE_MODAL } from '~/lib/utils/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import FindingModal from 'ee/vue_shared/security_reports/components/modal.vue';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';
import { capitalizeFirstCharacter, convertToCamelCase } from '~/lib/utils/text_utility';
import { helpPagePath } from '~/helpers/help_page_helper';
import { CRITICAL, HIGH } from '~/vulnerabilities/constants';
import { DynamicScroller, DynamicScrollerItem } from 'vendor/vue-virtual-scroller';
import SummaryText from './summary_text.vue';
import SummaryHighlights from './summary_highlights.vue';
import SecurityTrainingPromoWidget from './security_training_promo_widget.vue';
import { i18n, reportTypes, popovers } from './i18n';

export default {
  name: 'WidgetSecurityReports',
  components: {
    FindingModal,
    MrWidget,
    MrWidgetRow,
    SummaryText,
    SummaryHighlights,
    SecurityTrainingPromoWidget,
    GlBadge,
    GlButton,
    DynamicScroller,
    DynamicScrollerItem,
  },
  i18n,
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      isCreatingIssue: false,
      isDismissingFinding: false,
      modalData: null,
      vulnerabilities: {
        collapsed: null,
        expanded: null,
      },
    };
  },
  computed: {
    helpPopovers() {
      return {
        SAST: {
          options: { title: popovers.SAST_TITLE },
          content: { text: popovers.SAST_TEXT, learnMorePath: this.mr.sastHelp },
        },
        DAST: {
          options: { title: popovers.DAST_TITLE },
          content: { text: popovers.DAST_TEXT, learnMorePath: this.mr.dastHelp },
        },
        SECRET_DETECTION: {
          options: { title: popovers.SECRET_DETECTION_TITLE },
          content: {
            text: popovers.SECRET_DETECTION_TEXT,
            learnMorePath: this.mr.secretDetectionHelp,
          },
        },
        CONTAINER_SCANNING: {
          options: { title: popovers.CONTAINER_SCANNING_TITLE },
          content: {
            text: popovers.CONTAINER_SCANNING_TEXT,
            learnMorePath: this.mr.containerScanningHelp,
          },
        },
        DEPENDENCY_SCANNING: {
          options: { title: popovers.DEPENDENCY_SCANNING_TITLE },
          content: {
            text: popovers.DEPENDENCY_SCANNING_TEXT,
            learnMorePath: this.mr.dependencyScanningHelp,
          },
        },
        API_FUZZING: {
          options: { title: popovers.API_FUZZING_TITLE },
          content: {
            learnMorePath: this.mr.apiFuzzingHelp,
          },
        },
        COVERAGE_FUZZING: {
          options: { title: popovers.COVERAGE_FUZZING_TITLE },
          content: {
            learnMorePath: this.mr.coverageFuzzingHelp,
          },
        },
      };
    },

    isCollapsible() {
      if (!this.vulnerabilities.collapsed) {
        return false;
      }

      return this.vulnerabilitiesCount > 0;
    },

    vulnerabilitiesCount() {
      return this.vulnerabilities.collapsed.reduce((counter, current) => {
        return counter + current.numberOfNewFindings + (current.fixed?.length || 0);
      }, 0);
    },

    highlights() {
      if (!this.vulnerabilities.collapsed) {
        return {};
      }

      const highlights = {
        [HIGH]: 0,
        [CRITICAL]: 0,
        other: 0,
      };

      // The data we receive from the API is something like:
      // [
      //  { scanner: "SAST", added: [{ id: 15, severity: 'critical' }] },
      //  { scanner: "DAST", added: [{ id: 15, severity: 'high' }] },
      //  ...
      // ]
      this.vulnerabilities.collapsed.forEach((report) =>
        this.highlightsFromReport(report, highlights),
      );

      return highlights;
    },

    totalNewVulnerabilities() {
      if (!this.vulnerabilities.collapsed) {
        return 0;
      }

      return this.vulnerabilities.collapsed.reduce((counter, current) => {
        return counter + (current.numberOfNewFindings || 0);
      }, 0);
    },

    statusIconName() {
      if (this.totalNewVulnerabilities > 0) {
        return 'warning';
      }

      return 'success';
    },

    canCreateIssue() {
      return Boolean(
        this.mr.createVulnerabilityFeedbackIssuePath ||
          this.modalData?.vulnerability?.create_jira_issue_url,
      );
    },

    canDismissFinding() {
      return Boolean(this.mr.createVulnerabilityFeedbackDismissalPath);
    },
  },
  methods: {
    handleIsLoading(value) {
      this.isLoading = value;
    },

    fetchCollapsedData() {
      // TODO: check if gl.mrWidgetData can be safely removed after we migrate to the
      // widget extension.
      const endpoints = [
        [this.mr.sastComparisonPath, 'SAST'],
        [this.mr.dastComparisonPath, 'DAST'],
        [this.mr.secretDetectionComparisonPath, 'SECRET_DETECTION'],
        [this.mr.apiFuzzingComparisonPath, 'API_FUZZING'],
        [this.mr.coverageFuzzingComparisonPath, 'COVERAGE_FUZZING'],
        [this.mr.dependencyScanningComparisonPath, 'DEPENDENCY_SCANNING'],
        [this.mr.containerScanningComparisonPath, 'CONTAINER_SCANNING'],
      ].filter(([endpoint, reportType]) => {
        const enabledReportsKeyName = convertToCamelCase(reportType.toLowerCase());
        return Boolean(endpoint) && this.mr.enabledReports[enabledReportsKeyName];
      });

      return endpoints.map(([path, reportType]) => () => {
        const props = {
          reportType,
          reportTypeDescription: reportTypes[reportType],
          numberOfNewFindings: 0,
          added: [],
          fixed: [],
        };

        return axios
          .get(path)
          .then(({ data, headers = {}, status }) => ({
            headers,
            status,
            data: { ...props, ...data, numberOfNewFindings: data.added?.length || 0 },
          }))
          .catch(({ headers = {}, status = 500 }) => ({
            headers,
            status,
            data: { ...props, error: true },
          }));
      });
    },

    highlightsFromReport(report, highlights = { [HIGH]: 0, [CRITICAL]: 0, other: 0 }) {
      // The data we receive from the API is something like:
      // [
      //  { scanner: "SAST", added: [{ id: 15, severity: 'critical' }] },
      //  { scanner: "DAST", added: [{ id: 15, severity: 'high' }] },
      //  ...
      // ]
      return report.added.reduce((acc, vuln) => {
        if (vuln.severity === HIGH) {
          acc[HIGH] += 1;
        } else if (vuln.severity === CRITICAL) {
          acc[CRITICAL] += 1;
        } else {
          acc.other += 1;
        }
        return acc;
      }, highlights);
    },

    statusIconNameReportType(report) {
      if (report.numberOfNewFindings > 0 || report.error) {
        return EXTENSION_ICONS.warning;
      }

      return EXTENSION_ICONS.success;
    },

    statusIconNameVulnerability(vuln) {
      return EXTENSION_ICONS[`severity${capitalizeFirstCharacter(vuln.severity)}`];
    },

    isDismissed(vuln) {
      return vuln.state === 'dismissed';
    },

    setModalData(finding) {
      this.modalData = {
        error: null,
        title: finding.name,
        vulnerability: finding,
        isShowingDeleteButtons: false,
      };

      // We want to keep a reference to the `finding` object so that whenever
      // that object is updated, also the `vulnerability.collapsed` state is updated.
      this.modalData.vulnerability.isDismissed = this.isDismissed(finding);
      this.isDismissingFinding = false;

      this.$root.$emit(BV_SHOW_MODAL, VULNERABILITY_MODAL_ID);
    },

    createNewIssue() {
      this.isCreatingIssue = true;
      const finding = this.modalData?.vulnerability;

      axios
        .post(this.mr.createVulnerabilityFeedbackIssuePath, {
          vulnerability_feedback: {
            feedback_type: 'issue',
            pipeline_id: this.mr.pipelineId,
            project_fingerprint: finding.project_fingerprint,
            finding_uuid: finding.uuid,
            category: finding.report_type,
            vulnerability_data: { ...finding, category: finding.report_type },
          },
        })
        .then((response) => {
          visitUrl(response.data.issue_url); // redirect the user to the created issue
        })
        .catch(() => {
          this.modalData.error = s__(
            'ciReport|There was an error creating the issue. Please try again.',
          );
        })
        .finally(() => {
          this.isCreatingIssue = false;
        });
    },

    dismissFinding(comment) {
      const finding = this.modalData?.vulnerability;
      const toastMsg = sprintf(s__("SecurityReports|Dismissed '%{vulnerabilityName}'"), {
        vulnerabilityName: finding.name,
      });

      this.isDismissingFinding = true;

      return axios
        .post(this.mr.createVulnerabilityFeedbackDismissalPath, {
          vulnerability_feedback: {
            category: finding.report_type,
            comment,
            feedback_type: 'dismissal',
            pipeline_id: this.mr.pipelineId,
            project_fingerprint: finding.project_fingerprint,
            finding_uuid: finding.uuid,
            vulnerability_data: finding,
          },
        })
        .then(({ data }) => {
          this.modalData.vulnerability.state = 'dismissed';
          this.modalData.vulnerability.isDismissed = true;
          this.$set(this.modalData.vulnerability, 'dismissal_feedback', data);
          this.hideModal();
          toast(toastMsg);
        })
        .catch((error) => {
          const pipelineNoLongerExists =
            error.response?.status === HTTP_STATUS_UNPROCESSABLE_ENTITY;

          this.modalData.error = pipelineNoLongerExists
            ? s__(
                'ciReport|Could not dismiss vulnerability because the associated pipeline no longer exists. Refresh the page and try again.',
              )
            : s__('ciReport|There was an error dismissing the vulnerability. Please try again.');
        })
        .finally(() => {
          this.isDismissingFinding = false;
        });
    },

    revertDismissVulnerability() {
      this.isDismissingFinding = true;

      axios
        .delete(
          this.modalData.vulnerability.dismissal_feedback
            .destroy_vulnerability_feedback_dismissal_path,
        )
        .then(() => {
          this.modalData.vulnerability.state = 'detected';
          this.modalData.vulnerability.isDismissed = false;
          this.hideModal();
        })
        .catch(() => {
          this.modalData.error = s__(
            'ciReport|There was an error reverting the dismissal. Please try again.',
          );
        })
        .finally(() => {
          this.isDismissingFinding = false;
        });
    },

    openDismissalCommentBox() {
      this.$set(this.modalData, 'isCommentingOnDismissal', true);
    },

    closeDismissalCommentBox() {
      this.$set(this.modalData, 'isCommentingOnDismissal', false);
    },

    editDismissalComment(comment) {
      const { vulnerability: finding } = this.modalData;
      const dismissalFeedback = finding.dismissal_feedback;
      const url = `${this.mr.createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`;
      const toastMsg = sprintf(s__("SecurityReports|Comment edited on '%{vulnerabilityName}'"), {
        vulnerabilityName: finding.name,
      });

      // This will cause the spinner to be displayed
      this.isDismissingFinding = true;

      return axios
        .patch(url, {
          project_id: dismissalFeedback.project_id,
          id: dismissalFeedback.id,
          comment,
        })
        .then(({ data }) => {
          this.modalData.vulnerability.dismissal_feedback = data;
          toast(toastMsg);
          this.hideModal();
        })
        .catch(() => {
          this.modalData.error = s__('SecurityReports|There was an error adding the comment.');
        })
        .finally(() => {
          this.isDismissingFinding = false;
        });
    },

    hideDismissalDeleteButtons() {
      this.modalData.isShowingDeleteButtons = false;
    },

    showDismissalDeleteButtons() {
      this.modalData.isShowingDeleteButtons = true;
    },

    deleteDismissalComment() {
      const { vulnerability: finding } = this.modalData;
      const { dismissal_feedback: dismissalFeedback } = finding;
      const url = `${this.mr.createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`;
      const toastMsg = sprintf(s__("SecurityReports|Comment deleted on '%{vulnerabilityName}'"), {
        vulnerabilityName: finding.name,
      });

      // This will cause the spinner to be displayed
      this.isDismissingFinding = true;

      return axios
        .patch(url, {
          project_id: dismissalFeedback.project_id,
          comment: '',
        })
        .then(({ data }) => {
          this.modalData.vulnerability.dismissal_feedback = data;
          toast(toastMsg);
          this.hideModal();
        })
        .catch(() => {
          this.modalData.error = s__('SecurityReports|There was an error deleting the comment.');
        });
    },

    hideModal() {
      this.$root.$emit(BV_HIDE_MODAL, VULNERABILITY_MODAL_ID);
    },
  },
  SEVERITY_LEVELS,
  widgetHelpPopover: {
    options: { title: i18n.helpPopoverTitle },
    content: {
      text: i18n.helpPopoverContent,
      learnMorePath: helpPagePath('user/application_security/index', {
        anchor: 'ultimate',
      }),
    },
  },
};
</script>

<template>
  <mr-widget
    v-model="vulnerabilities"
    :error-text="$options.i18n.error"
    :fetch-collapsed-data="fetchCollapsedData"
    :status-icon-name="statusIconName"
    :widget-name="$options.name"
    :is-collapsible="isCollapsible"
    :help-popover="$options.widgetHelpPopover"
    multi-polling
    @is-loading="handleIsLoading"
  >
    <template #summary>
      <summary-text :total-new-vulnerabilities="totalNewVulnerabilities" :is-loading="isLoading" />
      <summary-highlights
        v-if="!isLoading && totalNewVulnerabilities > 0"
        :highlights="highlights"
      />
    </template>
    <template #content>
      <finding-modal
        v-if="modalData"
        :visible="true"
        :modal="modalData"
        :is-dismissing-vulnerability="isDismissingFinding"
        :is-creating-merge-request="false"
        :is-creating-issue="isCreatingIssue"
        :can-create-issue="canCreateIssue"
        :can-dismiss-vulnerability="canDismissFinding"
        @addDismissalComment="editDismissalComment"
        @closeDismissalCommentBox="closeDismissalCommentBox"
        @openDismissalCommentBox="openDismissalCommentBox"
        @editVulnerabilityDismissalComment="openDismissalCommentBox"
        @deleteDismissalComment="deleteDismissalComment"
        @revertDismissVulnerability="revertDismissVulnerability"
        @createNewIssue="createNewIssue"
        @dismissVulnerability="dismissFinding"
        @showDismissalDeleteButtons="showDismissalDeleteButtons"
        @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
      />
      <security-training-promo-widget
        :security-configuration-path="mr.securityConfigurationPath"
        :project-full-path="mr.sourceProjectFullPath"
      />
      <mr-widget-row
        v-for="report in vulnerabilities.collapsed"
        :key="report.reportType"
        :widget-name="$options.name"
        :level="2"
        :status-icon-name="statusIconNameReportType(report)"
        :help-popover="helpPopovers[report.reportType]"
        :data-testid="`report-${report.reportType}`"
      >
        <template #header>
          <div>
            <summary-text
              :total-new-vulnerabilities="report.numberOfNewFindings"
              :is-loading="false"
              :error="report.error"
              :scanner="report.reportTypeDescription"
              :data-testid="`${report.reportType}-report-header`"
            />
            <summary-highlights
              v-if="report.numberOfNewFindings > 0"
              :highlights="highlightsFromReport(report)"
            />
          </div>
        </template>
        <template #body>
          <div v-if="report.numberOfNewFindings > 0" class="gl-mt-2 gl-w-full">
            <strong>{{ $options.i18n.new }}</strong>
            <div class="gl-mt-2">
              <dynamic-scroller
                :items="report.added"
                :min-item-size="32"
                :style="{ maxHeight: '170px' }"
                data-testid="dynamic-content-scroller"
                key-field="uuid"
                class="gl-pr-5"
              >
                <template #default="{ item: vuln, active }">
                  <dynamic-scroller-item :item="vuln" :active="active">
                    <mr-widget-row
                      :key="vuln.uuid"
                      :level="3"
                      :widget-name="$options.name"
                      :status-icon-name="statusIconNameVulnerability(vuln)"
                      class="gl-mt-2"
                    >
                      <template #body>
                        {{ $options.SEVERITY_LEVELS[vuln.severity] }}
                        <gl-button variant="link" class="gl-ml-2" @click="setModalData(vuln)">{{
                          vuln.name
                        }}</gl-button>
                        <gl-badge v-if="isDismissed(vuln)" class="gl-ml-3">{{
                          $options.i18n.dismissed
                        }}</gl-badge>
                      </template>
                    </mr-widget-row>
                  </dynamic-scroller-item>
                </template>
              </dynamic-scroller>
            </div>
          </div>
        </template>
      </mr-widget-row>
    </template>
  </mr-widget>
</template>
