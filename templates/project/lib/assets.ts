/**
 * Environment-Aware Asset Helper for TypeScript/JavaScript Projects
 *
 * This utility provides automatic asset URL resolution based on environment:
 * - Development: Uses local file paths
 * - Production: Uses CDN URLs
 * - Test: Configurable behavior
 *
 * @module assets
 * @version 1.0.0
 * @license MIT
 */

/**
 * Asset resolution mode
 * - 'local': Always use local paths
 * - 'cdn': Always use CDN URLs
 * - 'auto': Automatic based on environment (default)
 */
export type AssetMode = 'local' | 'cdn' | 'auto';

/**
 * Environment-specific asset resolution strategy
 * - 'cdn-production-local-dev': CDN in production, local in development (default)
 * - 'cdn-always': Always use CDN URL regardless of environment
 * - 'local-always': Always use local path regardless of environment
 */
export type EnvMode = 'cdn-production-local-dev' | 'cdn-always' | 'local-always';

/**
 * Detected environment type
 */
type Environment = 'development' | 'production' | 'test';

/**
 * Asset URL resolution configuration
 */
interface AssetConfig {
  localPath: string;
  cdnUrl: string;
  envMode?: EnvMode;
}

/**
 * AssetResolver - Singleton class for environment-aware asset URL resolution
 *
 * Provides cached environment detection and URL resolution logic.
 *
 * @example
 * ```typescript
 * const resolver = AssetResolver.getInstance();
 * const url = resolver.getAssetUrl('/media/logo.png', 'https://cdn.example.com/logos/logo.png');
 * ```
 */
export class AssetResolver {
  private static instance: AssetResolver | null = null;
  private environment: Environment;
  private assetMode: AssetMode;

  /**
   * Private constructor - use getInstance() instead
   */
  private constructor() {
    this.environment = this.detectEnvironment();
    this.assetMode = this.detectAssetMode();
  }

  /**
   * Get singleton instance of AssetResolver
   */
  public static getInstance(): AssetResolver {
    if (!AssetResolver.instance) {
      AssetResolver.instance = new AssetResolver();
    }
    return AssetResolver.instance;
  }

  /**
   * Reset singleton instance (useful for testing)
   * @internal
   */
  public static resetInstance(): void {
    AssetResolver.instance = null;
  }

  /**
   * Detect current environment from NODE_ENV
   * @private
   */
  private detectEnvironment(): Environment {
    const nodeEnv = typeof process !== 'undefined'
      ? process.env.NODE_ENV?.toLowerCase()
      : undefined;

    if (nodeEnv === 'production') return 'production';
    if (nodeEnv === 'test') return 'test';
    return 'development';
  }

  /**
   * Detect asset mode from ASSET_MODE environment variable
   * @private
   */
  private detectAssetMode(): AssetMode {
    const assetMode = typeof process !== 'undefined'
      ? process.env.ASSET_MODE?.toLowerCase()
      : undefined;

    if (assetMode === 'local' || assetMode === 'cdn') {
      return assetMode as AssetMode;
    }
    return 'auto';
  }

  /**
   * Validate local path to prevent directory traversal
   * @private
   */
  private validateLocalPath(path: string): boolean {
    if (!path || typeof path !== 'string') return false;

    // Prevent directory traversal attacks
    if (path.includes('..')) return false;
    if (path.includes('\\')) return false;

    // Should start with / or ./
    if (!path.startsWith('/') && !path.startsWith('./')) return false;

    return true;
  }

  /**
   * Validate CDN URL format
   * @private
   */
  private validateCdnUrl(url: string): boolean {
    if (!url || typeof url !== 'string') return false;

    try {
      const parsed = new URL(url);

      // In production, require HTTPS
      if (this.environment === 'production' && parsed.protocol !== 'https:') {
        console.warn(`[AssetResolver] CDN URL should use HTTPS in production: ${url}`);
        return false;
      }

      return parsed.protocol === 'http:' || parsed.protocol === 'https:';
    } catch {
      return false;
    }
  }

  /**
   * Determine whether to use CDN based on environment and mode
   * @private
   */
  private shouldUseCdn(envMode: EnvMode = 'cdn-production-local-dev'): boolean {
    // Handle explicit asset mode override
    if (this.assetMode === 'cdn') return true;
    if (this.assetMode === 'local') return false;

    // Handle envMode strategies
    switch (envMode) {
      case 'cdn-always':
        return true;

      case 'local-always':
        return false;

      case 'cdn-production-local-dev':
      default:
        return this.environment === 'production';
    }
  }

  /**
   * Get environment-aware asset URL
   *
   * @param localPath - Local file path (e.g., '/media/logo.png')
   * @param cdnUrl - CDN URL (e.g., 'https://cdn.example.com/logos/logo.png')
   * @param envMode - Environment mode strategy (default: 'cdn-production-local-dev')
   * @returns Resolved asset URL based on environment
   *
   * @example
   * ```typescript
   * const resolver = AssetResolver.getInstance();
   *
   * // Default behavior: CDN in prod, local in dev
   * const url1 = resolver.getAssetUrl('/media/logo.png', 'https://cdn.example.com/logo.png');
   *
   * // Always use CDN
   * const url2 = resolver.getAssetUrl('/media/banner.jpg', 'https://cdn.example.com/banner.jpg', 'cdn-always');
   *
   * // Always use local
   * const url3 = resolver.getAssetUrl('/media/icon.svg', 'https://cdn.example.com/icon.svg', 'local-always');
   * ```
   */
  public getAssetUrl(
    localPath: string,
    cdnUrl: string,
    envMode: EnvMode = 'cdn-production-local-dev'
  ): string {
    // Validate inputs
    const isLocalValid = this.validateLocalPath(localPath);
    const isCdnValid = this.validateCdnUrl(cdnUrl);

    if (!isLocalValid && !isCdnValid) {
      throw new Error(`[AssetResolver] Invalid asset paths: local="${localPath}", cdn="${cdnUrl}"`);
    }

    // Determine which URL to use
    const useCdn = this.shouldUseCdn(envMode);

    if (useCdn && isCdnValid) {
      return cdnUrl;
    }

    if (!useCdn && isLocalValid) {
      return localPath;
    }

    // Fallback logic
    if (isLocalValid) {
      console.warn(`[AssetResolver] Falling back to local path: ${localPath}`);
      return localPath;
    }

    if (isCdnValid) {
      console.warn(`[AssetResolver] Falling back to CDN URL: ${cdnUrl}`);
      return cdnUrl;
    }

    throw new Error(`[AssetResolver] Cannot resolve asset URL`);
  }

  /**
   * Get current environment
   */
  public getEnvironment(): Environment {
    return this.environment;
  }

  /**
   * Get current asset mode
   */
  public getAssetMode(): AssetMode {
    return this.assetMode;
  }
}

/**
 * Convenience function for getting asset URL without creating resolver instance
 *
 * @param localPath - Local file path
 * @param cdnUrl - CDN URL
 * @param envMode - Environment mode strategy
 * @returns Resolved asset URL
 *
 * @example
 * ```typescript
 * import { getAssetUrl } from '@/lib/assets';
 *
 * const logoUrl = getAssetUrl('/media/logo.png', 'https://cdn.example.com/logo.png');
 * ```
 */
export function getAssetUrl(
  localPath: string,
  cdnUrl: string,
  envMode?: EnvMode
): string {
  const resolver = AssetResolver.getInstance();
  return resolver.getAssetUrl(localPath, cdnUrl, envMode);
}

/**
 * React hook for environment-aware asset URLs with memoization
 *
 * Automatically re-computes only when inputs change, preventing unnecessary re-renders.
 *
 * @param localPath - Local file path
 * @param cdnUrl - CDN URL
 * @param envMode - Environment mode strategy
 * @returns Resolved asset URL (memoized)
 *
 * @example
 * ```tsx
 * import { useAsset } from '@/lib/assets';
 *
 * export default function Logo() {
 *   const logoUrl = useAsset(
 *     '/media/logo.png',
 *     'https://cdn.example.com/logos/logo.png'
 *   );
 *
 *   return <img src={logoUrl} alt="Logo" />;
 * }
 * ```
 *
 * @example
 * ```tsx
 * // With custom env mode
 * function Banner() {
 *   const bannerUrl = useAsset(
 *     '/media/banner.jpg',
 *     'https://cdn.example.com/banners/hero.jpg',
 *     'cdn-always'
 *   );
 *
 *   return <div style={{ backgroundImage: `url(${bannerUrl})` }} />;
 * }
 * ```
 */
export function useAsset(
  localPath: string,
  cdnUrl: string,
  envMode?: EnvMode
): string {
  // Check if React hooks are available
  if (typeof require !== 'undefined') {
    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const React = require('react');

      // eslint-disable-next-line react-hooks/rules-of-hooks
      return React.useMemo(
        () => getAssetUrl(localPath, cdnUrl, envMode),
        [localPath, cdnUrl, envMode]
      );
    } catch {
      // React not available, fall through to simple resolution
    }
  }

  // Fallback if React is not available
  return getAssetUrl(localPath, cdnUrl, envMode);
}

/**
 * Batch resolve multiple assets
 *
 * @param configs - Array of asset configurations
 * @returns Array of resolved URLs in same order
 *
 * @example
 * ```typescript
 * import { batchResolveAssets } from '@/lib/assets';
 *
 * const [logoUrl, bannerUrl, iconUrl] = batchResolveAssets([
 *   { localPath: '/media/logo.png', cdnUrl: 'https://cdn.example.com/logo.png' },
 *   { localPath: '/media/banner.jpg', cdnUrl: 'https://cdn.example.com/banner.jpg' },
 *   { localPath: '/media/icon.svg', cdnUrl: 'https://cdn.example.com/icon.svg', envMode: 'cdn-always' },
 * ]);
 * ```
 */
export function batchResolveAssets(configs: AssetConfig[]): string[] {
  const resolver = AssetResolver.getInstance();
  return configs.map(config =>
    resolver.getAssetUrl(config.localPath, config.cdnUrl, config.envMode)
  );
}

// Export types
export type { AssetConfig, Environment };
