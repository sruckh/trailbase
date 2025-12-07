#!/bin/bash

# TrailBase Setup Script for shared_net Docker Network
# This script helps set up TrailBase with the shared_net network and Backblaze storage

set -e

echo "🚀 Setting up TrailBase with shared_net Docker network..."

# Check if shared_net network exists
if ! docker network inspect shared_net &>/dev/null; then
    echo "❌ Error: Docker network 'shared_net' not found!"
    echo "Please create the network first:"
    echo "  docker network create shared_net"
    exit 1
fi

# Create Backblaze directories
echo "📁 Creating directories on Backblaze volume..."
mkdir -p /mnt/backblaze/trailbase/traildepot
mkdir -p /mnt/backblaze/trailbase/logs

# Set permissions (TrailBase runs as non-root user)
# Note: You may need to adjust UID/GID based on your Docker setup
echo "🔐 Setting directory permissions..."
chown -R 1000:1000 /mnt/backblaze/trailbase/traildepot
chown -R 1000:1000 /mnt/backblaze/trailbase/logs
chmod 755 /mnt/backblaze/trailbase/traildepot
chmod 755 /mnt/backblaze/trailbase/logs

# Check if .env file exists
if [ ! -f .env ]; then
    echo "⚙️  Creating .env file from template..."
    cp .env.shared-net.example .env
    echo "✅ Created .env file. Please edit it with your configuration:"
    echo "   - Set JWT_SECRET (run: openssl rand -hex 32)"
    echo "   - Set ADMIN_PASSWORD"
    echo "   - Configure email and OAuth settings if needed"
    echo ""
    echo "Example commands:"
    echo "  nano .env"
    echo "  # or"
    echo "  vim .env"
    echo ""
    read -p "Press Enter after you've configured the .env file..."
fi

# Generate a JWT secret if not set
if ! grep -q "^JWT_SECRET=" .env || grep -q "your-secure-jwt-secret-here" .env; then
    echo "🔐 Generating new JWT secret..."
    JWT_SECRET=$(openssl rand -hex 32)
    sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
    sed -i "s/your-secure-jwt-secret-here/$JWT_SECRET/" .env
    echo "✅ JWT secret generated and saved to .env"
fi

# Start the container
echo "🐳 Starting TrailBase container..."
docker-compose -f docker-compose.shared-net.yml up -d

# Wait a moment for the container to start
echo "⏳ Waiting for TrailBase to start..."
sleep 5

# Check if container is running
if docker-compose -f docker-compose.shared-net.yml ps | grep -q "Up"; then
    echo ""
    echo "✅ TrailBase is running successfully!"
    echo ""
    echo "📍 Container Information:"
    echo "  - Container Name: trailbase"
    echo "  - Network: shared_net"
    echo "  - Data Volume: /mnt/backblaze/trailbase/traildepot"
    echo "  - Logs: docker-compose -f docker-compose.shared-net.yml logs -f"
    echo ""
    echo "🔗 Access TrailBase:"
    echo "  - Admin UI: Available on the shared_net network at port 4000"
    echo "  - Health Check: curl http://trailbase:4000/_/health (from within network)"
    echo ""
    echo "📋 Useful Commands:"
    echo "  - View logs: docker-compose -f docker-compose.shared-net.yml logs -f trail"
    echo "  - Stop container: docker-compose -f docker-compose.shared-net.yml down"
    echo "  - Restart container: docker-compose -f docker-compose.shared-net.yml restart"
    echo "  - Access container shell: docker exec -it trailbase sh"
    echo ""
    echo "📝 First Steps:"
    echo "  1. Check logs for admin credentials:"
    echo "     docker-compose -f docker-compose.shared-net.yml logs trail | grep 'admin user'"
    echo "  2. Access admin UI from another container on shared_net"
    echo "  3. Create your database tables and start building!"
else
    echo ""
    echo "❌ Failed to start TrailBase container"
    echo "Check logs for errors:"
    echo "  docker-compose -f docker-compose.shared-net.yml logs trail"
    exit 1
fi