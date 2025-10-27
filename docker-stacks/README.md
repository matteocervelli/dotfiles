# Docker Stacks - Production Infrastructure

**Complete observability, infrastructure, and application deployment stacks for VPS.**

## Overview

This directory contains production-ready Docker Compose stacks for deploying a complete monitoring and infrastructure solution on your VPS.

### Stacks Included

1. **Observability** - Monitoring, logging, and alerting
   - Grafana (visualization)
   - Prometheus (metrics)
   - Loki (logs)
   - Alloy (telemetry collector)
   - Alertmanager (alerts)
   - Various exporters (node, cadvisor, postgres, redis, nginx)

2. **Infrastructure** - Database, cache, and reverse proxy
   - PostgreSQL 16 (database)
   - Redis 7 (cache/message broker)
   - Nginx (reverse proxy)
   - Exporters for monitoring

## Quick Start

### 1. Deploy Observability Stack

```bash
cd docker-stacks/observability

# Create environment file
cp .env.example .env

# Edit configuration (set passwords, URLs)
vim .env

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f grafana
```

**Access:**
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090
- Alertmanager: http://localhost:9093
- Loki: http://localhost:3100

### 2. Deploy Infrastructure Stack

```bash
cd docker-stacks/infrastructure

# Create environment file
cp .env.example .env

# Edit configuration
vim .env

# Start all services
docker compose up -d

# Check status
docker compose ps

# Test connections
docker exec -it postgres psql -U postgres
docker exec -it redis redis-cli
```

**Access:**
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- Nginx: http://localhost (80/443)
- PgAdmin: http://localhost:5050 (with --profile tools)
- Redis Commander: http://localhost:8081 (with --profile tools)

### 3. Connect Stacks Together

The observability and infrastructure stacks are connected via the `monitoring` network:

```bash
# Start both stacks
cd docker-stacks/observability && docker compose up -d
cd docker-stacks/infrastructure && docker compose up -d

# Verify connectivity
docker exec -it prometheus wget -qO- http://postgres-exporter:9187/metrics
docker exec -it prometheus wget -qO- http://redis-exporter:9121/metrics
```

## Configuration

### Environment Variables

Create `.env` files in each stack directory:

**observability/.env:**
```bash
# Grafana
GF_ADMIN_USER=admin
GF_ADMIN_PASSWORD=change_me_please
GF_SECRET_KEY=very_secret_key_here
GF_SERVER_ROOT_URL=https://grafana.example.com
GF_SERVER_DOMAIN=grafana.example.com

# Hostname
HOSTNAME=vps-production
```

**infrastructure/.env:**
```bash
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=strong_password_here
POSTGRES_DB=app
POSTGRES_PORT=5432

# Redis
REDIS_PASSWORD=redis_password_here
REDIS_PORT=6379

# PgAdmin (optional)
PGADMIN_EMAIL=admin@example.com
PGADMIN_PASSWORD=pgadmin_password
```

### Customizing Configurations

All configurations can be edited:

**Prometheus:**
- `observability/prometheus/prometheus.yml` - Scrape configs
- `observability/prometheus/alerts.yml` - Alert rules

**Loki:**
- `observability/loki/loki.yml` - Loki config
- `observability/loki/promtail.yml` - Log collection

**PostgreSQL:**
- `infrastructure/postgres/postgresql.conf` - Database tuning
- `infrastructure/postgres/queries.yml` - Custom metrics

**Redis:**
- `infrastructure/redis/redis.conf` - Cache configuration

**Nginx:**
- `infrastructure/nginx/nginx.conf` - Main config
- `infrastructure/nginx/conf.d/*.conf` - Virtual hosts

## Monitoring Your Applications

### Next.js Application

1. Update Nginx config with your domain:
```bash
vim infrastructure/nginx/conf.d/nextjs.conf
# Change: example.com → your-domain.com
```

2. Add your app to infrastructure stack:
```yaml
# infrastructure/docker-compose.yml
services:
  nextjs-app:
    image: your-nextjs-app:latest
    container_name: nextjs-app
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@postgres:5432/db
      - REDIS_URL=redis://:password@redis:6379
    networks:
      - infrastructure
      - monitoring
    labels:
      - "monitoring=true"  # For Prometheus service discovery
```

3. Reload Nginx:
```bash
docker compose exec nginx nginx -s reload
```

### FastAPI Application

1. Update Nginx config:
```bash
vim infrastructure/nginx/conf.d/fastapi.conf
# Change: api.example.com → your-api-domain.com
```

2. Add Prometheus metrics to your FastAPI app:
```python
from prometheus_client import Counter, Histogram, make_asgi_app
from fastapi import FastAPI

app = FastAPI()

# Metrics
request_count = Counter('http_requests_total', 'Total requests')
request_duration = Histogram('http_request_duration_seconds', 'Request duration')

# Add metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)
```

3. Add to infrastructure stack:
```yaml
services:
  fastapi-app:
    image: your-fastapi-app:latest
    container_name: fastapi-app
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/db
      - REDIS_URL=redis://:password@redis:6379
    networks:
      - infrastructure
      - monitoring
```

### Vite + React SPA

1. Update Nginx config:
```bash
vim infrastructure/nginx/conf.d/vite.conf
# Change: spa.example.com → your-spa-domain.com
```

2. Build and serve:
```bash
# Build your Vite app
npm run build

# Serve with Nginx (built-in to infrastructure stack)
```

3. For API calls, proxy to FastAPI:
```typescript
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'http://api.example.com',
        changeOrigin: true,
      }
    }
  }
})
```

## Celery Monitoring

### Setup Celery with Flower

Add to your FastAPI/Django stack:

```yaml
services:
  # Celery worker
  celery-worker:
    image: your-app:latest
    command: celery -A app worker -l info
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/db
      - REDIS_URL=redis://:password@redis:6379
    networks:
      - infrastructure
      - monitoring
    depends_on:
      - redis
      - postgres

  # Celery beat (scheduler)
  celery-beat:
    image: your-app:latest
    command: celery -A app beat -l info
    environment:
      - REDIS_URL=redis://:password@redis:6379
    networks:
      - infrastructure
    depends_on:
      - redis

  # Flower (monitoring UI)
  celery-flower:
    image: mher/flower:latest
    command: celery --broker=redis://:password@redis:6379 flower --port=5555
    ports:
      - "5555:5555"
    environment:
      - CELERY_BROKER_URL=redis://:password@redis:6379
      - FLOWER_BASIC_AUTH=admin:password
    networks:
      - infrastructure
      - monitoring
    depends_on:
      - redis

  # Celery exporter (for Prometheus)
  celery-exporter:
    image: danihodovic/celery-exporter:latest
    environment:
      - CELERY_BROKER_URL=redis://:password@redis:6379
    ports:
      - "9808:9808"
    networks:
      - monitoring
    depends_on:
      - redis
```

**Access Flower:** http://localhost:5555

### Celery Metrics in Grafana

1. Import Celery dashboard in Grafana
2. Add data source: Prometheus
3. Query metrics:
   - `celery_tasks_total` - Total tasks
   - `celery_tasks_failed_total` - Failed tasks
   - `celery_workers` - Active workers
   - `celery_queue_length` - Queue depth

## Grafana Dashboards

### Import Pre-built Dashboards

1. **Node Exporter Full** (ID: 1860)
   - System metrics (CPU, memory, disk, network)

2. **PostgreSQL Database** (ID: 9628)
   - Database metrics, connections, slow queries

3. **Redis Dashboard** (ID: 763)
   - Cache metrics, memory usage, operations

4. **Nginx Overview** (ID: 12708)
   - Request rates, response times, error rates

5. **Docker Container Monitoring** (ID: 893)
   - Container metrics from cAdvisor

6. **Loki Logs** (ID: 13639)
   - Log aggregation and searching

### Import in Grafana

```bash
# Via UI
Dashboards → Import → Enter ID → Load

# Or via CLI
curl -X POST http://admin:admin@localhost:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -d '{"dashboard": {...}, "overwrite": true}'
```

## Alerting

### Configure Alert Notifications

Edit `observability/alertmanager/alertmanager.yml`:

**Email notifications:**
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

receivers:
  - name: 'critical'
    email_configs:
      - to: 'ops-team@example.com'
```

**Slack notifications:**
```yaml
receivers:
  - name: 'critical'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts-critical'
        title: 'Critical Alert'
```

**Restart Alertmanager:**
```bash
cd observability
docker compose restart alertmanager
```

### Test Alerts

```bash
# Trigger a test alert
curl -X POST http://localhost:9093/api/v1/alerts -d '[{
  "labels": {
    "alertname": "TestAlert",
    "severity": "critical"
  },
  "annotations": {
    "summary": "This is a test alert"
  }
}]'
```

## SSL/TLS Configuration

### Using Let's Encrypt

1. Install Certbot:
```bash
sudo apt install certbot
```

2. Generate certificates:
```bash
sudo certbot certonly --standalone -d example.com -d www.example.com
```

3. Copy certificates to Nginx:
```bash
sudo cp /etc/letsencrypt/live/example.com/fullchain.pem \
  docker-stacks/infrastructure/nginx/ssl/
sudo cp /etc/letsencrypt/live/example.com/privkey.pem \
  docker-stacks/infrastructure/nginx/ssl/
```

4. Restart Nginx:
```bash
cd infrastructure
docker compose restart nginx
```

5. Setup auto-renewal:
```bash
sudo certbot renew --dry-run
```

## Backup and Recovery

### PostgreSQL Backup

```bash
# Backup
docker exec postgres pg_dump -U postgres app > backup_$(date +%Y%m%d).sql

# Restore
docker exec -i postgres psql -U postgres app < backup_20250127.sql

# Automated backups (add to crontab)
0 2 * * * cd /home/user/dotfiles/docker-stacks && \
  docker exec postgres pg_dump -U postgres app | \
  gzip > /backups/postgres_$(date +\%Y\%m\%d).sql.gz
```

### Redis Backup

```bash
# Backup (RDB snapshot)
docker exec redis redis-cli SAVE

# Copy snapshot
docker cp redis:/data/dump.rdb ./backup/redis_$(date +%Y%m%d).rdb

# Restore
docker cp backup/redis.rdb redis:/data/dump.rdb
docker compose restart redis
```

### Monitoring Data Backup

```bash
# Prometheus data
docker run --rm -v prometheus_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/prometheus_backup.tar.gz /data

# Grafana dashboards
docker exec grafana grafana-cli admin export-dashboards /tmp/dashboards
docker cp grafana:/tmp/dashboards ./backup/grafana_dashboards/

# Loki data
docker run --rm -v loki_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/loki_backup.tar.gz /data
```

## Troubleshooting

### Services Not Starting

```bash
# Check logs
docker compose logs <service-name>

# Check configuration
docker compose config

# Verify network
docker network ls
docker network inspect monitoring
```

### High Resource Usage

```bash
# Check container stats
docker stats

# Check disk usage
docker system df

# Clean up
docker system prune -a
```

### Connection Issues

```bash
# Test connectivity
docker exec -it prometheus wget -qO- http://node-exporter:9100/metrics
docker exec -it grafana curl http://prometheus:9090/api/v1/query?query=up

# Check DNS resolution
docker exec -it grafana nslookup prometheus
```

### Metrics Not Showing

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Check Prometheus scrape config
docker exec prometheus cat /etc/prometheus/prometheus.yml

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload
```

## Performance Tuning

### For 2GB RAM VPS

```yaml
# Adjust in docker-compose.yml
services:
  prometheus:
    environment:
      - PROMETHEUS_STORAGE_RETENTION_TIME=15d
    deploy:
      resources:
        limits:
          memory: 512M

  grafana:
    deploy:
      resources:
        limits:
          memory: 256M

  postgres:
    # See postgres/postgresql.conf
    # shared_buffers = 512MB
    # effective_cache_size = 1536MB
```

### For 4GB RAM VPS

```yaml
services:
  prometheus:
    environment:
      - PROMETHEUS_STORAGE_RETENTION_TIME=30d
    deploy:
      resources:
        limits:
          memory: 1G

  grafana:
    deploy:
      resources:
        limits:
          memory: 512M

  postgres:
    # shared_buffers = 1GB
    # effective_cache_size = 3GB
```

## Security Best Practices

1. **Change default passwords**
   - Grafana admin password
   - PostgreSQL password
   - Redis password

2. **Use strong secrets**
   - Generate with: `openssl rand -base64 32`

3. **Enable SSL/TLS**
   - Use Let's Encrypt certificates
   - Force HTTPS in Nginx

4. **Restrict access**
   - Use UFW firewall rules
   - Bind services to localhost when possible
   - Use Tailscale for admin access

5. **Regular updates**
   ```bash
   docker compose pull
   docker compose up -d
   ```

6. **Backup regularly**
   - Automated daily backups
   - Test restore procedures
   - Store backups off-site (R2, S3)

## Resources

### Documentation

- [Grafana Docs](https://grafana.com/docs/grafana/latest/)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Loki Docs](https://grafana.com/docs/loki/latest/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Redis Docs](https://redis.io/documentation)
- [Nginx Docs](https://nginx.org/en/docs/)

### Related Guides

- [VPS Ubuntu Setup](../docs/guides/vps-ubuntu-setup.md)
- [Docker Installation](../scripts/bootstrap/install-docker.sh)
- [Security Hardening](../scripts/security/harden-vps.sh)

---

**Created**: 2025-10-27
**Last Updated**: 2025-10-27
**Maintained By**: Matteo Cervelli
**Project**: [dotfiles](https://github.com/matteocervelli/dotfiles)
