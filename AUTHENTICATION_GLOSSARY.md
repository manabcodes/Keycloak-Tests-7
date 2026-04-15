# Authentication and Authorization Terms Glossary

This document explains the main protocols, standards, and terms related to authentication, authorization, and digital identity in a clear and understandable way.

---

## 🔐 OAuth 2.0 (Open Authorization 2.0)

**What is it?**  
OAuth 2.0 is an **authorization protocol** that allows third-party applications to obtain limited access to a user's resources without exposing their credentials.

**Simple analogy:**  
Imagine you want to give a photo printing application access to your Google photos, but you don't want to give it your Google password. OAuth 2.0 is like giving it a "temporary key" that only works to access your photos, and only for a limited time.

**Main features:**
- **Not an authentication protocol** (though often used together with one)
- Allows **delegated access** to resources
- Uses **access tokens** instead of credentials
- Defines several **flows** depending on the application type

**Common flows:**
- **Authorization Code Flow**: For secure web applications
- **Implicit Flow**: For JavaScript applications (now discouraged)
- **Client Credentials Flow**: For server-to-server communication
- **Resource Owner Password Credentials**: For trusted applications (not recommended)

**Practical example:**  
When you use "Sign in with Google" in an application, that application uses OAuth 2.0 to obtain permission to access your basic Google information.

---

## 🆔 OpenID Connect (OIDC)

**What is it?**  
OpenID Connect is an **authentication protocol** built on top of OAuth 2.0. While OAuth 2.0 focuses on authorization ("can I access this?"), OIDC focuses on authentication ("who are you?").

**Relationship with OAuth 2.0:**  
OIDC is like an "extension" of OAuth 2.0 that adds authentication capabilities. It uses the same OAuth 2.0 flow but adds a special token called **ID Token** that contains information about the user's identity.

**Main features:**
- Built on OAuth 2.0
- Provides **authentication** (not just authorization)
- Issues **ID Tokens** (JWT) with user information
- Defines standard endpoints (`.well-known/openid-configuration`)
- Supports **UserInfo endpoint** to obtain additional user information

**Key components:**
- **ID Token**: JWT token containing user identity information
- **Access Token**: Token to access protected resources
- **Refresh Token**: Token to obtain new access tokens without re-authentication

**Practical example:**  
When you log in to an application using Keycloak, the application uses OIDC to:
1. Authenticate you (verify who you are)
2. Obtain information about you (name, email, etc.)
3. Authorize access to the application

---

## 🏛️ SAML (Security Assertion Markup Language)

**What is it?**  
SAML is an XML standard for **exchanging authentication and authorization information** between parties, especially between an Identity Provider (IdP) and a Service Provider (SP).

**Simple analogy:**  
Imagine you are a student and want to enter the library. The library doesn't have your information, but trusts your university. SAML is like a "student pass" that your university issues and that the library accepts as proof that you are a student.

**Main features:**
- Based on **XML**
- Used mainly in **enterprise environments**
- Supports **Single Sign-On (SSO)**
- Defines **assertions** about user identity
- Older than OAuth 2.0/OIDC

**Key components:**
- **Identity Provider (IdP)**: Who authenticates the user (e.g.: Keycloak)
- **Service Provider (SP)**: The application that needs to verify identity
- **SAML Assertion**: XML document containing user information
- **SAML Response**: IdP response to SP with the assertion

**Common flows:**
- **SP-Initiated**: User tries to access the application, which redirects to IdP
- **IdP-Initiated**: User logs in to IdP and then chooses the application

**Practical example:**  
A company uses SAML so its employees can log in to multiple applications (Salesforce, Office 365, etc.) using their corporate credentials once.

---

## 📁 LDAP (Lightweight Directory Access Protocol)

**What is it?**  
LDAP is a **directory access protocol** that allows querying and modifying information in a directory service (like Active Directory).

**Simple analogy:**  
LDAP is like a "digital phone book" where you can search for information about users, groups, computers, etc. in an organization.

**Main features:**
- Protocol for **accessing directories**
- Used to **store and query** user information
- Hierarchical structure in the form of a **tree (DIT - Directory Information Tree)**
- Not an authentication protocol itself, but used to verify credentials

**Key concepts:**
- **DN (Distinguished Name)**: Unique identifier of an object in the directory
- **Base DN**: Root of the directory tree (e.g.: `dc=company,dc=com`)
- **OU (Organizational Unit)**: Organizational unit
- **CN (Common Name)**: Common name of an object
- **Bind**: LDAP authentication operation

**Practical example:**  
A company stores employee information (names, emails, departments) in Active Directory. Applications use LDAP to query this information and authenticate users.

**LDAP vs Active Directory:**
- **LDAP**: It's the protocol (the "language" to talk to directories)
- **Active Directory**: It's a Microsoft directory service that uses LDAP

---

## 🔑 JWT (JSON Web Token)

**What is it?**  
JWT is an **open standard** for securely transmitting information between parties as a JSON object. This information can be verified and trusted because it is digitally signed.

**Structure:**  
A JWT has three parts separated by dots (`.`):
1. **Header**: Token type and signature algorithm
2. **Payload**: The data (claims) about the user
3. **Signature**: Signature to verify the token hasn't been tampered with

**Structure example:**
```
xxxxx.yyyyy.zzzzz
```

**Main features:**
- **Self-contained**: All necessary information is in the token
- **Signed**: Can be verified without querying the server
- **Compact**: Easy to transmit in URLs, HTTP headers, etc.
- **Stateless**: Server doesn't need to store sessions

**Types of claims:**
- **Registered claims**: Standard (e.g.: `iss`, `exp`, `sub`)
- **Public claims**: Publicly defined
- **Private claims**: Custom for the application

**Practical example:**  
When you log in to an application, Keycloak issues a JWT containing your name, email, and roles. The application can verify this token without querying Keycloak each time.

---

## 🌐 SSO (Single Sign-On)

**What is it?**  
SSO is an **authentication mechanism** that allows a user to log in once and access multiple applications without having to authenticate again.

**Simple analogy:**  
It's like having a master key that opens all doors in a building. Once you prove your identity at the entrance, you can access all offices without having to identify yourself at each one.

**Main features:**
- **Single authentication** for multiple applications
- **Improves user experience** (no need for multiple passwords)
- **Reduces friction** in accessing applications
- **Centralizes identity** management

**Types of SSO:**
- **Web SSO**: For web applications (using cookies, tokens, etc.)
- **Enterprise SSO**: For enterprise applications (using SAML, OIDC)
- **Mobile SSO**: For mobile applications

**Practical example:**  
An employee logs in once to the company portal and can access all applications (email, CRM, HR system) without logging in again.

---

## 🏢 IdP (Identity Provider)

**What is it?**  
An Identity Provider is a **service that authenticates users** and provides information about their identity to other applications (Service Providers).

**Main features:**
- **Authenticates users** (verifies who they are)
- **Issues tokens or assertions** about identity
- **Manages user** credentials
- **Provides user** information to applications

**Examples of IdPs:**
- **Keycloak**: Open-source IdP
- **Google**: For "Sign in with Google"
- **Microsoft Azure AD**: For enterprises
- **Okta**: Commercial enterprise IdP
- **Auth0**: IdP as a service

**Practical example:**  
Keycloak acts as an IdP when it authenticates a user and then provides a token to an application that trusts Keycloak.

---

## 🎯 SP (Service Provider)

**What is it?**  
A Service Provider is an **application or service** that needs to verify a user's identity and trusts an Identity Provider to do so.

**Main features:**
- **Depends on an IdP** for authentication
- **Trusts IdP tokens/assertions**
- **Doesn't manage credentials** directly
- **Provides services** to the authenticated user

**Practical example:**  
A web application (like the "Employee Portal") is a Service Provider that trusts Keycloak (IdP) to authenticate users.

---

## 🔄 Federation (Identity Federation)

**What is it?**  
Identity federation is a **trust agreement** between multiple organizations or domains to share identity information and enable SSO between them.

**Simple analogy:**  
It's like an agreement between universities where a student from University A can use their credential to access resources from University B, because both universities have a trust agreement.

**Main features:**
- **Establishes trust** between domains/organizations
- **Enables SSO** between different organizations
- **Reduces the need** for multiple accounts
- **Maintains autonomy** of each organization

**Practical example:**  
A company and its business partners configure federation so employees from both organizations can access shared systems using their corporate credentials.

---

## 🎫 Access Token

**What is it?**  
An Access Token is an **authorization token** that allows an application to access protected resources on behalf of a user.

**Main features:**
- **Short lifetime** (typically minutes or hours)
- **Used for authorization** (resource access)
- **Included in requests** to protected APIs
- **Can be opaque or JWT**

**Practical example:**  
When an application wants to read your Google photos, it includes the Access Token in the HTTP request to demonstrate it has permission.

---

## 🔄 Refresh Token

**What is it?**  
A Refresh Token is a **long-lived token** used to obtain new Access Tokens without requiring the user to authenticate again.

**Main features:**
- **Long lifetime** (days, weeks, or indefinite)
- **Used only to obtain** new access tokens
- **More secure** than storing credentials
- **Can be revoked** if compromised

**Practical example:**  
If an Access Token expires after 1 hour, the application can use the Refresh Token to obtain a new Access Token without asking the user to log in again.

---

## 🆔 ID Token

**What is it?**  
An ID Token is a **JWT token** containing information about the user's identity. It's part of the OpenID Connect protocol.

**Main features:**
- **Always a JWT**
- **Contains identity information** (name, email, etc.)
- **Signed by the IdP**
- **Not used to access resources** (that's the Access Token)
- **Short lifetime**

**Practical example:**  
When you log in with OIDC, you receive an ID Token containing your name, email, and other identity data that the application can use to personalize your experience.

---

## 🔐 PKCE (Proof Key for Code Exchange)

**What is it?**  
PKCE is a **security extension** for OAuth 2.0 designed to protect the Authorization Code Flow, especially in public applications (like mobile apps or SPAs).

**Problem it solves:**  
In public applications, the client secret cannot be kept secure. PKCE adds an additional security layer using a dynamically generated verification code.

**How it works:**
1. The application generates a **code verifier** (random)
2. Creates a **code challenge** (hash of the verifier)
3. Sends the challenge to the server
4. When exchanging the code, sends the original verifier
5. The server verifies that the verifier corresponds to the challenge

**Main features:**
- **Improves OAuth 2.0** security
- **Especially useful** for public applications
- **Recommended** for SPAs and mobile applications
- **Optional but highly recommended**

**Practical example:**  
A JavaScript application (SPA) uses PKCE to ensure that even if someone intercepts the authorization code, they cannot use it without the original code verifier.

---

## 🎭 Realm (Realm)

**What is it?**  
In Keycloak, a Realm is an **isolated space** where users, clients, roles, and configurations are managed independently.

**Simple analogy:**  
It's like a "separate building" within Keycloak. Each building has its own users, rules, and configurations, and they don't mix with each other.

**Main features:**
- **Complete isolation** between realms
- **Independent users** in each realm
- **Separate configurations** (password policies, themes, etc.)
- **Realm-specific** clients

**Practical example:**  
A company can have:
- `company-realm`: For internal employees
- `client-realm`: For external clients
- `partner-realm`: For business partners

Each realm has its own users and applications, completely separated.

---

## 👤 Client (Client)

**What is it?**  
In OAuth 2.0/OIDC, a Client is an **application that requests access** to protected resources on behalf of a user.

**Types of clients:**
- **Public Client**: Cannot securely maintain secrets (SPA, mobile applications)
- **Confidential Client**: Can securely maintain secrets (server applications)

**Main features:**
- **Has a Client ID** (unique identifier)
- **Can have a Client Secret** (for confidential clients)
- **Configured with allowed** redirect URIs
- **Can have assigned** scopes

**Practical example:**  
The "Employee Portal" is a Client registered in Keycloak with Client ID `portal-app` and redirect URI `http://localhost:3000/portal`.

---

## 🎯 Scope (Scope)

**What is it?**  
A Scope is a **permission or access scope** that defines what resources or information an application can access.

**Main features:**
- **Defines access** limits
- **Requested by the application** during authentication
- **Approved by the user** (in some cases)
- **Included in the access** token

**Common scopes:**
- `openid`: Required for OIDC
- `profile`: Basic profile information
- `email`: Email address
- `offline_access`: To obtain refresh tokens

**Practical example:**  
An application can request the scopes `openid profile email` to obtain basic user information, or `openid profile email read:photos` to also access their photos.

---

## 🔗 Redirect URI

**What is it?**  
A Redirect URI is the **URL to which the authorization server redirects** the user after authentication, including the authorization code.

**Main features:**
- **Must match exactly** with the one configured in the client
- **Includes the authorization code** in the URL
- **Critical security**: Only authorized URIs can receive tokens
- **Can have multiple** URIs per client

**Practical example:**  
If a client has the redirect URI `http://localhost:3000/portal` configured, Keycloak will only redirect to that exact URL after authentication.

---

## 🔐 Client Secret

**What is it?**  
A Client Secret is a **secret credential** used by confidential clients to authenticate with the authorization server.

**Main features:**
- **Only for confidential clients** (server applications)
- **Never exposed** to the user or browser
- **Used in the exchange** of authorization code for tokens
- **Must be kept secure**

**Practical example:**  
A server application includes its Client Secret when exchanging the authorization code for tokens, demonstrating it's the authorized application.

---

## 🌍 Identity Provider (IDP) - In Keycloak Context

**What is it?**  
In Keycloak, an Identity Provider is an **integration with an external identity provider** (like Google, Facebook, GitHub) that allows users to authenticate using their credentials from that provider.

**Main features:**
- **Connects Keycloak** with external providers
- **Enables social login** (Google, Facebook, etc.)
- **Maps information** from external provider to Keycloak users
- **Can automatically create users** or link them to existing users

**Practical example:**  
When you configure Google as an Identity Provider in Keycloak, users can log in using their Google account instead of creating an account in Keycloak.

---

## 📋 User Federation

**What is it?**  
User Federation in Keycloak allows **connecting Keycloak with external directory systems** (like LDAP or Active Directory) to synchronize users.

**Main features:**
- **Synchronizes users** from external systems
- **Can be read-only** or allow writing
- **Periodic or real-time** synchronization
- **Maps attributes** between systems

**Practical example:**  
A company connects Keycloak with its Active Directory so all employees can use their corporate credentials to log in to applications managed by Keycloak.

---

## 🔒 SSL/TLS and HTTPS

**What is it?**  
SSL/TLS are **encryption** protocols that protect communication between client and server. HTTPS is HTTP over SSL/TLS.

**In Keycloak context:**
- **Production**: Must always use HTTPS
- **Development**: Can use HTTP with `sslRequired: "none"`
- **Certificates**: Required for HTTPS in production

**Keycloak configuration:**
- `KC_HTTPS_REQUIRED`: Environment variable to require HTTPS
- `sslRequired`: Realm property to require SSL

---

## 📊 Comparative Summary

| Term | Type | Main Purpose | When to Use |
|---------|------|---------------------|-------------|
| **OAuth 2.0** | Protocol | Authorization (resource access) | When you need to give access to resources without sharing credentials |
| **OpenID Connect** | Protocol | Authentication + Authorization | When you need to authenticate users and obtain identity information |
| **SAML** | XML Standard | Enterprise SSO authentication | In enterprise environments with applications that support SAML |
| **LDAP** | Protocol | Directory access | To query/store user information in directories |
| **JWT** | Standard | Information transmission | For self-contained and verifiable tokens |
| **SSO** | Mechanism | Single authentication | To improve UX and security in multiple applications |

---

## 🔗 Relationships Between Terms

```
OAuth 2.0
  └── OpenID Connect (extends OAuth 2.0)
      └── Uses JWT for ID Tokens
          └── Implemented by Keycloak (IdP)
              └── Provides SSO
                  └── Can federate with LDAP/AD
                      └── Can integrate Identity Providers (Google, etc.)
```

---

## 📚 Additional Resources

- **OAuth 2.0**: [RFC 6749](https://tools.ietf.org/html/rfc6749)
- **OpenID Connect**: [Specification](https://openid.net/connect/)
- **SAML 2.0**: [Specification](http://saml.xml.org/saml-specifications)
- **JWT**: [RFC 7519](https://tools.ietf.org/html/rfc7519)
- **Keycloak**: [Official documentation](https://www.keycloak.org/documentation)

---

*This document is a quick reference guide. For specific implementations, consult the official documentation of each protocol or tool.*
