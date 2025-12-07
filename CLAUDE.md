# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# 🛑 STOP — Run codemap before ANY task

```bash
codemap .                     # Project structure
codemap --deps                # How files connect
codemap --diff                # What changed vs main
codemap --diff --ref <branch> # Changes vs specific branch
```

## Required Usage

**BEFORE starting any task**, run `codemap .` first.

**ALWAYS run `codemap --deps` when:**
- User asks how something works
- Refactoring or moving code
- Tracing imports or dependencies

**ALWAYS run `codemap --diff` when:**
- Reviewing or summarizing changes
- Before committing code
- User asks what changed
- Use `--ref <branch>` when comparing against something other than main

## Essential Development Commands

### Rust/Crate Development
```bash
# Build the main TrailBase binary
cargo build --bin trail
cargo build --bin trail --release  # Optimized release build

# Run tests
cargo test                         # Run all tests
cargo test --package trailbase-core  # Test specific package
cargo test --package trailbase-client  # Test client package

# Development server with permissive CORS/cookies
cargo run -- --data-dir client/testfixture run --dev

# Check and format
cargo check                        # Quick compilation check
cargo clippy --workspace --no-deps # Lint
cargo +nightly fmt                 # Format code
```

### JavaScript/TypeScript (Admin UI & Client)
```bash
# Admin dashboard development
cd crates/assets/js/admin
pnpm install
pnpm run dev                       # Development server with hot reload
pnpm run build                     # Build for production
pnpm run check                     # TypeScript check + lint + tests
pnpm run test                      # Run tests

# Protobuf code generation (requires protoc and libprotobuf-dev)
pnpm run proto                     # Generate TypeScript types from protobuf

# Client library
cd crates/assets/js/client
pnpm install
pnpm run build                     # Build client library
pnpm run check                     # TypeScript check + lint
```

### Authentication UI
```bash
cd crates/auth-ui/ui
pnpm install
pnpm run dev                       # Development server
pnpm run build                     # Build for production
```

### Documentation
```bash
cd docs
pnpm install
pnpm run dev                       # Development server
pnpm run build                     # Build static site
```

### Full Project Commands
```bash
# Format all codebases (Rust, JS, Dart, C#, Python, Swift, Go)
make format

# Check all codebases (lint + type checking)
make check

# Build static binary
make static

# Docker build
make docker
docker build . -t trailbase

# Install dependencies (first time setup)
git submodule update --init --recursive
pnpm install
```

## High-Level Architecture

### Core Components

**TrailBase** is a single-executable backend built on Rust with these key components:

1. **Core Server** (`crates/core/`): Main application server handling:
   - HTTP/WebSocket server using Axum
   - SQLite database with custom extensions
   - Authentication & authorization
   - Admin API endpoints
   - Real-time subscriptions (SSE)
   - WebAssembly runtime for extensions

2. **Admin Dashboard** (`crates/assets/js/admin/`): SolidJS-based SPA for:
   - Database schema management
   - User management
   - API key management
   - Log viewing
   - File uploads
   - Real-time monitoring

3. **Authentication UI** (`crates/auth-ui/`): Astro-based UI for:
   - Login/logout flows
   - User registration
   - Password reset
   - Email verification
   - Profile management
   - OAuth provider integration

4. **Client Libraries** (`client/`): Type-safe client libraries for:
   - TypeScript/JavaScript
   - Rust
   - Dart/Flutter
   - Python
   - Go
   - Swift
   - C#/.NET
   - Kotlin

5. **WebAssembly Runtime**: Wasmtime-based runtime for:
   - Custom server-side logic
   - Database extensions
   - API endpoints
   - Authentication providers
   - Middleware components

### Key Directories

- `crates/`: Rust crates making up the core server
- `client/`: Multi-language client libraries
- `examples/`: Example applications and demos
- `docs/`: Documentation website (Astro/Starlight)
- `client/testfixture/`: Test fixtures and integration tests

### Database & Schema

- Uses SQLite as the embedded database
- SQL migrations in `traildepot/migrations/`
- Schema metadata and type information
- Automatic REST API generation from schemas
- Real-time subscriptions based on table changes

### Configuration

- Single `traildepot/` directory contains all runtime data
- `config.textproto` for server configuration
- Database files in `traildepot/data/`
- File uploads in `traildepot/uploads/`
- Backups in `traildepot/backups/`

## Development Workflow

### Setting up Development Environment

1. Install dependencies:
   ```bash
   # System dependencies
   sudo apt-get install -y curl libssl-dev pkg-config libclang-dev protobuf-compiler libprotobuf-dev

   # Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

   # Node.js & pnpm
   curl -fsSL https://get.pnpm.io/install.sh | sh
   ```

2. Clone and setup:
   ```bash
   git clone --recursive https://github.com/trailbaseio/trailbase.git
   cd trailbase
   git submodule update --init --recursive
   pnpm install
   ```

### Testing Individual Components

**For the main server:**
```bash
cargo test --package trailbase-core
```

**For admin UI:**
```bash
cd crates/assets/js/admin
pnpm run test
```

**For client libraries:**
```bash
# TypeScript client
cd crates/assets/js/client
pnpm run check

# Rust client
cd client/rust
cargo test

# Python client
cd client/python
poetry run pytest
```

### Common Development Patterns

1. **Protobuf First**: API schemas defined in `.proto` files in `crates/core/proto/`
2. **Type Generation**: TypeScript types auto-generated from Rust using `ts-rs`
3. **Migration Driven**: Database changes via SQL migrations
4. **WASM Components**: Extensible via WebAssembly guests
5. **Multi-client**: Same API exposed to all client libraries

### Examples Development

```bash
# Blog example (web + Flutter)
cd examples/blog
make types      # Generate type definitions
cargo run -- run --public-dir web/dist

# Coffee vector search
cd examples/coffee-vector-search
cargo run

# WASM guest examples
cd examples/wasm-guest-rust
cargo build --target wasm32-wasi
```

## Project-specific Notes

- **Single Binary**: Everything compiles to one `trail` executable
- **Embedded Assets**: All web assets embedded at build time
- **No External Dependencies**: Self-contained except for system libraries
- **Cross-platform**: Linux, macOS, Windows support
- **WASM Extensions**: Use `wasmtime` for safe sandboxed extensions
- **SQLite Extensions**: Custom vector search and other extensions built-in

## Debugging Tips

- Use `RUST_LOG=debug` for verbose logging
- Admin UI available at `/_/admin` when running
- Use `--dev` flag for permissive CORS during development
- Database accessible via SQLite tools at `traildepot/data/db`
- Real-time logs available in admin dashboard

## Performance Considerations

- Sub-millisecond query latencies typical
- Built for high-concurrency with Tokio async runtime
- SQLite provides excellent performance for read-heavy workloads
- WebAssembly components have minimal overhead
- Static asset serving optimized for performance