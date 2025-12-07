#!/bin/bash

# TrailBase Shutdown Script for shared_net Docker Network
# This script cleanly shuts down TrailBase and performs cleanup

set -e

echo "🛑 Shutting down TrailBase..."

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    case $color in
        "red") echo -e "\033[31m$message\033[0m" ;;
        "green") echo -e "\033[32m$message\033[0m" ;;
        "yellow") echo -e "\033[33m$message\033[0m" ;;
        "blue") echo -e "\033[34m$message\033[0m" ;;
        *) echo "$message" ;;
    esac
}

# Check if container is running
if docker compose -f docker-compose.shared-net.yml ps 2>/dev/null | grep -q "trail"; then
    print_status "yellow" "TrailBase container is running. Stopping it gracefully..."

    # Graceful shutdown with timeout
    print_status "blue" "Sending SIGTERM to TrailBase container..."
    docker compose -f docker-compose.shared-net.yml stop trail || {
        print_status "red" "Failed to stop container gracefully"
        exit 1
    }

    # Wait for graceful shutdown
    echo "Waiting for container to stop..."
    sleep 3

    # Force stop if still running
    if docker ps -q -f name=trailbase | grep -q .; then
        print_status "yellow" "Container still running, forcing shutdown..."
        docker compose -f docker-compose.shared-net.yml kill trail || true
    fi

    print_status "green" "✅ TrailBase container stopped successfully"
else
    print_status "yellow" "TrailBase container is not running"
fi

# Remove the container
print_status "blue" "Removing TrailBase container..."
if docker compose -f docker-compose.shared-net.yml down 2>/dev/null; then
    print_status "green" "✅ Container removed successfully"
else
    print_status "yellow" "Container was already removed or doesn't exist"
fi

# Optional: Clean up unused Docker resources
read -p "Clean up unused Docker images and volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "blue" "Cleaning up unused Docker resources..."

    # Remove unused images
    print_status "blue" "Removing unused Docker images..."
    docker image prune -f || true

    # Remove unused volumes (be careful with this!)
    print_status "yellow" "WARNING: This will remove unused volumes including possibly your data!"
    read -p "Remove unused volumes? (NOT RECOMMENDED - Type 'YES' to confirm): " -r
    echo
    if [[ $REPLY == "YES" ]]; then
        docker volume prune -f || true
        print_status "green" "✅ Unused volumes removed"
    else
        print_status "blue" "Skipping volume cleanup (recommended)"
    fi

    # Clean up networks
    print_status "blue" "Removing unused Docker networks..."
    docker network prune -f || true

    print_status "green" "✅ Docker cleanup completed"
fi

# Backup configuration
if [ -f .env ]; then
    backup_dir="/mnt/backblaze/trailbase/backups/config"
    backup_file="$backup_dir/env-$(date +%Y%m%d-%H%M%S).backup"

    if [ ! -d "$backup_dir" ]; then
        mkdir -p "$backup_dir"
    fi

    cp .env "$backup_file" 2>/dev/null || true
    print_status "blue" "Configuration backed up to: $backup_file"
fi

# Show final status
echo ""
print_status "green" "🎉 Shutdown completed successfully!"
echo ""
echo "📊 Summary:"
echo "  - TrailBase container: stopped and removed"
echo "  - Docker network: shared_net (still available)"
echo "  - Data volume: /mnt/backblaze/trailbase (preserved)"
echo ""
echo "📂 Important directories preserved:"
echo "  - Data: /mnt/backblaze/trailbase/traildepot/"
echo "  - Logs: /mnt/backblaze/trailbase/logs/"
echo "  - Backups: /mnt/backblaze/trailbase/backups/"
echo ""
echo "🚀 To start TrailBase again:"
echo "  ./setup-shared-net.sh"
echo ""
echo "🔍 To check the network:"
echo "  docker network inspect shared_net"
echo ""
echo "📝 To remove everything (including data):"
echo "  sudo rm -rf /mnt/backblaze/trailbase"
echo "  docker network rm shared_net"