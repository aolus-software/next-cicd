# ========================================
# Makefile for Next.js + Prisma Project
# ========================================
#
# Common commands:
#   make dev           - Start Next.js dev server
#   make start         - Start Next.js prod server
#   make build         - Build Next.js app
#   make lint          - Run ESLint
#   make format        - Run Prettier (or your formatter)
#   make test          - Run tests
#   make deploy-prep   - Install deps, run migrations, build
#
# Prisma / DB helpers (optional; remove if not using Prisma):
#   make db-generate   - Generate Prisma Client
#   make db-migrate    - Run migrations (deploy)
#   make db-migrate-dev- Run migrations (dev)
#   make db-seed       - Run DB seed
#   make db-studio     - Open Prisma Studio
#
# ========================================

# ===========================
# Help
# ===========================
help:
	@echo ""
	@echo "Available commands:"
	@echo "  make dev             - Start Next.js development server"
	@echo "  make start           - Start Next.js production server"
	@echo "  make build           - Build the Next.js app"
	@echo "  make lint            - Run ESLint"
	@echo "  make format          - Run code formatter"
	@echo "  make test            - Run tests"
	@echo "  make test-watch      - Run tests in watch mode"
	# @echo "  make db-generate     - Generate Prisma Client"
	# @echo "  make db-migrate      - Run Prisma migrate deploy"
	# @echo "  make db-migrate-dev  - Run Prisma migrate dev"
	# @echo "  make db-seed         - Run DB seeder"
	# @echo "  make db-studio       - Open Prisma Studio"
	@echo "  make deploy-prep     - Prepare app for deployment"
	@echo ""

# ===========================
# Next.js app
# ===========================
dev:
	@echo "Starting Next.js development server..."
	npm run dev

start:
	@echo "Starting Next.js production server..."
	npm run start

build:
	@echo "Building Next.js app..."
	npm run build

# ===========================
# Lint & Format
# ===========================
lint:
	@echo "Running ESLint..."
	npm run lint

format:
	@echo "Running formatter..."
	npm run format

# ===========================
# Tests
# ===========================
test:
	@echo "Running tests..."
	npm test

test-watch:
	@echo "Running tests in watch mode..."
	npm run test:watch

# ===========================
# Database (Prisma)
# ===========================
# db-generate:
# 	@echo "Generating Prisma Client..."
# 	npx prisma generate

# db-migrate:
# 	@echo "Running Prisma migrations (deploy)..."
# 	npx prisma migrate deploy

# db-migrate-dev:
# 	@echo "Running Prisma migrations (dev)..."
# 	npx prisma migrate dev

# db-seed:
# 	@echo "Running database seeder..."
# 	npm run seed

# db-studio:
# 	@echo "Starting Prisma Studio..."
# 	npx prisma studio

# ===========================
# Deployment
# ===========================
deploy-prep:
	@echo "Preparing Next.js app for deployment..."
	npm install
	npx prisma migrate deploy
	npx prisma generate
	npm run build

# ===========================
# Phony Targets
# ===========================
.PHONY: \
	help dev start build lint format test test-watch \
	deploy-prep
	# db-generate db-migrate db-migrate-dev db-seed db-studio