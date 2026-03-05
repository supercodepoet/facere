# Application Definition

We creating a modern, web based TODO list application called Facere. I know there are a ton of these
type applications already on the web. I want to take a new approach to the UI/UX focusing on being
fun and friendly. I want this application to be a joy to use and maek the user want to come back
and use it to manage all their TODO lists. This application should be responsive to all types
of mobile devices, as well as, computer screens.

# Techinical Setup

We are using the latest Ruby on Rails 8.1 web application framework. We want to keep this application
as vanilla Rails as possible. We will use all the features available in modern Rails. When in doubt
you can look at the Rails Guides (https://guides.rubyonrails.org) to determine what tools are
available and how to use them. We want to use all the Hotwire tools as well to manage front-end
interaction.

For the HTML, CSS, and JS of the application we want to leverage Web Awesome Pro (https://webawesome.com)
for all the components, theming, and our design system. We want to make sure all the hooks play
nicely with Stimulus. For our iconography we want to use Font Awesome Pro (https://fontawesome.com).

For a refernce application on how to build a modern, vanilla Ruby on Rails application you can
refer to the Fizzy codebase by 37signals found at https://github.com/basecamp/fizzy. Use all modern
techniques for building a production Ruby on Rails application for scalability, maintainability, and
extensability.

## Follow Clean Architecture and Domain Driven Design principles:

### General Principles

- **Early return pattern**: Always use early returns when possible, over nested conditions for better readability
- Avoid code duplication through creation of reusable functions and modules
- Decompose long (more than 80 lines of code) components and functions into multiple smaller components and functions. If they cannot be used anywhere else, keep it in the same file. But if file longer than 200 lines of code, it should be split into multiple files.
- Use arrow functions instead of function declarations when possible

### Best Practices

#### Library-First Approach

- **ALWAYS search for existing solutions before writing custom code**
  - Check npm for existing libraries that solve the problem
  - Evaluate existing services/SaaS solutions
  - Consider third-party APIs for common functionality
- Use libraries instead of writing your own utils or helpers. For example, use `cockatiel` instead of writing your own retry logic.
- **When custom code IS justified:**
  - Specific business logic unique to the domain
  - Performance-critical paths with special requirements
  - When external dependencies would be overkill
  - Security-sensitive code requiring full control
  - When existing solutions don't meet requirements after thorough evaluation

#### Architecture and Design

- **Clean Architecture & DDD Principles:**
  - Follow domain-driven design and ubiquitous language
  - Separate domain entities from infrastructure concerns
  - Keep business logic independent of frameworks
  - Define use cases clearly and keep them isolated
- **Naming Conventions:**
  - **AVOID** generic names: `utils`, `helpers`, `common`, `shared`
  - **USE** domain-specific names: `OrderCalculator`, `UserAuthenticator`, `InvoiceGenerator`
  - Follow bounded context naming patterns
  - Each module should have a single, clear purpose
- **Separation of Concerns:**
  - Do NOT mix business logic with UI components
  - Keep database queries out of controllers
  - Maintain clear boundaries between contexts
  - Ensure proper separation of responsibilities

#### Anti-Patterns to Avoid

- **NIH (Not Invented Here) Syndrome:**
  - Don't build custom auth when Auth0/Supabase exists
  - Don't write custom state management instead of using Redux/Zustand
  - Don't create custom form validation instead of using established libraries
- **Poor Architectural Choices:**
  - Mixing business logic with UI components
  - Database queries directly in controllers
  - Lack of clear separation of concerns
- **Generic Naming Anti-Patterns:**
  - `utils.js` with 50 unrelated functions
  - `helpers/misc.js` as a dumping ground
  - `common/shared.js` with unclear purpose
- Remember: Every line of custom code is a liability that needs maintenance, testing, and documentation

#### Code Quality

- Proper error handling with typed catch blocks
- Break down complex logic into smaller, reusable functions
- Avoid deep nesting (max 3 levels)
- Keep functions focused and under 50 lines when possible
- Keep files focused and under 200 lines of code when possible
