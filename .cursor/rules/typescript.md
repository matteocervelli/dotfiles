# TypeScript Coding Standards

## 🎯 TypeScript Configuration

### Core Principles
- Strict type checking enabled
- No `any` types unless absolutely necessary
- Prefer interfaces over type aliases for objects
- Use generics for reusable components
- Leverage TypeScript's inference when possible

### tsconfig.json Best Practices
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true
  }
}
```

## 🏗️ Type Definitions

### Interface Design
```typescript
// ✅ Good: Clear, descriptive interface
interface UserProfile {
  readonly id: string;
  email: string;
  firstName: string;
  lastName: string;
  createdAt: Date;
  updatedAt: Date;
  preferences?: UserPreferences;
}

// ✅ Good: Extending interfaces
interface AdminUser extends UserProfile {
  permissions: Permission[];
  lastLogin: Date;
}
```

### Type vs Interface
```typescript
// ✅ Use interfaces for object shapes
interface ApiResponse<T> {
  data: T;
  status: number;
  message: string;
}

// ✅ Use types for unions, primitives, computed types
type Status = 'loading' | 'success' | 'error';
type UserRole = 'admin' | 'user' | 'guest';
type EventHandler<T> = (event: T) => void;
```

### Generic Types
```typescript
// ✅ Good: Descriptive generic constraints
interface Repository<T extends { id: string }> {
  findById(id: string): Promise<T | null>;
  create(entity: Omit<T, 'id'>): Promise<T>;
  update(id: string, updates: Partial<T>): Promise<T>;
  delete(id: string): Promise<void>;
}

// ✅ Good: Multiple generic parameters with defaults
interface ApiClient<TRequest = unknown, TResponse = unknown> {
  request<T = TResponse>(
    endpoint: string, 
    data?: TRequest
  ): Promise<T>;
}
```

## 🎯 Function and Method Typing

### Function Signatures
```typescript
// ✅ Good: Explicit return types for public APIs
function calculateTax(amount: number, rate: number): number {
  return amount * rate;
}

// ✅ Good: Async function with proper typing
async function fetchUser(id: string): Promise<UserProfile | null> {
  try {
    const response = await api.get(`/users/${id}`);
    return response.data;
  } catch (error) {
    if (error.status === 404) return null;
    throw error;
  }
}

// ✅ Good: Function overloads for different parameter combinations
function createElement(tag: 'img'): HTMLImageElement;
function createElement(tag: 'input'): HTMLInputElement;
function createElement(tag: string): HTMLElement;
function createElement(tag: string): HTMLElement {
  return document.createElement(tag);
}
```

### Method Typing in Classes
```typescript
class UserService {
  private readonly apiClient: ApiClient;

  constructor(apiClient: ApiClient) {
    this.apiClient = apiClient;
  }

  // ✅ Good: Explicit return type, proper error handling
  async getUserById(id: string): Promise<UserProfile> {
    if (!id.trim()) {
      throw new Error('User ID is required');
    }

    const user = await this.apiClient.get<UserProfile>(`/users/${id}`);
    if (!user) {
      throw new Error(`User not found: ${id}`);
    }

    return user;
  }

  // ✅ Good: Generic method with constraints
  async updateUser<T extends Partial<UserProfile>>(
    id: string, 
    updates: T
  ): Promise<UserProfile> {
    return this.apiClient.patch(`/users/${id}`, updates);
  }
}
```

## 🔧 Advanced TypeScript Patterns

### Utility Types Usage
```typescript
// ✅ Good: Leveraging built-in utility types
type CreateUserRequest = Omit<UserProfile, 'id' | 'createdAt' | 'updatedAt'>;
type UserUpdate = Partial<Pick<UserProfile, 'firstName' | 'lastName' | 'email'>>;
type UserResponse = Required<Pick<UserProfile, 'id' | 'email'>> & 
  Partial<Omit<UserProfile, 'id' | 'email'>>;

// ✅ Good: Custom utility types
type NonEmptyArray<T> = [T, ...T[]];
type ApiEndpoints = Record<string, string>;
type EventMap<T> = {
  [K in keyof T]: (payload: T[K]) => void;
};
```

### Discriminated Unions
```typescript
// ✅ Good: Type-safe state management
type ApiState<T> = 
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };

function handleApiState<T>(state: ApiState<T>): void {
  switch (state.status) {
    case 'idle':
      // TypeScript knows no additional properties
      break;
    case 'loading':
      // TypeScript knows no additional properties
      break;
    case 'success':
      // TypeScript knows state.data exists and is type T
      console.log(state.data);
      break;
    case 'error':
      // TypeScript knows state.error exists and is string
      console.error(state.error);
      break;
  }
}
```

### Type Guards
```typescript
// ✅ Good: Custom type guards
function isUserProfile(obj: unknown): obj is UserProfile {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof (obj as UserProfile).id === 'string' &&
    typeof (obj as UserProfile).email === 'string'
  );
}

// ✅ Good: Generic type guard
function isArrayOf<T>(
  items: unknown[], 
  guard: (item: unknown) => item is T
): items is T[] {
  return items.every(guard);
}

// Usage
if (isUserProfile(data)) {
  // TypeScript knows data is UserProfile
  console.log(data.email);
}
```

## 🎨 React with TypeScript

### Component Props
```typescript
// ✅ Good: Explicit props interface
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
  children: React.ReactNode;
}

const Button: React.FC<ButtonProps> = ({ 
  variant, 
  size = 'md', 
  disabled = false, 
  onClick, 
  children 
}) => {
  return (
    <button 
      className={`btn btn-${variant} btn-${size}`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
```

### Hooks Typing
```typescript
// ✅ Good: Custom hook with proper typing
function useApi<T>(url: string): {
  data: T | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
} {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Failed to fetch');
      const result = await response.json() as T;
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return { data, loading, error, refetch: fetchData };
}
```

## 🚫 Common Anti-Patterns to Avoid

### Type Assertions and Any
```typescript
// ❌ Bad: Using any
function processData(data: any): any {
  return data.someProperty;
}

// ✅ Good: Proper typing
function processData<T extends { someProperty: unknown }>(data: T): T['someProperty'] {
  return data.someProperty;
}

// ❌ Bad: Unnecessary type assertion
const userData = response.data as UserProfile;

// ✅ Good: Type guard or proper typing
if (isUserProfile(response.data)) {
  const userData = response.data;
}
```

### Interface Pollution
```typescript
// ❌ Bad: Too many optional properties
interface UserData {
  id?: string;
  email?: string;
  firstName?: string;
  lastName?: string;
  age?: number;
  // ... 20 more optional properties
}

// ✅ Good: Split into focused interfaces
interface UserIdentity {
  id: string;
  email: string;
}

interface UserPersonalInfo {
  firstName: string;
  lastName: string;
  age: number;
}

interface UserProfile extends UserIdentity, UserPersonalInfo {
  createdAt: Date;
}
```

## 🔍 Type Safety Best Practices

### Environment and Configuration
```typescript
// ✅ Good: Type-safe environment variables
interface EnvironmentConfig {
  NODE_ENV: 'development' | 'production' | 'test';
  API_URL: string;
  DATABASE_URL: string;
  JWT_SECRET: string;
}

function getConfig(): EnvironmentConfig {
  const config = {
    NODE_ENV: process.env.NODE_ENV,
    API_URL: process.env.API_URL,
    DATABASE_URL: process.env.DATABASE_URL,
    JWT_SECRET: process.env.JWT_SECRET,
  };

  // Validate required environment variables
  for (const [key, value] of Object.entries(config)) {
    if (!value) {
      throw new Error(`Missing required environment variable: ${key}`);
    }
  }

  return config as EnvironmentConfig;
}
```

### Error Handling
```typescript
// ✅ Good: Type-safe error handling
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number = 500
  ) {
    super(message);
    this.name = 'AppError';
  }
}

type Result<T, E = AppError> = 
  | { success: true; data: T }
  | { success: false; error: E };

async function safeApiCall<T>(
  apiCall: () => Promise<T>
): Promise<Result<T>> {
  try {
    const data = await apiCall();
    return { success: true, data };
  } catch (error) {
    const appError = error instanceof AppError 
      ? error 
      : new AppError('Unknown error', 'UNKNOWN_ERROR');
    return { success: false, error: appError };
  }
}
```

---

**Version**: 1.0  
**Last Updated**: [Date]  
**Review Cycle**: Monthly