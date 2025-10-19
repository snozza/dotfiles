# Development Guidelines for Claude

Always start with temporal acknowledgement - run Bash date command.

### **Development Partnership**

We build production-ready code together. I will handle the implementation details while you guide the architecture and identify potential complexities early in the process.

### **Core Workflow: Research → Plan → Implement → Validate**

Every feature should begin with the following declaration: "Let me research the codebase and create a plan before implementing."

*   **Research**: Understand existing patterns, architecture, and the flow of data within the application.
*   **Plan**: Propose a technical approach and verify it with you.
*   **Implement**: Build the feature, complete with tests and comprehensive error handling.
*   **Validate**: ALWAYS run formatters, linters, and tests after implementation to ensure code quality and consistency.

### **Code Organization**

Maintaining a clean and organized codebase is crucial for scalability.

*   **Keep functions small and focused**: If you find the need for comments to explain different sections within a single function, it's a sign that it should be split into smaller, more specialized functions.
*   **Group related functionality**: Organize code into modules with clear responsibilities. A typical project structure might separate concerns into directories like `controllers`, `services`, `models`, and `routes`.
*   **Prefer many small files over a few large ones**: This enhances readability and makes it easier for developers to navigate the codebase. The use of `index.ts` barrel files can simplify imports from modules with multiple files.

### **Architecture Principles**

This is always a feature branch:

*   **Delete old code completely**: No deprecation is needed.
*   **No versioned names**: Avoid names like `processV2`, `handleNew`, or `ClientOld`.
*   **No migration code unless explicitly requested**.
*   **No "removed code" comments**: Simply delete it.

Prefer explicit over implicit:

*   **Clear function and variable names over clever abstractions**: Code should be self-documenting whenever possible.
*   **Obvious data flow over hidden magic**: A developer should be able to trace the flow of data through the application without difficulty.
*   **Direct dependencies over service locators**.

### **TypeScript/Node.js Development Standards**

#### **Required Patterns**

*   **Embrace static typing**: Avoid using `any` as it undermines the benefits of TypeScript. Utilize interfaces and types to define clear contracts for your data structures. Enabling `strict` mode in your `tsconfig.json` is highly recommended.
*   **Use Promises and async/await for asynchronous operations**: Instead of callbacks, leverage modern asynchronous patterns for more readable and maintainable code.
*   **Early returns to reduce nesting**: Flatten your code by handling edge cases and errors at the beginning of a function.
*   **Handle errors gracefully**: Implement a centralized error-handling mechanism, such as custom middleware in an Express application. Ensure you're catching promise rejections.
*   **Use dependency injection**: This practice makes your code more modular, testable, and maintainable.
*   **Document exported symbols with TSDoc**: Proper documentation helps prevent misuse of your code and makes it easier for other developers to understand.

#### **Problem Solving**

*   **When stuck**: Stop. The simplest solution is usually the correct one.
*   **When uncertain**: "Let me analyze this architecture further."
*   **When choosing**: "I see approach A (simple) vs B (flexible). Which do you prefer?"

Your guidance is crucial in preventing over-engineering. When there is uncertainty about an implementation, it is best to pause and ask for direction.

### **Testing Strategy**

The approach to testing should match the complexity of the code.

*   **Complex business logic**: Write tests first (TDD).
*   **Simple CRUD operations**: Write the code first, then the tests.
*   **Hot paths**: Add benchmarks after implementation.

**What to avoid in tests:**
*   DO NOT test CSS classes, styling attributes, or icon presence
*   DO NOT test implementation details like specific Tailwind classes
*   Focus on behavior and functionality, not visual implementation
*   Style tests are flaky and provide little value

**Security is always a priority**:
*   Validate all user inputs to prevent injection attacks.
*   Use environment variables to store sensitive information; do not hardcode them.
*   Keep dependencies up to date to patch known vulnerabilities.
*   Implement robust authentication and authorization mechanisms.

**Performance rule**: Measure before optimizing. No guessing.

### **Progress Tracking**

*   **Todo comments**: Use `// TODO:` for task management within the code.
*   **Clear naming**: Apply consistent and descriptive naming conventions for all code elements.
*   **Focus on maintainable solutions over clever abstractions**.

### **Code Hygiene**

**Import Management:**
*   Use absolute imports only (`@/` for backend, `@` for frontend) - never relative paths like `../../`
*   External packages first, then internal imports alphabetically
*   Use `import type` for TypeScript type-only imports
*   Delete all unused imports and variables immediately

**Pre-commit Requirements:**
*   NEVER commit code with failing tests
*   NEVER commit code with linting errors
*   NEVER commit code with TypeScript errors
*   Run formatters, linters, and tests before every commit

**Code Cleanliness:**
*   Delete commented-out code completely (no "removed code" comments)
*   No `console.log` in production code (use `console.error` for errors or proper logging)
*   Remove unused variables, functions, and imports
*   Clean up debugging code before committing

**Validation Patterns:**
*   Early returns for validation errors (avoid deep nesting)
*   Validate inputs at API boundaries (Joi schemas for backend)
*   Type safety over runtime checks when possible
