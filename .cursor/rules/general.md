# General Coding Standards

## 🎯 Core Principles

### Code Quality
- Write self-documenting code with clear variable and function names
- Follow the Single Responsibility Principle (SRP)
- Keep functions small and focused (max 50 lines)
- Prefer composition over inheritance
- Use meaningful comments for complex business logic only

### File Organization
- **500-Line Limit**: No file should exceed 500 lines of code
- **Automatic Splitting**: When files exceed the limit, split them by logical responsibilities
- **Modular Design**: Prefer multiple focused files over single large files
- **Clean Separation**: Maintain clear interfaces between split modules

### Code Structure
- **Single Responsibility**: Each file should have one clear purpose
- **Dependency Injection**: Always use service parameters instead of global imports
- **Interface First**: Define contracts before implementations
- **Clean Architecture**: Maintain strict layer separation (interfaces → core → implementations)

## 📁 File Naming Conventions

### General Rules
- Use kebab-case for file names: `user-service.js`, `auth-middleware.js`
- Use PascalCase for component files: `UserProfile.jsx`, `AuthButton.tsx`
- Use SCREAMING_SNAKE_CASE for constants files: `API_CONSTANTS.js`
- Include file type in name when helpful: `user.model.js`, `auth.service.js`

### Directory Structure
```
src/
├── components/          # Reusable UI components
├── pages/              # Page-level components
├── services/           # Business logic and API calls
├── utils/              # Pure utility functions
├── hooks/              # Custom hooks (React)
├── types/              # Type definitions
├── constants/          # App constants
└── assets/             # Static assets
```

## 🔧 Code Style Guidelines

### Variable Naming
- Use descriptive names: `getUserById` not `getUser`
- Use camelCase for variables and functions
- Use PascalCase for classes and components
- Use SCREAMING_SNAKE_CASE for constants
- Avoid abbreviations unless widely understood

### Function Design
- Pure functions when possible (no side effects)
- Single purpose per function
- Return early to reduce nesting
- Use guard clauses for validation
- Prefer async/await over promises chains

### Error Handling
- Always handle errors explicitly
- Use try-catch blocks for async operations
- Return meaningful error messages
- Log errors with context for debugging
- Fail fast with clear error messages

## 📚 Documentation Standards

### Code Comments
- **What**: Explain complex business logic and algorithms
- **Why**: Document non-obvious decisions and trade-offs
- **How**: Only when the implementation is particularly complex
- Avoid comments that restate the code

### Function Documentation
```javascript
/**
 * Calculates user engagement score based on activity metrics
 * @param {Object} userActivity - User activity data
 * @param {number} userActivity.logins - Number of logins in period
 * @param {number} userActivity.actions - Number of actions taken
 * @param {number} timeWindow - Days to calculate over
 * @returns {number} Engagement score between 0-100
 */
function calculateEngagementScore(userActivity, timeWindow) {
  // Implementation
}
```

## 🧪 Testing Requirements

### Test Coverage
- **Comprehensive Coverage**: All utility modules must have unit tests
- **Mock External Services**: Use dependency injection for testable code
- **Integration Tests**: Test service interactions in isolated environments
- **Health Monitoring**: Include health checks for all external dependencies

### Test Structure
- Follow AAA pattern: Arrange, Act, Assert
- One assertion per test when possible
- Use descriptive test names: `should_return_error_when_user_not_found`
- Test edge cases and error conditions
- Mock external dependencies

### Test File Organization
```
src/
├── components/
│   ├── UserProfile.jsx
│   └── UserProfile.test.jsx
├── services/
│   ├── user-service.js
│   └── user-service.test.js
```

## 🔄 Git Commit Standards

### Commit Message Format
```
type(scope): description

[optional body]

[optional footer]
```

### Commit Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```
feat(auth): add password reset functionality
fix(api): handle null response in user service
docs(readme): update installation instructions
refactor(utils): extract common date formatting logic
```

## 🛡️ Security Guidelines

### Input Validation
- Validate all user inputs
- Sanitize data before database operations
- Use parameterized queries to prevent SQL injection
- Implement rate limiting on API endpoints

### Sensitive Data
- Never commit secrets or API keys
- Use environment variables for configuration
- Encrypt sensitive data at rest
- Use HTTPS for all data transmission

### Authentication & Authorization
- Implement proper session management
- Use strong password requirements
- Implement proper RBAC (Role-Based Access Control)
- Log security-relevant events

## 🚀 Performance Guidelines

### Code Optimization
- Avoid premature optimization
- Profile before optimizing
- Use efficient algorithms and data structures
- Implement caching where appropriate

### Bundle Optimization
- Tree-shake unused code
- Lazy load non-critical components
- Optimize images and assets
- Minimize bundle size

## 🔧 Development Workflow

### Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Functions are properly tested
- [ ] Documentation is updated
- [ ] No security vulnerabilities
- [ ] Performance impact considered
- [ ] Error handling implemented

### Pull Request Guidelines
- Keep PRs small and focused
- Include clear description of changes
- Reference related issues
- Update documentation if needed
- Ensure CI passes before requesting review

---

**Version**: 1.0  
**Last Updated**: [Date]  
**Review Cycle**: Monthly