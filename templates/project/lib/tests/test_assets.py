"""
Example Test Suite for Python Asset Helper

This is a TEMPLATE test file for projects using the asset helper.
Copy this to your project and customize as needed.

Test Framework: pytest
Location: Copy to your project's tests/ directory

Setup:
    pip install pytest pytest-cov

Run tests:
    pytest tests/test_assets.py -v
    pytest tests/test_assets.py -v --cov=lib.assets
"""

import os
import pytest
from lib.assets import (
    AssetMode,
    AssetResolver,
    get_asset_url,
    batch_resolve_assets,
)


class TestAssetResolver:
    """Test suite for AssetResolver class"""

    @pytest.fixture(autouse=True)
    def setup_and_teardown(self, monkeypatch):
        """Setup and teardown for each test"""
        # Save original environment
        self.original_env = dict(os.environ)

        # Reset singleton instance before each test
        AssetResolver.reset_instance()

        yield

        # Restore environment after each test
        os.environ.clear()
        os.environ.update(self.original_env)
        AssetResolver.reset_instance()

    def test_singleton_pattern(self):
        """Test that AssetResolver uses singleton pattern"""
        instance1 = AssetResolver.get_instance()
        instance2 = AssetResolver.get_instance()
        assert instance1 is instance2

    def test_reset_instance(self):
        """Test that reset_instance creates new instance"""
        instance1 = AssetResolver.get_instance()
        AssetResolver.reset_instance()
        instance2 = AssetResolver.get_instance()
        assert instance1 is not instance2


class TestEnvironmentDetection:
    """Test environment detection logic"""

    @pytest.fixture(autouse=True)
    def reset_resolver(self, monkeypatch):
        """Reset singleton before each test"""
        AssetResolver.reset_instance()
        yield
        AssetResolver.reset_instance()

    def test_detects_production_from_environment(self, monkeypatch):
        """Test detection of production from ENVIRONMENT variable"""
        monkeypatch.setenv('ENVIRONMENT', 'production')
        resolver = AssetResolver.get_instance()
        assert resolver.get_environment() == 'production'

    def test_detects_production_from_prod(self, monkeypatch):
        """Test detection of production from 'prod' value"""
        monkeypatch.setenv('ENVIRONMENT', 'prod')
        resolver = AssetResolver.get_instance()
        assert resolver.get_environment() == 'production'

    def test_detects_development(self, monkeypatch):
        """Test detection of development environment"""
        monkeypatch.setenv('ENVIRONMENT', 'development')
        resolver = AssetResolver.get_instance()
        assert resolver.get_environment() == 'development'

    def test_detects_test(self, monkeypatch):
        """Test detection of test environment"""
        monkeypatch.setenv('ENVIRONMENT', 'test')
        resolver = AssetResolver.get_instance()
        assert resolver.get_environment() == 'test'

    def test_defaults_to_development(self, monkeypatch):
        """Test default environment is development"""
        monkeypatch.delenv('ENVIRONMENT', raising=False)
        monkeypatch.delenv('PYTHON_ENV', raising=False)
        resolver = AssetResolver.get_instance()
        assert resolver.get_environment() == 'development'

    def test_uses_python_env_as_fallback(self, monkeypatch):
        """Test PYTHON_ENV as fallback"""
        monkeypatch.delenv('ENVIRONMENT', raising=False)
        monkeypatch.setenv('PYTHON_ENV', 'production')
        resolver = AssetResolver.get_instance()
        assert resolver.get_environment() == 'production'


class TestAssetModeDetection:
    """Test asset mode detection logic"""

    @pytest.fixture(autouse=True)
    def reset_resolver(self, monkeypatch):
        """Reset singleton before each test"""
        AssetResolver.reset_instance()
        yield
        AssetResolver.reset_instance()

    def test_detects_local_mode(self, monkeypatch):
        """Test detection of local asset mode"""
        monkeypatch.setenv('ASSET_MODE', 'local')
        resolver = AssetResolver.get_instance()
        assert resolver.get_asset_mode() == AssetMode.LOCAL

    def test_detects_cdn_mode(self, monkeypatch):
        """Test detection of CDN asset mode"""
        monkeypatch.setenv('ASSET_MODE', 'cdn')
        resolver = AssetResolver.get_instance()
        assert resolver.get_asset_mode() == AssetMode.CDN

    def test_defaults_to_auto_mode(self, monkeypatch):
        """Test default asset mode is auto"""
        monkeypatch.delenv('ASSET_MODE', raising=False)
        resolver = AssetResolver.get_instance()
        assert resolver.get_asset_mode() == AssetMode.AUTO


class TestURLResolutionDevelopment:
    """Test URL resolution in development environment"""

    @pytest.fixture(autouse=True)
    def setup_dev_env(self, monkeypatch):
        """Setup development environment"""
        monkeypatch.setenv('ENVIRONMENT', 'development')
        AssetResolver.reset_instance()
        yield
        AssetResolver.reset_instance()

    def test_returns_local_path_by_default(self):
        """Test that local path is returned in development"""
        resolver = AssetResolver.get_instance()
        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url == '/media/logo.png'

    def test_returns_cdn_with_cdn_always_mode(self):
        """Test CDN URL with cdn-always mode"""
        resolver = AssetResolver.get_instance()
        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png',
            'cdn-always'
        )
        assert url == 'https://cdn.example.com/logo.png'

    def test_returns_local_with_local_always_mode(self):
        """Test local path with local-always mode"""
        resolver = AssetResolver.get_instance()
        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png',
            'local-always'
        )
        assert url == '/media/logo.png'


class TestURLResolutionProduction:
    """Test URL resolution in production environment"""

    @pytest.fixture(autouse=True)
    def setup_prod_env(self, monkeypatch):
        """Setup production environment"""
        monkeypatch.setenv('ENVIRONMENT', 'production')
        AssetResolver.reset_instance()
        yield
        AssetResolver.reset_instance()

    def test_returns_cdn_url_by_default(self):
        """Test that CDN URL is returned in production"""
        resolver = AssetResolver.get_instance()
        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url == 'https://cdn.example.com/logo.png'

    def test_returns_local_with_local_always_mode(self):
        """Test local path with local-always mode in production"""
        resolver = AssetResolver.get_instance()
        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png',
            'local-always'
        )
        assert url == '/media/logo.png'


class TestInputValidation:
    """Test input validation and security"""

    @pytest.fixture(autouse=True)
    def setup_resolver(self):
        """Setup resolver for each test"""
        AssetResolver.reset_instance()
        self.resolver = AssetResolver.get_instance()

    def test_rejects_directory_traversal(self):
        """Test rejection of directory traversal attempts"""
        with pytest.raises(ValueError):
            self.resolver.get_asset_url(
                '../../../etc/passwd',
                'https://cdn.example.com/logo.png'
            )

    def test_accepts_paths_starting_with_slash(self):
        """Test acceptance of paths starting with /"""
        url = self.resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url is not None

    def test_accepts_paths_starting_with_dot_slash(self):
        """Test acceptance of paths starting with ./"""
        url = self.resolver.get_asset_url(
            './media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url is not None

    def test_rejects_invalid_cdn_url(self):
        """Test rejection of invalid CDN URLs"""
        with pytest.raises(ValueError):
            self.resolver.get_asset_url(
                '/media/logo.png',
                'not-a-url'
            )

    def test_warns_on_http_in_production(self, monkeypatch, capsys):
        """Test warning on HTTP URL in production"""
        monkeypatch.setenv('ENVIRONMENT', 'production')
        AssetResolver.reset_instance()
        resolver = AssetResolver.get_instance()

        with pytest.raises(ValueError):
            resolver.get_asset_url(
                '/media/logo.png',
                'http://cdn.example.com/logo.png'
            )

    def test_rejects_empty_strings(self):
        """Test rejection of empty strings"""
        with pytest.raises(ValueError):
            self.resolver.get_asset_url(
                '',
                'https://cdn.example.com/logo.png'
            )

    def test_rejects_none_values(self):
        """Test rejection of None values"""
        with pytest.raises((ValueError, AttributeError)):
            self.resolver.get_asset_url(
                None,
                'https://cdn.example.com/logo.png'
            )


class TestAssetModeOverride:
    """Test ASSET_MODE environment variable override"""

    @pytest.fixture(autouse=True)
    def reset_resolver(self):
        """Reset singleton before each test"""
        AssetResolver.reset_instance()
        yield
        AssetResolver.reset_instance()

    def test_local_mode_forces_local_in_production(self, monkeypatch):
        """Test ASSET_MODE=local forces local path in production"""
        monkeypatch.setenv('ENVIRONMENT', 'production')
        monkeypatch.setenv('ASSET_MODE', 'local')
        resolver = AssetResolver.get_instance()

        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url == '/media/logo.png'

    def test_cdn_mode_forces_cdn_in_development(self, monkeypatch):
        """Test ASSET_MODE=cdn forces CDN URL in development"""
        monkeypatch.setenv('ENVIRONMENT', 'development')
        monkeypatch.setenv('ASSET_MODE', 'cdn')
        resolver = AssetResolver.get_instance()

        url = resolver.get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url == 'https://cdn.example.com/logo.png'


class TestConvenienceFunctions:
    """Test convenience functions"""

    @pytest.fixture(autouse=True)
    def setup_dev_env(self, monkeypatch):
        """Setup development environment"""
        monkeypatch.setenv('ENVIRONMENT', 'development')
        AssetResolver.reset_instance()

    def test_get_asset_url_function(self):
        """Test get_asset_url convenience function"""
        url = get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png'
        )
        assert url == '/media/logo.png'

    def test_get_asset_url_with_env_mode(self):
        """Test get_asset_url with env_mode parameter"""
        url = get_asset_url(
            '/media/logo.png',
            'https://cdn.example.com/logo.png',
            'cdn-always'
        )
        assert url == 'https://cdn.example.com/logo.png'


class TestBatchResolution:
    """Test batch asset resolution"""

    @pytest.fixture(autouse=True)
    def setup_dev_env(self, monkeypatch):
        """Setup development environment"""
        monkeypatch.setenv('ENVIRONMENT', 'development')
        AssetResolver.reset_instance()

    def test_resolves_multiple_assets(self):
        """Test batch resolution of multiple assets"""
        urls = batch_resolve_assets([
            {
                'local_path': '/media/logo.png',
                'cdn_url': 'https://cdn.example.com/logo.png'
            },
            {
                'local_path': '/media/banner.jpg',
                'cdn_url': 'https://cdn.example.com/banner.jpg'
            },
            {
                'local_path': '/media/icon.svg',
                'cdn_url': 'https://cdn.example.com/icon.svg'
            }
        ])

        assert len(urls) == 3
        assert urls[0] == '/media/logo.png'
        assert urls[1] == '/media/banner.jpg'
        assert urls[2] == '/media/icon.svg'

    def test_supports_different_env_modes(self):
        """Test batch resolution with different env modes"""
        urls = batch_resolve_assets([
            {
                'local_path': '/media/logo.png',
                'cdn_url': 'https://cdn.example.com/logo.png'
            },
            {
                'local_path': '/media/banner.jpg',
                'cdn_url': 'https://cdn.example.com/banner.jpg',
                'env_mode': 'cdn-always'
            }
        ])

        assert urls[0] == '/media/logo.png'
        assert urls[1] == 'https://cdn.example.com/banner.jpg'


class TestEdgeCases:
    """Test edge cases and fallback behavior"""

    @pytest.fixture(autouse=True)
    def setup_resolver(self):
        """Setup resolver for each test"""
        AssetResolver.reset_instance()
        self.resolver = AssetResolver.get_instance()

    def test_falls_back_when_one_path_invalid(self, capsys):
        """Test graceful fallback when one path is invalid"""
        url = self.resolver.get_asset_url(
            '../invalid',
            'https://cdn.example.com/logo.png'
        )
        assert url == 'https://cdn.example.com/logo.png'

        # Check that warning was printed
        captured = capsys.readouterr()
        assert 'Warning' in captured.out or 'Falling back' in captured.out


# Integration tests
class TestIntegration:
    """Integration tests with different frameworks"""

    @pytest.fixture(autouse=True)
    def setup_dev_env(self, monkeypatch):
        """Setup development environment"""
        monkeypatch.setenv('ENVIRONMENT', 'development')
        AssetResolver.reset_instance()

    def test_fastapi_usage_pattern(self):
        """Test typical FastAPI usage pattern"""
        # Simulate FastAPI route
        def get_static_assets():
            return {
                'logo': get_asset_url(
                    '/static/logo.png',
                    'https://cdn.example.com/logo.png'
                ),
                'banner': get_asset_url(
                    '/static/banner.jpg',
                    'https://cdn.example.com/banner.jpg'
                )
            }

        assets = get_static_assets()
        assert assets['logo'] == '/static/logo.png'
        assert assets['banner'] == '/static/banner.jpg'

    def test_ml_model_loading_pattern(self):
        """Test typical ML model loading pattern"""
        model_path = get_asset_url(
            'data/models/whisper-large.bin',
            'https://cdn.example.com/models/whisper-large.bin',
            'local-always'  # Always use local for ML models
        )
        assert model_path == 'data/models/whisper-large.bin'
