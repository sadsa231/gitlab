<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import SignInGitlabCom from './sign_in_gitlab_com.vue';
import SignInGitlabMultiversion from './sign_in_gitlab_multiversion/index.vue';

export default {
  name: 'SignInPage',
  components: { SignInGitlabCom, SignInGitlabMultiversion },
  mixins: [glFeatureFlagMixin()],
  props: {
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
    publicKeyStorageEnabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isOauthSelfManagedEnabled() {
      return this.glFeatures.jiraConnectOauth && this.publicKeyStorageEnabled;
    },
  },
};
</script>
<template>
  <sign-in-gitlab-multiversion
    v-if="isOauthSelfManagedEnabled"
    @sign-in-oauth="$emit('sign-in-oauth', $event)"
    @error="$emit('error', $event)"
  />
  <sign-in-gitlab-com
    v-else
    :has-subscriptions="hasSubscriptions"
    @sign-in-oauth="$emit('sign-in-oauth')"
    @error="$emit('error', $event)"
  />
</template>
