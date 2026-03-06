# Definition

We need a entry screen to the web application that allows a user to either sign in to their existing
account or to sign up for a new account. The default method with be standard email address and password.
For creating an account we will need name, email address, password (which they need to confirm). We should
have a place for the user to accept terms of service and privacy policy. If the user that wants to log
into the system has forgotten their password, we need a worflow to help them reset that password. We
also want to support all the major 3rd party authentication types like Google, Facebook, Apple, etc.

This should be a painless sign up process and an even simplier sign in process. We want to make sure
we give clear but security aware errors for any issues that may arise. We also want to consider adding
two-factor authentication to the default email and password account creation.

# Requirements
- Email address needs to be unique for the system
- Follow standard password creation policy for major web applications
- On account creation the following are required:
  - Name
  - Email Address
  - Password
  - Password Confirmation
  - Acceptance of TOS and PP
- Errors should be clearly visible and easy to see