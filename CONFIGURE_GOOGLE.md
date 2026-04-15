# Configure Google Authentication in Keycloak

This guide will help you configure Google (Gmail) sign-in in Keycloak.

## Step 1: Get Google OAuth Credentials

### 1.1. Create a Project in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Create a new project or select an existing one
4. Note the project name

### 1.2. Enable Google+ API

1. In the side menu, go to **APIs & Services** > **Library**
2. Search for "Google+ API" or "People API"
3. Click on the result and then click **Enable**

### 1.3. Configure OAuth Consent Screen

1. Go to **APIs & Services** > **OAuth consent screen**
2. Select **External** (for development) or **Internal** (only for users in your organization)
3. Complete the required fields:
   - **App name**: Your application name (e.g.: "Company SSO")
   - **User support email**: Your email
   - **Developer contact information**: Your email
4. Click **Save and Continue**
5. In **Scopes**, click **Save and Continue** (default scopes are sufficient)
6. In **Test users**, add test emails if necessary
7. Click **Save and Continue** and then **Back to Dashboard**

### 1.4. Create OAuth 2.0 Credentials

1. Go to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **Web application** as application type
4. Complete the fields:
   - **Name**: "Keycloak SSO" (or the name you prefer)
   - **Authorized JavaScript origins**: 
     - `http://localhost:8080`
   - **Authorized redirect URIs**:
     - `http://localhost:8080/realms/empresa-realm/broker/google/endpoint`
5. Click **Create**
6. **IMPORTANT**: Copy the **Client ID** and **Client Secret** (only shown once)

## Step 2: Configure Keycloak

### Option A: Using Keycloak Web Interface

1. Access Keycloak admin console:
   - URL: `http://localhost:8080`
   - User: `admin`
   - Password: `admin`

2. Select the **empresa-realm** realm

3. In the side menu, go to **Identity Providers**

4. Click **Add provider** and select **Google**

5. Complete the configuration:
   - **Alias**: `google` (or leave default)
   - **Client ID**: Paste the Google Client ID
   - **Client Secret**: Paste the Google Client Secret
   - **Default Scopes**: `openid profile email` (already configured)

6. In the **Settings** tab:
   - **Trust Email**: Enable this option if you want Keycloak to trust the verified email from Google
   - **First Login Flow**: Select "first broker login" (default)
   - **Sync Mode**: Select "import" to automatically import users

7. Click **Save**

8. **Enable the provider**: Make sure the **Enabled** toggle is activated

### Option B: Update Realm JSON File

1. Edit the file `keycloak-config/realm-empresa.json`

2. Find the `identityProviders` section and update:
   ```json
   "identityProviders": [
     {
       "alias": "google",
       "providerId": "google",
       "enabled": true,
       "config": {
         "clientId": "YOUR_GOOGLE_CLIENT_ID_HERE",
         "clientSecret": "YOUR_GOOGLE_CLIENT_SECRET_HERE",
         "defaultScope": "openid profile email"
       }
     }
   ]
   ```

3. Restart Docker services:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Step 3: Test Google Login

1. Open an incognito window in your browser
2. Go to one of your applications:
   - `http://localhost:3000/portal`
   - `http://localhost:3000/proyectos`
   - `http://localhost:3000/admin`
3. You should see a button or link to sign in with Google
4. Click the Google button
5. You will be redirected to Google's authentication page
6. Sign in with your Google account
7. Accept the requested permissions
8. You will be redirected back to your application with the session started

## Role Configuration for Google Users

By default, users who authenticate with Google don't have assigned roles. You can configure this in two ways:

### Option 1: Assign Roles Manually

1. In Keycloak, go to **Users**
2. Find the automatically created user (usually the Google email)
3. Go to the **Role Mappings** tab
4. Assign the necessary roles (user, manager, admin)

### Option 2: Use Automatic Mappers (Advanced)

You can configure mappers in the Identity Provider to automatically assign roles based on email domain or Google attributes.

## Add Other Social Networks

Keycloak supports multiple identity providers:

- **GitHub**: Similar to Google, requires Client ID and Client Secret
- **Facebook**: Requires App ID and App Secret
- **Twitter**: Requires API Key and API Secret
- **Microsoft/Azure AD**: Requires Client ID and Client Secret
- **LinkedIn**: Requires Client ID and Client Secret

The process is similar: obtain credentials from the provider and configure them in Keycloak.

## Troubleshooting

### Error: "redirect_uri_mismatch"
- Verify that the redirect URI in Google Cloud Console exactly matches:
  - `http://localhost:8080/realms/empresa-realm/broker/google/endpoint`

### Error: "invalid_client"
- Verify that the Client ID and Client Secret are correct
- Make sure there are no extra spaces when copying/pasting

### Google button doesn't appear
- Verify that the Identity Provider is enabled (`enabled: true`)
- Verify that you are in the correct realm (`empresa-realm`)
- Clear browser cache

### User is not created automatically
- Verify that "Trust Email" is enabled
- Verify that "Sync Mode" is set to "import"
- Check Keycloak logs for errors

## Important Notes

- In production, use HTTPS instead of HTTP
- Update redirect URIs in Google Cloud Console to include your production domain
- Consider restricting access by email domain using "hostedDomain" in configuration
- Google users are automatically created in Keycloak the first time they sign in
