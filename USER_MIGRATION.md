# User and Password Migration to Keycloak

## Scenario

You have an existing platform with users and passwords, and you want to migrate to Keycloak to centralize authentication.

## Important Considerations about Passwords

### Main Problem

Keycloak CANNOT import passwords in plain text or hashed directly because:
- Keycloak uses its own hashing algorithm (bcrypt, pbkdf2, etc.)
- It needs Keycloak's specific format
- Hashed passwords from other systems are not compatible

## Migration Options

### Option 1: Migration with Password Reset (Recommended)

**How it works:**
1. Import users to Keycloak
2. Mark passwords as "temporary"
3. Users must change their password on first login
4. Or send a password reset email

**Advantages:**
- Simple and secure
- You don't need to know current passwords
- Complies with security best practices

**Disadvantages:**
- Users must change their password
- May cause temporary inconveniences

### Option 2: Migration with Temporary Passwords

**How it works:**
1. Generate temporary passwords for each user
2. Send them via email or SMS
3. Users log in with the temporary password
4. Keycloak asks them to change the password

**Advantages:**
- Full control over the process
- You can force password change

**Disadvantages:**
- Requires communication with users
- More administrative work

### Option 3: Migration with Plain Text Passwords (Development Only)

**How it works:**
1. Import users with plain text passwords
2. Keycloak hashes them automatically

**Advantages:**
- Transparent migration for users
- They don't need to change password

**Disadvantages:**
- Only works if you have access to plain text passwords
- NOT recommended for production (security risk)

### Option 4: User Federation (LDAP/AD)

**How it works:**
1. Connect Keycloak to your existing LDAP/Active Directory
2. Users authenticate with their current credentials
3. You don't need to migrate passwords

**Advantages:**
- You don't need to migrate passwords
- Single source of truth
- Automatic synchronization

**Disadvantages:**
- Requires LDAP/AD infrastructure
- Dependency on external system

## Migration Procedure

### Phase 1: Preparation

#### Step 1.1: Export Users from Current Platform

1. Identify the user data source (database, file, API, etc.)
2. Export the following data per user:
   - Username
   - Email
   - First name (firstName)
   - Last name (lastName)
   - Status (active/inactive)
   - Current roles or permissions
   - Password (if available in plain text)

#### Step 1.2: Prepare Data in Keycloak Format

1. Create a JSON file with user structure
2. Required format:
   - username: Unique username
   - email: Email address
   - firstName: User's first name
   - lastName: User's last name
   - enabled: true/false (active user)
   - emailVerified: true/false
   - password: Plain text password (if available)
   - temporary: true/false (if password is temporary)
   - roles: List of roles to assign

#### Step 1.3: Decide Password Strategy

1. Evaluate which option to use according to your situation:
   - If you have plain text passwords: Option 3 (development only) or Option 1
   - If you only have hashes: Option 1 or 2
   - If you have LDAP/AD: Option 4
2. Document the decision and communication plan

### Phase 2: Keycloak Configuration

#### Step 2.1: Access Keycloak Admin Console

1. Open browser and access Keycloak URL
2. Log in with administrator credentials
3. Select the realm where you will migrate users

#### Step 2.2: Verify Existing Roles

1. Navigate to Roles in the side menu
2. Verify that necessary roles exist
3. If roles are missing, create them before migrating users
4. Document roles and their descriptions

#### Step 2.3: Configure Email (Optional)

1. If you will use password reset by email:
   - Go to Realm Settings → Email
   - Configure SMTP server
   - Test email sending

### Phase 3: User Migration

#### Step 3.1: Use Migration Script

1. Use the script provided in the scripts/ folder
2. Prepare the JSON file with users to migrate
3. Run the script in dry-run mode first to verify
4. Review dry-run results
5. Execute real migration

#### Step 3.2: Manual Migration (Alternative)

If you prefer to migrate manually:

1. Go to Users in Keycloak Admin Console
2. Click "Add user"
3. Complete the fields:
   - Username
   - Email
   - First name
   - Last name
   - Email verified: ON
   - Enabled: ON
4. Click "Create"
5. Go to the "Credentials" tab
6. Set the password:
   - Password: Enter the password
   - Temporary: Mark if temporary
7. Click "Set password"
8. Go to the "Role Mappings" tab
9. Assign necessary roles
10. Repeat for each user

#### Step 3.3: Verify Migrated Users

1. List all users in Keycloak
2. Verify that the number matches exported users
3. Review a sample of users to confirm:
   - Correct data
   - Passwords set
   - Roles assigned
4. Test login with some test users

### Phase 4: User Communication

#### Step 4.1: Prepare Communication

1. Draft an informative email that includes:
   - Reason for migration
   - Migration date
   - Access instructions
   - Temporary password (if applicable)
   - Steps to change password
   - Support contact

#### Step 4.2: Send Notifications

1. Send email to all affected users
2. Consider sending reminders before migration
3. Prepare a support channel for inquiries

### Phase 5: Validation and Testing

#### Step 5.1: Authentication Testing

1. Test login with different types of users:
   - User with basic role
   - User with multiple roles
   - User with temporary password
   - User with permanent password
2. Verify that roles are assigned correctly
3. Confirm that applications can authenticate users

#### Step 5.2: Post-Migration Monitoring

1. Monitor Keycloak logs for errors
2. Review failed login attempts
3. Verify that no users are incorrectly blocked
4. Collect user feedback

### Phase 6: Finalization

#### Step 6.1: Deactivate Old System

1. Once successful migration is confirmed:
   - Deactivate old authentication system
   - Keep a backup of data
   - Document deactivation date

#### Step 6.2: Final Documentation

1. Document:
   - Number of migrated users
   - Migration date
   - Password strategy used
   - Problems encountered and solutions
   - Lessons learned

## Handling Hashed Passwords

### Important Limitation

Keycloak CANNOT import hashed passwords from other systems because:
- It uses specific algorithms (bcrypt, pbkdf2)
- Hash format is different
- It cannot "convert" hashes from other systems

### Available Solutions

1. If you have plain text passwords:
   - You can import them directly
   - Keycloak will hash them automatically

2. If you only have hashes:
   - You cannot import them directly
   - Option 1: Password reset (recommended)
   - Option 2: Temporary passwords
   - Option 3: User Federation (LDAP/AD)

## Best Practices

### Planning

- Phase 1: Migrate users without passwords (temporary)
- Phase 2: Communicate change to users
- Phase 3: Users change passwords on first login
- Phase 4: Deactivate old system

### Communication

Send an email to users with:
- Subject: Migration to new authentication system
- Reason for migration
- Access instructions
- Temporary password (if applicable)
- Steps to change password
- Support contact

### Validation

After migration:
- Verify that all users were migrated
- Test login with some users
- Monitor authentication errors
- Collect user feedback

## Migration Checklist

### Pre-Migration
- [ ] Export users from current system
- [ ] Prepare data in Keycloak format
- [ ] Decide password strategy
- [ ] Create or verify migration script
- [ ] Test migration in development environment
- [ ] Prepare communication for users

### Migration
- [ ] Execute migration in production
- [ ] Verify migrated users
- [ ] Validate passwords set
- [ ] Confirm roles assigned
- [ ] Send notifications to users

### Post-Migration
- [ ] Test authentication with test users
- [ ] Monitor logs and errors
- [ ] Collect user feedback
- [ ] Resolve encountered problems
- [ ] Document completed process
- [ ] Deactivate old system (when ready)

## Available Tools

### Migration Script

A Python script is provided in the scripts/ folder that allows:
- Migrate users from JSON file
- Set passwords
- Automatically assign roles
- Dry-run mode for testing
- Handle existing users

### Keycloak Admin CLI

Alternative using Keycloak command line:
- Configure administrator credentials
- Import users from JSON file
- Manage users and roles

### Keycloak REST API

For custom integrations:
- Endpoints to create users
- Endpoints to set passwords
- Endpoints to assign roles
- Complete documentation available

## References

- Keycloak User Management Documentation
- Keycloak REST API Documentation
- User Federation Documentation
- Keycloak Admin CLI Guide
