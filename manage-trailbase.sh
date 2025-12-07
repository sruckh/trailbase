#!/bin/bash

# TrailBase Management Script for shared_net Docker Network
# A unified script to manage TrailBase lifecycle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Show usage
show_usage() {
    echo "TrailBase Management Script"
    echo ""
    echo "Usage: $0 {start|stop|restart|status|logs|backup|help}"
    echo ""
    echo "Commands:"
    echo "  start    - Start TrailBase container"
    echo "  stop     - Stop TrailBase container"
    echo "  restart  - Restart TrailBase container"
    echo "  status   - Show container status"
    echo "  logs     - Show container logs"
    echo "  backup   - Backup TrailBase data"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start           # Start TrailBase"
    echo "  $0 restart         # Restart TrailBase"
    echo "  $0 logs -f         # Follow logs"
}

# Check if Docker network exists
check_network() {
    if ! docker network inspect shared_net &>/dev/null; then
        print_status "$RED" "❌ Docker network 'shared_net' not found!"
        print_status "$YELLOW" "Please create it first:"
        echo "  docker network create shared_net"
        exit 1
    fi
}

# Start TrailBase
start_trailbase() {
    print_status "$BLUE" "🚀 Starting TrailBase..."

    check_network

    # Create directories if they don't exist
    mkdir -p /mnt/backblaze/trailbase/traildepot
    mkdir -p /mnt/backblaze/trailbase/logs

    # Set permissions
    chown -R 1000:1000 /mnt/backblaze/trailbase/traildepot 2>/dev/null || true
    chown -R 1000:1000 /mnt/backblaze/trailbase/logs 2>/dev/null || true

    # Check if .env exists
    if [ ! -f .env ]; then
        print_status "$YELLOW" "⚙️  Creating .env file from template..."
        cp .env.shared-net.example .env

        # Generate JWT secret
        JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "change-this-secret")
        sed -i "s/your-secure-jwt-secret-here/$JWT_SECRET/" .env

        print_status "$GREEN" "✅ .env file created with generated JWT secret"
        print_status "$YELLOW" "⚠️  Please edit .env to configure your settings"
    fi

    # Start container
    docker compose -f docker-compose.shared-net.yml up -d

    # Wait for startup
    print_status "$BLUE" "⏳ Waiting for TrailBase to start..."
    sleep 5

    # Check status
    if docker compose -f docker-compose.shared-net.yml ps | grep -q "Up"; then
        print_status "$GREEN" "✅ TrailBase started successfully!"
        echo ""
        print_status "$BLUE" "Access TrailBase at: http://trailbase:4000 (from shared_net network)"
    else
        print_status "$RED" "❌ Failed to start TrailBase"
        print_status "$YELLOW" "Check logs: $0 logs"
        exit 1
    fi
}

# Stop TrailBase
stop_trailbase() {
    print_status "$BLUE" "🛑 Stopping TrailBase..."

    if docker compose -f docker-compose.shared-net.yml ps 2>/dev/null | grep -q "trail"; then
        docker compose -f docker-compose.shared-net.yml down
        print_status "$GREEN" "✅ TrailBase stopped successfully"
    else
        print_status "$YELLOW" "TrailBase is not running"
    fi
}

# Restart TrailBase
restart_trailbase() {
    print_status "$BLUE" "🔄 Restarting TrailBase..."
    stop_trailbase
    sleep 2
    start_trailbase
}

# Show status
show_status() {
    print_status "$BLUE" "📊 TrailBase Status:"
    echo ""

    # Container status
    if docker compose -f docker-compose.shared-net.yml ps 2>/dev/null | grep -q "trail"; then
        docker compose -f docker-compose.shared-net.yml ps
    else
        print_status "$YELLOW" "TrailBase container is not running"
    fi

    echo ""

    # Network status
    if docker network inspect shared_net &>/dev/null; then
        print_status "$GREEN" "✅ Docker network 'shared_net' exists"
        echo "  Network ID: $(docker network inspect shared_net -f '{{.Id}}' 2>/dev/null)"
    else
        print_status "$RED" "❌ Docker network 'shared_net' does not exist"
    fi

    echo ""

    # Volume status
    if [ -d /mnt/backblaze/trailbase ]; then
        print_status "$GREEN" "✅ Data volume exists at /mnt/backblaze/trailbase"
        du -sh /mnt/backblaze/trailbase/traildepot 2>/dev/null | awk '{print "  Size: " $1}' || echo "  Size: calculating..."
    else
        print_status "$RED" "❌ Data volume not found"
    fi
}

# Show logs
show_logs() {
    docker compose -f docker-compose.shared-net.yml logs -f trail "$@"
}

# Backup data
backup_data() {
    local backup_dir="/mnt/backblaze/trailbase/backups/manual"
    local backup_name="trailbase-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_path="$backup_dir/$backup_name"

    print_status "$BLUE" "💾 Creating backup..."

    # Create backup directory
    mkdir -p "$backup_dir"

    # Create backup
    if command -v tar >/dev/null 2>&1; then
        tar -czf "$backup_path.tar.gz" -C /mnt/backblaze/trailbase traildepot logs 2>/dev/null
        print_status "$GREEN" "✅ Backup created: $backup_path.tar.gz"
    else
        cp -r /mnt/backblaze/trailbase/traildepot "$backup_path" 2>/dev/null
        print_status "$GREEN" "✅ Backup created: $backup_path"
    fi

    # Backup configuration
    if [ -f .env ]; then
        cp .env "$backup_dir/env-$(date +%Y%m%d-%H%M%S).backup"
    fi

    # Clean old backups (keep last 5)
    ls -t "$backup_dir"/*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

    print_status "$BLUE" "📂 Backups kept in: $backup_dir"
}

# Main script logic
case "${1:-help}" in
    "start")
        start_trailbase
        ;;
    "stop")
        stop_trailbase
        ;;
    "shutdown")
        shift
        ./shutdown-shared-net.sh "$@"
        ;;
    "restart")
        restart_trailbase
        ;;
    "status")
        show_status
        ;;
    "logs")
        shift
        show_logs "$@"
        ;;
    "backup")
        backup_data
        ;;
    "help"|*)
        show_usage
        ;;
esac