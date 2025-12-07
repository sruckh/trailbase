# Docker Setup for TrailBase

This guide explains how to set up TrailBase using Docker with a shared network and Backblaze storage.

## Prerequisites

1. Docker and Docker Compose installed
2. Backblaze volume mounted at `/mnt/backblaze`
3. Docker network `shared_net` created

## Quick Setup

### 1. Create Docker Network (if not exists)
```bash
docker network create shared_net
```

### 2. Run the Setup Script
```bash
./setup-shared-net.sh
```

The script will:
- Create necessary directories on Backblaze
- Set proper permissions
- Generate a secure JWT secret
- Start TrailBase container

### 3. Check the Status
```bash
# Check if container is running
docker-compose -f docker-compose.shared-net.yml ps

# View logs
docker-compose -f docker-compose.shared-net.yml logs -f trail
```

## Manual Setup

### 1. Create Directories
```bash
# Create data directories
mkdir -p /mnt/backblaze/trailbase/traildepot
mkdir -p /mnt/backblaze/trailbase/logs

# Set permissions (TrailBase runs as user 1000:1000)
chown -R 1000:1000 /mnt/backblaze/trailbase
chmod 755 /mnt/backblaze/trailbase/traildepot
```

### 2. Configure Environment
```bash
# Copy environment template
cp .env.shared-net.example .env

# Edit configuration
nano .env
```

Important settings to configure:
- `JWT_SECRET`: Generate with `openssl rand -hex 32`
- `ADMIN_PASSWORD`: Set secure admin password
- `CORS_ORIGINS`: Add your frontend URLs

### 3. Start TrailBase
```bash
docker-compose -f docker-compose.shared-net.yml up -d
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ADDRESS` | Server bind address | `0.0.0.0:4000` |
| `DATA_DIR` | Data directory path | `/app/traildepot` |
| `JWT_SECRET` | JWT signing secret | Required |
| `ADMIN_EMAIL` | Default admin email | `admin@localhost` |
| `ADMIN_PASSWORD` | Default admin password | Required |
| `CORS_ORIGINS` | Allowed CORS origins | localhost |
| `RUST_LOG` | Log level | `info` |

### Email Configuration (Optional)

Enable email features by configuring SMTP:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM=noreply@yourdomain.com
```

### OAuth Providers (Optional)

Configure OAuth providers for social login:
```env
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
```

## Network Access

TrailBase is configured to:
- **Not expose** ports to localhost
- **Expose** port 4000 only to the `shared_net` Docker network
- Be accessible at `trailbase:4000` from other containers on the network

### Example: Access from another container
```bash
# From another container on shared_net
curl http://trailbase:4000/_/health
```

### Example: Nginx reverse proxy configuration
```nginx
upstream trailbase {
    server trailbase:4000;
}

server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://trailbase;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Data Persistence

- **Database**: Stored in `/mnt/backblaze/trailbase/traildepot/data/`
- **Migrations**: `/mnt/backblaze/trailbase/traildepot/migrations/`
- **File uploads**: `/mnt/backblaze/trailbase/traildepot/uploads/`
- **Backups**: `/mnt/backblaze/trailbase/traildepot/backups/`
- **Logs**: `/mnt/backblaze/trailbase/logs/`

## Management Commands

### Quick Management Script
```bash
# Start TrailBase
./manage-trailbase.sh start

# Stop TrailBase
./manage-trailbase.sh stop

# Restart TrailBase
./manage-trailbase.sh restart

# Check status
./manage-trailbase.sh status

# View logs (follow)
./manage-trailbase.sh logs -f

# Create backup
./manage-trailbase.sh backup

# Full shutdown with cleanup
./shutdown-shared-net.sh
```

### Manual Commands
```bash
# Start services
docker compose -f docker-compose.shared-net.yml up -d

# Stop services
docker compose -f docker-compose.shared-net.yml down

# View logs
docker compose -f docker-compose.shared-net.yml logs -f trail

# Restart service
docker compose -f docker-compose.shared-net.yml restart

# Access container shell
docker exec -it trailbase sh

# Update to latest version
docker compose -f docker-compose.shared-net.yml pull
docker compose -f docker-compose.shared-net.yml up -d
```

## Health Check

The container includes a health check:
```bash
# Check health status
docker-compose -f docker-compose.shared-net.yml ps
curl http://trailbase:4000/_/health
```

## Troubleshooting

### Permission Denied Errors
If you see permission errors:
```bash
# Fix ownership
sudo chown -R 1000:1000 /mnt/backblaze/trailbase

# Or run with different user (not recommended)
# Add to docker-compose.yml:
# user: "1000:1000"
```

### Container Won't Start
Check logs:
```bash
./manage-trailbase.sh logs
# or
docker compose -f docker-compose.shared-net.yml logs trail
```

Common issues:
- Missing JWT_SECRET in .env file
- Network `shared_net` doesn't exist
- Backblaze volume not mounted
- Port conflicts (shouldn't happen with network-only exposure)

### Network Issues
Verify network exists:
```bash
docker network ls | grep shared_net
```

Check container network connection:
```bash
docker network inspect shared_net
```