---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Generic OAuth 2.0 provider **(FREE SELF)**

The [`omniauth-oauth2-generic` gem](https://gitlab.com/satorix/omniauth-oauth2-generic) allows single sign-on (SSO) between GitLab
and your OAuth 2.0 provider, or any OAuth 2.0 provider compatible with this gem.

This strategy allows for the configuration of this OmniAuth SSO process:

1. Strategy directs the client to your authorization URL (**configurable**), with
   the specified ID and key.
1. The OAuth 2.0 provider handles authentication of the request, user, and (optionally)
   authorization to access the user's profile.
1. The OAuth 2.0 provider directs the client back to GitLab where Strategy
   retrieves the access token.
1. Strategy requests user information from a **configurable** "user profile"
   URL using the access token.
1. Strategy parses user information from the response using a **configurable**
   format.
1. GitLab finds or creates the returned user and signs them in.

This strategy:

- Can only be used for single sign-on, and does not provide any other access
  granted by any OAuth 2.0 provider. For example, importing projects or users.
- Only supports the Authorization Grant flow, which is most common for client-server
  applications like GitLab.
- Cannot fetch user information from more than one URL.
- Has not been tested with user information formats, except JSON.

## Configure the OAuth 2.0 provider

To configure the provider:

1. Register your application in the OAuth 2.0 provider you want to authenticate with.

   The redirect URI you provide when registering the application should be:

   ```plaintext
   http://your-gitlab.host.com/users/auth/oauth2_generic/callback
   ```

   You should now be able to get a client ID and client secret. Where these
   appear is different for each provider. This may also be called application ID
   and application secret.

1. On your GitLab server, complete the following steps.

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   1. Edit the [common configuration file settings](omniauth.md#configure-common-settings)
      to add `oauth2_generic` as a single sign-on provider. This enables Just-In-Time
      account provisioning for users who do not have an existing GitLab account.
   1. Edit `/etc/gitlab/gitlab.rb` to add the configuration for your provider. For example:

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        {
          name: "oauth2_generic",
          label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
          app_id: "<your_app_client_id>",
          app_secret: "<your_app_client_secret>",
          args: {
            client_options: {
              site: "<your_auth_server_url>",
              user_info_url: "/oauth2/v1/userinfo",
              authorize_url: "/oauth2/v1/authorize",
              token_url: "/oauth2/v1/token"
            },
            user_response_structure: {
              root_path: [],
              id_path: ["sub"],
              attributes: {
                email: "email",
                name: "name"
              }
            },
            authorize_params: {
              scope: "openid profile email"
            },
            strategy_class: "OmniAuth::Strategies::OAuth2Generic"
          }
        }
      ]
      ```

   1. Save the file and reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   :::TabTitle Helm chart (Kubernetes)

   1. Edit the [common configuration file settings](omniauth.md#configure-common-settings)
      to add `oauth2_generic` as a single sign-on provider. This enables Just-In-Time
      account provisioning for users who do not have an existing GitLab account.
   1. Export the Helm values:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Edit `gitlab_values.yaml`.

      NOTE:
      The following example exposes the `app_secret` value in the main YAML file.
      You're strongly advised to use
      [Helm secrets](https://docs.gitlab.com/charts/installation/secrets.html)
      instead.

      ```yaml
      global:
        appConfig:
          omniauth:
            enabled: true
            providers:
              - name: "oauth2_generic"
                label: "Provider name" # optional label for login button defaults to "Oauth2 Generic"
                app_id: "<your_app_client_id>"
                app_secret: "<your_app_client_secret>"
                args:
                  client_options:
                    site: "<your_auth_server_url>"
                    user_info_url: "/oauth2/v1/userinfo"
                    authorize_url: "/oauth2/v1/authorize"
                    token_url: "/oauth2/v1/token"
                  user_response_structure:
                    root_path: []
                    id_path: ["sub"]
                    attributes:
                      email: "email"
                      name: "name"
                  authorize_params:
                    scope: "openid profile email"
                  strategy_class: "OmniAuth::Strategies::OAuth2Generic"
      ```

   1. Save the file and apply the new values:

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   :::TabTitle Self-compiled (source)

   1. Edit the [common configuration file settings](omniauth.md#configure-common-settings)
      to add `oauth2_generic` as a single sign-on provider. This enables Just-In-Time
      account provisioning for users who do not have an existing GitLab account.
   1. Edit `/home/git/gitlab/config/gitlab.yml`:

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: "oauth2_generic",
                label: "Provider name", # optional label for login button, defaults to "Oauth2 Generic"
                app_id: "<your_app_client_id>",
                app_secret: "<your_app_client_secret>",
                args: {
                  client_options: {
                    site: "<your_auth_server_url>",
                    user_info_url: "/oauth2/v1/userinfo",
                    authorize_url: "/oauth2/v1/authorize",
                    token_url: "/oauth2/v1/token"
                  },
                  user_response_structure: {
                    root_path: [],
                    id_path: ["sub"],
                    attributes: {
                      email: "email",
                      name: "name"
                    }
                  },
                  authorize_params: {
                    scope: "openid profile email"
                  },
                  strategy_class: "OmniAuth::Strategies::OAuth2Generic"
                }
              }
      ```

   1. Save the file and restart GitLab:

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   ::EndTabs

On the sign-in page there should now be a new icon below the regular sign-in
form. Select that icon to begin your provider's authentication process. This
directs the browser to your OAuth 2.0 provider's authentication page. If
everything goes well, you are returned to your GitLab instance and
signed in.
