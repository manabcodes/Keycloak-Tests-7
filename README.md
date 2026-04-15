# Keycloak Demo - Use Cases

This project contains the implementation of different use cases for Keycloak in the context of identification and authentication.

## Project Structure

```
keycloak-demo/
├── USE_CASES.md              # Main document with all use cases
├── README.md                 # This file
├── AUTHENTICATION_GLOSSARY.md # Authentication terms glossary
├── use-cases/                # Folder with all use cases
│   ├── USE_CASE_1/            # SSO in corporate and citizen applications
│   ├── USE_CASE_2/            # Machine authentication - WEB services
│   ├── USE_CASE_3/            # Citizen identification
│   ├── USE_CASE_4/            # Application-level authorization
│   ├── USE_CASE_5/            # Decentralized permission management
│   ├── USE_CASE_6/            # External applications send data
│   ├── USE_CASE_7/            # Different identity providers
│   └── USE_CASE_8/            # Usage from supported applications
└── [shared configuration files]
```

## Use Cases

See [USE_CASES.md](./USE_CASES.md) for the complete description of all use cases.

### USE_CASE_1: SSO in Corporate and Citizen Applications ✅

**Status**: In progress

**Location**: `use-cases/USE_CASE_1/`

**Description**: Implementation of Single Sign-On (SSO) for corporate applications and also for citizens.

**To run**:
```bash
cd use-cases/USE_CASE_1
docker-compose up -d
```

See [use-cases/USE_CASE_1/README.md](./use-cases/USE_CASE_1/README.md) for more details.

### Other Use Cases

The remaining use cases are pending implementation. Each will have its own folder with documentation and code when implemented.

## Additional Documentation

- [USE_CASES.md](./USE_CASES.md) - Main document with all use cases
- [AUTHENTICATION_GLOSSARY.md](./AUTHENTICATION_GLOSSARY.md) - Glossary of authentication and authorization terms

## Requirements

- Docker and Docker Compose
- Modern web browser
- (Optional) Google OAuth 2.0 credentials to test social login

## Notes

- Each use case is independent and can be run separately
- Use cases share concepts and patterns, but are organized to facilitate development and maintenance
- It is recommended to review the documentation of each use case before running it
