# Python Coding Standards

## 🎯 Core Python Principles

### Code Style
- Follow PEP 8 style guide
- Use Black for automatic formatting
- Use Ruff for linting and import sorting
- Maximum line length: 88 characters (Black default)
- Use type hints for all function signatures

### Project Structure
```
src/
├── main.py              # Application entry point
├── config/              # Configuration management
├── models/              # Data models and schemas
├── services/            # Business logic
├── repositories/        # Data access layer
├── utils/               # Utility functions
├── exceptions/          # Custom exceptions
└── tests/               # Test files
```

## 🏗️ Type Hints and Documentation

### Function Signatures
```python
from typing import Dict, List, Optional, Union, TypeVar, Generic
from datetime import datetime

# ✅ Good: Complete type hints
def calculate_tax(amount: float, rate: float) -> float:
    """Calculate tax amount based on principal and rate.
    
    Args:
        amount: The principal amount
        rate: Tax rate as decimal (0.1 for 10%)
        
    Returns:
        The calculated tax amount
        
    Raises:
        ValueError: If amount or rate is negative
    """
    if amount < 0 or rate < 0:
        raise ValueError("Amount and rate must be non-negative")
    return amount * rate

# ✅ Good: Optional parameters and complex types
def create_user(
    email: str,
    first_name: str,
    last_name: str,
    metadata: Optional[Dict[str, Union[str, int]]] = None,
) -> Dict[str, Union[str, datetime]]:
    """Create a new user with the provided information."""
    user_data = {
        "email": email,
        "first_name": first_name,
        "last_name": last_name,
        "created_at": datetime.utcnow(),
    }
    
    if metadata:
        user_data.update(metadata)
    
    return user_data
```

### Class Definitions
```python
from dataclasses import dataclass
from typing import Protocol, ClassVar
from abc import ABC, abstractmethod

# ✅ Good: Dataclass for data containers
@dataclass
class UserProfile:
    id: str
    email: str
    first_name: str
    last_name: str
    created_at: datetime
    is_active: bool = True
    
    def full_name(self) -> str:
        """Get the user's full name."""
        return f"{self.first_name} {self.last_name}"

# ✅ Good: Protocol for interfaces
class EmailProvider(Protocol):
    """Protocol for email service providers."""
    
    def send_email(
        self,
        to: str,
        subject: str,
        body: str,
        from_email: Optional[str] = None,
    ) -> bool:
        """Send an email message."""
        ...

# ✅ Good: Abstract base class for inheritance
class Repository(ABC, Generic[T]):
    """Abstract base repository class."""
    
    @abstractmethod
    async def create(self, entity: T) -> T:
        """Create a new entity."""
        pass
    
    @abstractmethod
    async def get_by_id(self, entity_id: str) -> Optional[T]:
        """Get entity by ID."""
        pass
```

## 🔧 Error Handling and Validation

### Custom Exceptions
```python
# ✅ Good: Specific exception hierarchy
class AppError(Exception):
    """Base application exception."""
    
    def __init__(self, message: str, error_code: str = "APP_ERROR"):
        self.message = message
        self.error_code = error_code
        super().__init__(message)

class ValidationError(AppError):
    """Raised when data validation fails."""
    
    def __init__(self, field: str, message: str):
        self.field = field
        super().__init__(f"Validation error for {field}: {message}", "VALIDATION_ERROR")

class NotFoundError(AppError):
    """Raised when a requested resource is not found."""
    
    def __init__(self, resource: str, identifier: str):
        super().__init__(
            f"{resource} not found: {identifier}",
            "NOT_FOUND"
        )
```

### Validation with Pydantic
```python
from pydantic import BaseModel, validator, Field
from typing import Optional
import re

# ✅ Good: Pydantic models for validation
class CreateUserRequest(BaseModel):
    email: str = Field(..., description="User email address")
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    age: Optional[int] = Field(None, ge=0, le=150)
    
    @validator('email')
    def validate_email(cls, v: str) -> str:
        """Validate email format."""
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, v):
            raise ValueError('Invalid email format')
        return v.lower()
    
    @validator('first_name', 'last_name')
    def validate_names(cls, v: str) -> str:
        """Validate name fields."""
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip().title()

# ✅ Good: Response models
class UserResponse(BaseModel):
    id: str
    email: str
    first_name: str
    last_name: str
    full_name: str
    created_at: datetime
    
    class Config:
        from_attributes = True  # For SQLAlchemy models
```

## 🎯 Async Programming

### Async Functions and Context Managers
```python
import asyncio
import aiohttp
from contextlib import asynccontextmanager
from typing import AsyncGenerator

# ✅ Good: Async service class
class ApiClient:
    def __init__(self, base_url: str, timeout: int = 30):
        self.base_url = base_url
        self.timeout = aiohttp.ClientTimeout(total=timeout)
        self._session: Optional[aiohttp.ClientSession] = None
    
    async def __aenter__(self) -> 'ApiClient':
        """Async context manager entry."""
        self._session = aiohttp.ClientSession(timeout=self.timeout)
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:
        """Async context manager exit."""
        if self._session:
            await self._session.close()
    
    async def get(self, endpoint: str) -> Dict[str, Any]:
        """Make GET request to API endpoint."""
        if not self._session:
            raise RuntimeError("ApiClient must be used as async context manager")
        
        url = f"{self.base_url}{endpoint}"
        async with self._session.get(url) as response:
            response.raise_for_status()
            return await response.json()
    
    async def post(self, endpoint: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Make POST request to API endpoint."""
        if not self._session:
            raise RuntimeError("ApiClient must be used as async context manager")
        
        url = f"{self.base_url}{endpoint}"
        async with self._session.post(url, json=data) as response:
            response.raise_for_status()
            return await response.json()

# ✅ Good: Async generator for streaming data
async def fetch_users_batch(
    api_client: ApiClient, 
    batch_size: int = 100
) -> AsyncGenerator[List[UserProfile], None]:
    """Fetch users in batches from API."""
    offset = 0
    
    while True:
        users_data = await api_client.get(f"/users?limit={batch_size}&offset={offset}")
        users = [UserProfile(**user) for user in users_data['users']]
        
        if not users:
            break
            
        yield users
        offset += batch_size
```

### Error Handling in Async Code
```python
import logging
from typing import TypeVar, Callable, Any

T = TypeVar('T')

# ✅ Good: Async error handling decorator
def handle_async_errors(
    default_return: Any = None,
    log_errors: bool = True
) -> Callable[[Callable[..., Awaitable[T]]], Callable[..., Awaitable[T]]]:
    """Decorator for handling async function errors."""
    
    def decorator(func: Callable[..., Awaitable[T]]) -> Callable[..., Awaitable[T]]:
        async def wrapper(*args, **kwargs) -> T:
            try:
                return await func(*args, **kwargs)
            except Exception as e:
                if log_errors:
                    logging.error(f"Error in {func.__name__}: {str(e)}", exc_info=True)
                
                if default_return is not None:
                    return default_return
                raise
        
        return wrapper
    return decorator

# Usage
@handle_async_errors(default_return=[])
async def fetch_user_data(user_id: str) -> List[Dict[str, Any]]:
    """Fetch user data with error handling."""
    async with ApiClient("https://api.example.com") as client:
        return await client.get(f"/users/{user_id}/data")
```

## 🗄️ Database and ORM Patterns

### SQLAlchemy Models
```python
from sqlalchemy import Column, String, DateTime, Boolean, Integer, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()

# ✅ Good: SQLAlchemy model with proper typing
class User(Base):
    __tablename__ = "users"
    
    id: str = Column(String, primary_key=True)
    email: str = Column(String, unique=True, nullable=False, index=True)
    first_name: str = Column(String, nullable=False)
    last_name: str = Column(String, nullable=False)
    is_active: bool = Column(Boolean, default=True)
    created_at: datetime = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    orders = relationship("Order", back_populates="user")
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, email={self.email})>"

# ✅ Good: Repository pattern
class UserRepository:
    def __init__(self, db_session):
        self.db = db_session
    
    async def create(self, user_data: CreateUserRequest) -> User:
        """Create a new user."""
        user = User(
            id=str(uuid.uuid4()),
            email=user_data.email,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
        )
        
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email address."""
        result = await self.db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
```

## 🧪 Testing Patterns

### Pytest Best Practices
```python
import pytest
from unittest.mock import AsyncMock, patch
from httpx import AsyncClient

# ✅ Good: Test fixtures
@pytest.fixture
async def api_client():
    """Create test API client."""
    async with AsyncClient() as client:
        yield client

@pytest.fixture
def mock_user_data():
    """Sample user data for testing."""
    return {
        "id": "test-user-123",
        "email": "test@example.com",
        "first_name": "Test",
        "last_name": "User",
    }

# ✅ Good: Async test with mocking
@pytest.mark.asyncio
async def test_create_user_success(api_client: AsyncClient, mock_user_data):
    """Test successful user creation."""
    with patch('services.user_service.UserRepository') as mock_repo:
        # Setup mock
        mock_repo.return_value.create = AsyncMock(return_value=User(**mock_user_data))
        
        # Test the endpoint
        response = await api_client.post("/users", json={
            "email": "test@example.com",
            "first_name": "Test",
            "last_name": "User",
        })
        
        # Assertions
        assert response.status_code == 201
        assert response.json()["email"] == "test@example.com"
        mock_repo.return_value.create.assert_called_once()

# ✅ Good: Parametrized tests
@pytest.mark.parametrize("email,expected_valid", [
    ("valid@example.com", True),
    ("invalid-email", False),
    ("", False),
    ("@example.com", False),
])
def test_email_validation(email: str, expected_valid: bool):
    """Test email validation with various inputs."""
    if expected_valid:
        # Should not raise exception
        CreateUserRequest(
            email=email,
            first_name="Test",
            last_name="User"
        )
    else:
        # Should raise validation error
        with pytest.raises(ValueError):
            CreateUserRequest(
                email=email,
                first_name="Test",
                last_name="User"
            )
```

## 🔧 Configuration and Environment

### Settings Management
```python
from pydantic import BaseSettings, Field
from typing import Optional

# ✅ Good: Type-safe settings with Pydantic
class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    app_name: str = Field("My App", description="Application name")
    debug: bool = Field(False, description="Debug mode")
    
    # Database
    database_url: str = Field(..., description="Database connection URL")
    db_pool_size: int = Field(10, description="Database connection pool size")
    
    # External APIs
    api_key: str = Field(..., description="External API key")
    api_timeout: int = Field(30, description="API timeout in seconds")
    
    # JWT
    jwt_secret: str = Field(..., description="JWT signing secret")
    jwt_expire_hours: int = Field(24, description="JWT expiration time")
    
    class Config:
        env_file = ".env"
        case_sensitive = False

# ✅ Good: Singleton settings instance
@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()

# Usage in dependency injection
def get_db_session(settings: Settings = Depends(get_settings)):
    """Database session dependency."""
    # Create and return database session
    pass
```

## 🚀 Performance and Best Practices

### Efficient Data Processing
```python
from functools import lru_cache
from typing import Iterator
import asyncio

# ✅ Good: Generator for memory efficiency
def process_large_dataset(file_path: str) -> Iterator[Dict[str, Any]]:
    """Process large dataset line by line."""
    with open(file_path, 'r') as file:
        for line in file:
            data = json.loads(line)
            # Process data
            yield transform_data(data)

# ✅ Good: Cached expensive computations
@lru_cache(maxsize=128)
def expensive_calculation(input_value: str) -> str:
    """Cache expensive computation results."""
    # Simulate expensive operation
    time.sleep(1)
    return f"processed_{input_value}"

# ✅ Good: Batch processing with asyncio
async def process_items_in_batches(
    items: List[str], 
    batch_size: int = 10
) -> List[str]:
    """Process items in concurrent batches."""
    results = []
    
    for i in range(0, len(items), batch_size):
        batch = items[i:i + batch_size]
        batch_results = await asyncio.gather(
            *[process_single_item(item) for item in batch],
            return_exceptions=True
        )
        results.extend(batch_results)
    
    return results
```

---

**Version**: 1.0  
**Last Updated**: [Date]  
**Review Cycle**: Monthly