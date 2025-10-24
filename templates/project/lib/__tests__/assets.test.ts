/**
 * Example Test Suite for TypeScript Asset Helper
 *
 * This is a TEMPLATE test file for projects using the asset helper.
 * Copy this to your project and customize as needed.
 *
 * Test Framework: Jest or Vitest
 * Location: Copy to your project's __tests__ or test directory
 *
 * Setup for Jest:
 *   npm install --save-dev jest @types/jest ts-jest
 *
 * Setup for Vitest:
 *   npm install --save-dev vitest @vitest/ui
 */

import {
  AssetResolver,
  getAssetUrl,
  useAsset,
  batchResolveAssets,
  type AssetMode,
  type EnvMode,
} from '../assets';

describe('AssetResolver', () => {
  let originalEnv: NodeJS.ProcessEnv;

  beforeEach(() => {
    // Save original environment
    originalEnv = { ...process.env };

    // Reset singleton instance for each test
    AssetResolver.resetInstance();
  });

  afterEach(() => {
    // Restore original environment
    process.env = originalEnv;
  });

  describe('Environment Detection', () => {
    test('detects production environment', () => {
      process.env.NODE_ENV = 'production';
      const resolver = AssetResolver.getInstance();
      expect(resolver.getEnvironment()).toBe('production');
    });

    test('detects development environment', () => {
      process.env.NODE_ENV = 'development';
      const resolver = AssetResolver.getInstance();
      expect(resolver.getEnvironment()).toBe('development');
    });

    test('detects test environment', () => {
      process.env.NODE_ENV = 'test';
      const resolver = AssetResolver.getInstance();
      expect(resolver.getEnvironment()).toBe('test');
    });

    test('defaults to development when NODE_ENV not set', () => {
      delete process.env.NODE_ENV;
      const resolver = AssetResolver.getInstance();
      expect(resolver.getEnvironment()).toBe('development');
    });
  });

  describe('Asset Mode Detection', () => {
    test('detects local asset mode', () => {
      process.env.ASSET_MODE = 'local';
      const resolver = AssetResolver.getInstance();
      expect(resolver.getAssetMode()).toBe('local');
    });

    test('detects cdn asset mode', () => {
      process.env.ASSET_MODE = 'cdn';
      const resolver = AssetResolver.getInstance();
      expect(resolver.getAssetMode()).toBe('cdn');
    });

    test('defaults to auto asset mode', () => {
      delete process.env.ASSET_MODE;
      const resolver = AssetResolver.getInstance();
      expect(resolver.getAssetMode()).toBe('auto');
    });
  });

  describe('Singleton Pattern', () => {
    test('returns same instance on multiple calls', () => {
      const instance1 = AssetResolver.getInstance();
      const instance2 = AssetResolver.getInstance();
      expect(instance1).toBe(instance2);
    });

    test('resets instance correctly', () => {
      const instance1 = AssetResolver.getInstance();
      AssetResolver.resetInstance();
      const instance2 = AssetResolver.getInstance();
      expect(instance1).not.toBe(instance2);
    });
  });

  describe('URL Resolution - Development Environment', () => {
    beforeEach(() => {
      process.env.NODE_ENV = 'development';
    });

    test('returns local path in development by default', () => {
      const resolver = AssetResolver.getInstance();
      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png'
      );
      expect(url).toBe('/media/logo.png');
    });

    test('returns CDN URL with cdn-always mode', () => {
      const resolver = AssetResolver.getInstance();
      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png',
        'cdn-always'
      );
      expect(url).toBe('https://cdn.example.com/logo.png');
    });

    test('returns local path with local-always mode', () => {
      const resolver = AssetResolver.getInstance();
      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png',
        'local-always'
      );
      expect(url).toBe('/media/logo.png');
    });
  });

  describe('URL Resolution - Production Environment', () => {
    beforeEach(() => {
      process.env.NODE_ENV = 'production';
    });

    test('returns CDN URL in production by default', () => {
      const resolver = AssetResolver.getInstance();
      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png'
      );
      expect(url).toBe('https://cdn.example.com/logo.png');
    });

    test('returns local path with local-always mode', () => {
      const resolver = AssetResolver.getInstance();
      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png',
        'local-always'
      );
      expect(url).toBe('/media/logo.png');
    });
  });

  describe('Input Validation', () => {
    let resolver: AssetResolver;

    beforeEach(() => {
      resolver = AssetResolver.getInstance();
    });

    test('rejects path with directory traversal', () => {
      expect(() => {
        resolver.getAssetUrl(
          '../../../etc/passwd',
          'https://cdn.example.com/logo.png'
        );
      }).toThrow();
    });

    test('rejects path with backslashes', () => {
      expect(() => {
        resolver.getAssetUrl(
          '\\media\\logo.png',
          'https://cdn.example.com/logo.png'
        );
      }).toThrow();
    });

    test('accepts paths starting with /', () => {
      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png'
      );
      expect(url).toBeTruthy();
    });

    test('accepts paths starting with ./', () => {
      const url = resolver.getAssetUrl(
        './media/logo.png',
        'https://cdn.example.com/logo.png'
      );
      expect(url).toBeTruthy();
    });

    test('rejects invalid CDN URL', () => {
      expect(() => {
        resolver.getAssetUrl(
          '/media/logo.png',
          'not-a-url'
        );
      }).toThrow();
    });

    test('warns on HTTP in production', () => {
      process.env.NODE_ENV = 'production';
      AssetResolver.resetInstance();
      const newResolver = AssetResolver.getInstance();

      const consoleSpy = jest.spyOn(console, 'warn').mockImplementation();

      expect(() => {
        newResolver.getAssetUrl(
          '/media/logo.png',
          'http://cdn.example.com/logo.png'
        );
      }).toThrow();

      consoleSpy.mockRestore();
    });
  });

  describe('Asset Mode Override', () => {
    test('ASSET_MODE=local forces local path', () => {
      process.env.NODE_ENV = 'production';
      process.env.ASSET_MODE = 'local';
      const resolver = AssetResolver.getInstance();

      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png'
      );
      expect(url).toBe('/media/logo.png');
    });

    test('ASSET_MODE=cdn forces CDN URL', () => {
      process.env.NODE_ENV = 'development';
      process.env.ASSET_MODE = 'cdn';
      const resolver = AssetResolver.getInstance();

      const url = resolver.getAssetUrl(
        '/media/logo.png',
        'https://cdn.example.com/logo.png'
      );
      expect(url).toBe('https://cdn.example.com/logo.png');
    });
  });
});

describe('getAssetUrl convenience function', () => {
  beforeEach(() => {
    AssetResolver.resetInstance();
    process.env.NODE_ENV = 'development';
  });

  test('returns local path in development', () => {
    const url = getAssetUrl(
      '/media/logo.png',
      'https://cdn.example.com/logo.png'
    );
    expect(url).toBe('/media/logo.png');
  });

  test('supports env mode parameter', () => {
    const url = getAssetUrl(
      '/media/logo.png',
      'https://cdn.example.com/logo.png',
      'cdn-always'
    );
    expect(url).toBe('https://cdn.example.com/logo.png');
  });
});

describe('batchResolveAssets', () => {
  beforeEach(() => {
    AssetResolver.resetInstance();
    process.env.NODE_ENV = 'development';
  });

  test('resolves multiple assets', () => {
    const urls = batchResolveAssets([
      { localPath: '/media/logo.png', cdnUrl: 'https://cdn.example.com/logo.png' },
      { localPath: '/media/banner.jpg', cdnUrl: 'https://cdn.example.com/banner.jpg' },
      { localPath: '/media/icon.svg', cdnUrl: 'https://cdn.example.com/icon.svg' },
    ]);

    expect(urls).toHaveLength(3);
    expect(urls[0]).toBe('/media/logo.png');
    expect(urls[1]).toBe('/media/banner.jpg');
    expect(urls[2]).toBe('/media/icon.svg');
  });

  test('supports different env modes per asset', () => {
    const urls = batchResolveAssets([
      { localPath: '/media/logo.png', cdnUrl: 'https://cdn.example.com/logo.png' },
      { localPath: '/media/banner.jpg', cdnUrl: 'https://cdn.example.com/banner.jpg', envMode: 'cdn-always' },
    ]);

    expect(urls[0]).toBe('/media/logo.png');
    expect(urls[1]).toBe('https://cdn.example.com/banner.jpg');
  });
});

describe('useAsset React hook', () => {
  beforeEach(() => {
    AssetResolver.resetInstance();
    process.env.NODE_ENV = 'development';
  });

  test('returns local path in development', () => {
    const url = useAsset(
      '/media/logo.png',
      'https://cdn.example.com/logo.png'
    );
    expect(url).toBe('/media/logo.png');
  });

  test('supports env mode parameter', () => {
    const url = useAsset(
      '/media/logo.png',
      'https://cdn.example.com/logo.png',
      'cdn-always'
    );
    expect(url).toBe('https://cdn.example.com/logo.png');
  });

  // Note: React hook memoization testing requires React Testing Library
  // Add these tests if your project uses React:
  //
  // test('memoizes result', () => {
  //   const { result, rerender } = renderHook(
  //     ({ local, cdn }) => useAsset(local, cdn),
  //     { initialProps: { local: '/media/logo.png', cdn: 'https://cdn.example.com/logo.png' } }
  //   );
  //
  //   const firstResult = result.current;
  //   rerender({ local: '/media/logo.png', cdn: 'https://cdn.example.com/logo.png' });
  //   expect(result.current).toBe(firstResult);
  // });
});

describe('Edge Cases', () => {
  let resolver: AssetResolver;

  beforeEach(() => {
    AssetResolver.resetInstance();
    resolver = AssetResolver.getInstance();
  });

  test('handles empty strings', () => {
    expect(() => {
      resolver.getAssetUrl('', 'https://cdn.example.com/logo.png');
    }).toThrow();
  });

  test('handles whitespace-only strings', () => {
    expect(() => {
      resolver.getAssetUrl('   ', 'https://cdn.example.com/logo.png');
    }).toThrow();
  });

  test('falls back gracefully when one path is invalid', () => {
    const url = resolver.getAssetUrl(
      '../invalid',
      'https://cdn.example.com/logo.png'
    );
    expect(url).toBe('https://cdn.example.com/logo.png');
  });
});
