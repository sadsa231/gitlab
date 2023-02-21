---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure SCIM for GitLab.com groups **(PREMIUM SAAS)**

You can use the open standard System for Cross-domain Identity Management (SCIM) to automatically:

- Create users.
- Remove users (deactivate SCIM identity).

GitLab SAML SSO SCIM doesn't support updating users.

When SCIM is enabled for a GitLab group, membership of that group is synchronized between GitLab and an identity provider.

The [internal GitLab group SCIM API](../../../development/internal_api/index.md#group-scim-api) implements part of [the RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).

## Configure GitLab

Prerequisites:

- [Group single sign-on](index.md) must be configured.

To configure GitLab SAML SSO SCIM:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > SAML SSO**.
1. Select **Generate a SCIM token**.
1. For configuration of your identity provider, save the:
   - Token from the **Your SCIM token** field.
   - URL from the **SCIM API endpoint URL** field.

## Configure an identity provider

You can configure one of the following as an identity provider:

- [Azure Active Directory](#configure-azure-active-directory).
- [Okta](#configure-okta).
- [OneLogin](#configure-onelogin).

NOTE:
Other providers can work with GitLab but they have not been tested and are not supported.

### Configure Azure Active Directory

Prerequisites:

- [GitLab is configured](#configure-gitlab).

The SAML application created during [single sign-on](index.md) set up for
[Azure Active Directory](https://learn.microsoft.com/en-us/azure/active-directory/manage-apps/view-applications-portal)
must be set up for SCIM. For an example, see [example configuration](example_saml_config.md#scim-mapping).

To configure Azure Active Directory for SCIM:

1. In your app, go to the **Provisioning** tab and select **Get started**.
1. Set the **Provisioning Mode** to **Automatic**.
1. Complete the **Admin Credentials** using the value of:
   - **SCIM API endpoint URL** in GitLab for the **Tenant URL** field.
   - **Your SCIM token** in GitLab for the **Secret Token** field.
1. Select **Test Connection**. If the test is successful, save your configuration before continuing, or see the
   [troubleshooting](troubleshooting.md) information.
1. Select **Save**.

After saving, **Settings** and **Mappings** sections appear.

1. Under **Settings**, if required, set a notification email and select the
   **Send an email notification when a failure occurs** checkbox.
1. Under **Mappings**, we recommend you:
   1. Keep **Provision Azure Active Directory Users** enabled and select the **Provision Azure Active Directory Users**
      link to [configure attribute mappings](#configure-attribute-mappings).
   1. Below the mapping list select the **Show advanced options** checkbox.
   1. Select the **Edit attribute list for customappsso** link.
   1. Ensure the `id` is the primary and required field, and `externalId` is also required.
   1. Select **Save**.
1. Return to the **Provisioning** tab, saving unsaved changes if necessary.
1. Select **Edit attribute mappings**.
1. Under **Mappings**:
   1. Select **Provision Azure Active Directory Groups**.
   1. On the Attribute Mapping page, turn off the **Enabled** toggle. Leaving it turned on doesn't break the SCIM user
      provisioning, but it causes errors in Azure Active Directory that may be confusing and misleading.
   1. Select **Save**.
1. Return to the **Provisioning** tab, saving unsaved changes if necessary.
1. Select **Edit attribute mappings**.
1. Turn on the **Provisioning Status** toggle. Synchronization details and any errors appears on the bottom of the
   **Provisioning** screen, together with a link to the audit events.

WARNING:
Once synchronized, changing the field mapped to `id` and `externalId` may cause a number of errors. These include
provisioning errors, duplicate users, and may prevent existing users from accessing the GitLab group.

#### Configure attribute mappings

While [configuring Azure Active Directory for SCIM](#configure-azure-active-directory), you configure attribute mappings.
For an example, see [example configuration](example_saml_config.md#scim-mapping).

The following table provides attribute mappings known to work with GitLab.

| Source attribute    | Target attribute               | Matching precedence |
|:--------------------|:-------------------------------|:--------------------|
| `objectId`          | `externalId`                   | 1                   |
| `userPrincipalName` | `emails[type eq "work"].value` |                     |
| `mailNickname`      | `userName`                     |                     |

Each attribute mapping has:

- An Azure Active Directory attribute (source attribute).
- A `customappsso` attribute (target attribute).
- A matching precedence.

For each attribute:

1. Select the attribute to edit it.
1. Select the required settings.
1. Select **Ok**.

If your SAML configuration differs from [the recommended SAML settings](index.md#azure-setup-notes), select the mapping
attributes and modify them accordingly. In particular, the `objectId` source attribute must map to the `externalId`
target attribute.

If a mapping is not listed in the table, use the Azure Active Directory defaults. For a list of required attributes,
refer to the [internal group SCIM API](../../../development/internal_api/index.md#group-scim-api) documentation.

### Configure Okta

The SAML application created during [single sign-on](index.md) set up for Okta must be set up for SCIM.

Prerequisites:

- You must use the Okta [Lifecycle Management](https://www.okta.com/products/lifecycle-management/) product. This
  product tier is required to use SCIM on Okta.
- [GitLab is configured](#configure-gitlab).
- SAML application for [Okta](https://developer.okta.com/docs/guides/build-sso-integration/saml2/main/) set up as
  described in the [Okta setup notes](index.md#okta-setup-notes).
- Your Okta SAML setup matches the [configuration steps exactly](index.md), especially the NameID configuration.

To configure Okta for SCIM:

1. Sign in to Okta.
1. Ensure you are in the Admin Area by selecting the **Admin** button located in the top right. The button is not visible from the Admin Area.
1. In the **Application** tab, select **Browse App Catalog**.
1. Search for **GitLab**, find and select the **GitLab** application.
1. On the GitLab application overview page, select **Add**.
1. Under **Application Visibility** select both checkboxes. Currently the GitLab application does not support SAML
   authentication so the icon should not be shown to users.
1. Select **Done** to finish adding the application.
1. In the **Provisioning** tab, select **Configure API integration**.
1. Select **Enable API integration**.
   - For **Base URL**, paste the URL you copied from **SCIM API endpoint URL** on the GitLab SCIM configuration page.
   - For **API Token**, paste the SCIM token you copied from **Your SCIM token** on the GitLab SCIM
     configuration page.
1. To verify the configuration, select **Test API Credentials**.
1. Select **Save**.
1. After saving the API integration details, new settings tabs appear on the left. Select **To App**.
1. Select **Edit**.
1. Select the **Enable** checkbox for both **Create Users** and **Deactivate Users**.
1. Select **Save**.
1. Assign users in the **Assignments** tab. Assigned users are created and managed in your GitLab group.

### Configure OneLogin

Prerequisites:

- [GitLab is configured](#configure-gitlab).

OneLogin provides a **GitLab (SaaS)** app in their catalog, which includes a SCIM integration. Contact OneLogin if you
encounter issues.

## User access

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325712) in GitLab 14.0, GitLab users created by [SAML SSO](index.md#user-access-and-management) or SCIM provisioning are displayed with an **Enterprise** badge in the **Members** view.

During the synchronization process, all new users:

- Receive GitLab accounts.
- Are welcomed to their groups with an invitation email. You may want to warn your employees to expect this email.

The following diagram describes what happens when you add users to your SCIM app:

```mermaid
graph TD
  A[Add User to SCIM app] -->|IdP sends user info to GitLab| B(GitLab: Does the email exist?)
  B -->|No| C[GitLab creates user with SCIM identity]
  B -->|Yes| D[GitLab sends message back 'Email exists']
```

During provisioning:

- Both primary and secondary emails are considered when checking whether a GitLab user account exists.
- Duplicate usernames are handled by adding suffix `1` when creating the user. For example, if `test_user` already
  exists, `test_user1` is used. If `test_user1` already exists, GitLab increments the suffix until an unused username
  is found.

On subsequent visits, new and existing users can access groups either:

- Through the identity provider's dashboard.
- By visiting links directly.

For role information, see the [Group SAML](index.md#user-access-and-management) page.

### Link SCIM and SAML identities

If [group SAML](index.md) is configured and you have an existing GitLab.com account, users can link their SCIM and SAML
identities. Users should do this before synchronization is turned on because there can be provisioning errors for
existing users when synchronization is active.

To link your SCIM and SAML identities:

1. Update the [primary email](../../profile/index.md#change-your-primary-email) address in your GitLab.com user account
   to match the user profile email address in your identity provider.
1. [Link your SAML identity](index.md#linking-saml-to-your-existing-gitlabcom-account).

### Remove access

Remove or deactivate a user on the identity provider to remove their access to:

- The top-level group.
- All subgroups and projects.

After the identity provider performs a sync based on its configured schedule, the user's membership is revoked and they
lose access.

NOTE:
Deprovisioning does not delete the GitLab user account.

```mermaid
graph TD
  A[Remove User from SCIM app] -->|IdP sends request to GitLab| B(GitLab: Is the user part of the group?)
  B -->|No| C[Nothing to do]
  B -->|Yes| D[GitLab removes user from GitLab group]
```
