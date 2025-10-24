"""
Environment-Aware Asset Helper for Python Projects

This utility provides automatic asset URL resolution based on environment:
- Development: Uses local file paths
- Production: Uses CDN URLs
- Test: Configurable behavior

Compatible with FastAPI, Flask, Django, and standalone Python applications.

Version: 1.0.0
License: MIT
"""

import os
import re
from enum import Enum
from functools import lru_cache
from typing import Literal, Optional, List, Dict
from urllib.parse import urlparse


class AssetMode(Enum):
    """
    Asset resolution mode

    - LOCAL: Always use local paths
    - CDN: Always use CDN URLs
    - AUTO: Automatic based on environment (default)
    """
    LOCAL = 'local'
    CDN = 'cdn'
    AUTO = 'auto'


# Type alias for environment-specific strategies
EnvMode = Literal['cdn-production-local-dev', 'cdn-always', 'local-always']


class AssetResolver:
    """
    AssetResolver - Singleton class for environment-aware asset URL resolution

    Provides cached environment detection and URL resolution logic.

    Examples:
        >>> resolver = AssetResolver.get_instance()
        >>> url = resolver.get_asset_url('/media/logo.png', 'https://cdn.example.com/logos/logo.png')
        >>> print(url)
        '/media/logo.png'  # in development
        'https://cdn.example.com/logos/logo.png'  # in production
    """

    _instance: Optional['AssetResolver'] = None

    def __init__(self):
        """Private constructor - use get_instance() instead"""
        if AssetResolver._instance is not None:
            raise RuntimeError("Use AssetResolver.get_instance() instead of constructor")

        self.environment = self._detect_environment()
        self.asset_mode = self._detect_asset_mode()

    @classmethod
    def get_instance(cls) -> 'AssetResolver':
        """Get singleton instance of AssetResolver"""
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
            cls._instance.__init__()
        return cls._instance

    @classmethod
    def reset_instance(cls) -> None:
        """Reset singleton instance (useful for testing)"""
        cls._instance = None

    @lru_cache(maxsize=1)
    def _detect_environment(self) -> str:
        """
        Detect current environment from ENVIRONMENT or PYTHON_ENV variables

        Returns:
            'production', 'development', or 'test'
        """
        # Check ENVIRONMENT first (most common in Python)
        env = os.getenv('ENVIRONMENT', '').lower()
        if env in ('production', 'prod'):
            return 'production'
        if env in ('development', 'dev'):
            return 'development'
        if env == 'test':
            return 'test'

        # Fallback to PYTHON_ENV
        python_env = os.getenv('PYTHON_ENV', '').lower()
        if python_env in ('production', 'prod'):
            return 'production'
        if python_env in ('development', 'dev'):
            return 'development'
        if python_env == 'test':
            return 'test'

        # Default to development
        return 'development'

    @lru_cache(maxsize=1)
    def _detect_asset_mode(self) -> AssetMode:
        """
        Detect asset mode from ASSET_MODE environment variable

        Returns:
            AssetMode enum value
        """
        asset_mode = os.getenv('ASSET_MODE', '').lower()

        if asset_mode == 'local':
            return AssetMode.LOCAL
        if asset_mode == 'cdn':
            return AssetMode.CDN

        return AssetMode.AUTO

    def _validate_local_path(self, path: str) -> bool:
        """
        Validate local path to prevent directory traversal

        Args:
            path: Local file path

        Returns:
            True if valid, False otherwise
        """
        if not path or not isinstance(path, str):
            return False

        # Prevent directory traversal attacks
        if '..' in path:
            return False

        # Should start with / or ./
        if not path.startswith('/') and not path.startswith('./'):
            return False

        return True

    def _validate_cdn_url(self, url: str) -> bool:
        """
        Validate CDN URL format

        Args:
            url: CDN URL

        Returns:
            True if valid, False otherwise
        """
        if not url or not isinstance(url, str):
            return False

        try:
            parsed = urlparse(url)

            # In production, require HTTPS
            if self.environment == 'production' and parsed.scheme != 'https':
                print(f"[AssetResolver] Warning: CDN URL should use HTTPS in production: {url}")
                return False

            return parsed.scheme in ('http', 'https')
        except Exception:
            return False

    def _should_use_cdn(self, env_mode: EnvMode = 'cdn-production-local-dev') -> bool:
        """
        Determine whether to use CDN based on environment and mode

        Args:
            env_mode: Environment mode strategy

        Returns:
            True if CDN should be used, False otherwise
        """
        # Handle explicit asset mode override
        if self.asset_mode == AssetMode.CDN:
            return True
        if self.asset_mode == AssetMode.LOCAL:
            return False

        # Handle envMode strategies
        if env_mode == 'cdn-always':
            return True
        elif env_mode == 'local-always':
            return False
        else:  # cdn-production-local-dev (default)
            return self.environment == 'production'

    def get_asset_url(
        self,
        local_path: str,
        cdn_url: str,
        env_mode: EnvMode = 'cdn-production-local-dev'
    ) -> str:
        """
        Get environment-aware asset URL

        Args:
            local_path: Local file path (e.g., '/media/logo.png')
            cdn_url: CDN URL (e.g., 'https://cdn.example.com/logos/logo.png')
            env_mode: Environment mode strategy (default: 'cdn-production-local-dev')

        Returns:
            Resolved asset URL based on environment

        Raises:
            ValueError: If both paths are invalid

        Examples:
            >>> resolver = AssetResolver.get_instance()

            # Default behavior: CDN in prod, local in dev
            >>> url1 = resolver.get_asset_url('/media/logo.png', 'https://cdn.example.com/logo.png')

            # Always use CDN
            >>> url2 = resolver.get_asset_url(
            ...     '/media/banner.jpg',
            ...     'https://cdn.example.com/banner.jpg',
            ...     'cdn-always'
            ... )

            # Always use local
            >>> url3 = resolver.get_asset_url(
            ...     '/media/icon.svg',
            ...     'https://cdn.example.com/icon.svg',
            ...     'local-always'
            ... )
        """
        # Validate inputs
        is_local_valid = self._validate_local_path(local_path)
        is_cdn_valid = self._validate_cdn_url(cdn_url)

        if not is_local_valid and not is_cdn_valid:
            raise ValueError(
                f"[AssetResolver] Invalid asset paths: "
                f'local="{local_path}", cdn="{cdn_url}"'
            )

        # Determine which URL to use
        use_cdn = self._should_use_cdn(env_mode)

        if use_cdn and is_cdn_valid:
            return cdn_url

        if not use_cdn and is_local_valid:
            return local_path

        # Fallback logic
        if is_local_valid:
            print(f"[AssetResolver] Warning: Falling back to local path: {local_path}")
            return local_path

        if is_cdn_valid:
            print(f"[AssetResolver] Warning: Falling back to CDN URL: {cdn_url}")
            return cdn_url

        raise ValueError("[AssetResolver] Cannot resolve asset URL")

    def get_environment(self) -> str:
        """Get current environment"""
        return self.environment

    def get_asset_mode(self) -> AssetMode:
        """Get current asset mode"""
        return self.asset_mode


def get_asset_url(
    local_path: str,
    cdn_url: str,
    env_mode: EnvMode = 'cdn-production-local-dev'
) -> str:
    """
    Convenience function for getting asset URL without creating resolver instance

    Args:
        local_path: Local file path
        cdn_url: CDN URL
        env_mode: Environment mode strategy

    Returns:
        Resolved asset URL

    Examples:
        >>> from lib.assets import get_asset_url

        >>> logo_url = get_asset_url('/media/logo.png', 'https://cdn.example.com/logo.png')
        >>> print(logo_url)
        '/media/logo.png'  # in development

        >>> # FastAPI example
        >>> from fastapi import FastAPI
        >>> from lib.assets import get_asset_url

        >>> app = FastAPI()

        >>> @app.get("/")
        >>> def read_root():
        ...     return {
        ...         "logo": get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png')
        ...     }

        >>> # Flask example
        >>> from flask import Flask
        >>> from lib.assets import get_asset_url

        >>> app = Flask(__name__)

        >>> @app.route("/")
        >>> def index():
        ...     logo_url = get_asset_url('/static/logo.png', 'https://cdn.example.com/logo.png')
        ...     return f'<img src="{logo_url}" />'
    """
    resolver = AssetResolver.get_instance()
    return resolver.get_asset_url(local_path, cdn_url, env_mode)


def batch_resolve_assets(configs: List[Dict[str, str]]) -> List[str]:
    """
    Batch resolve multiple assets

    Args:
        configs: List of asset configurations with keys:
                - local_path: Local file path
                - cdn_url: CDN URL
                - env_mode: (optional) Environment mode strategy

    Returns:
        List of resolved URLs in same order

    Examples:
        >>> from lib.assets import batch_resolve_assets

        >>> urls = batch_resolve_assets([
        ...     {
        ...         'local_path': '/media/logo.png',
        ...         'cdn_url': 'https://cdn.example.com/logo.png'
        ...     },
        ...     {
        ...         'local_path': '/media/banner.jpg',
        ...         'cdn_url': 'https://cdn.example.com/banner.jpg'
        ...     },
        ...     {
        ...         'local_path': '/media/icon.svg',
        ...         'cdn_url': 'https://cdn.example.com/icon.svg',
        ...         'env_mode': 'cdn-always'
        ...     }
        ... ])
        >>> logo_url, banner_url, icon_url = urls
    """
    resolver = AssetResolver.get_instance()

    results = []
    for config in configs:
        local_path = config.get('local_path', '')
        cdn_url = config.get('cdn_url', '')
        env_mode = config.get('env_mode', 'cdn-production-local-dev')

        url = resolver.get_asset_url(local_path, cdn_url, env_mode)
        results.append(url)

    return results


# Convenience exports
__all__ = [
    'AssetMode',
    'EnvMode',
    'AssetResolver',
    'get_asset_url',
    'batch_resolve_assets',
]
