# CI/CD Setup Guide for Next.js on Ubuntu Server

This guide covers setting up a complete CI/CD pipeline using GitHub Actions to deploy a Next.js application to Ubuntu EC2 instances on AWS across 3 environments: Development, Staging, and Production.

---

## Part 1: Generate Public Key from PEM File

### Step 1: Locate Your PEM File

Ensure you have your existing `.pem` file (e.g., `your-key.pem`) downloaded from AWS.

### Step 2: Generate Public Key

Open your terminal and run:

```bash
ssh-keygen -y -f /path/to/your-key.pem > your-key.pub
```

Replace `/path/to/your-key.pem` with the actual path to your PEM file.

### Step 3: Verify Public Key

View the generated public key:

```bash
cat your-key.pub
```

You should see output starting with `ssh-rsa` or `ssh-ed25519`.

---

## Part 2: Add Keys to Ubuntu EC2 Server

### Step 1: Connect to Your Server

```bash
ssh -i your-key.pem ubuntu@your-server-ip
```

### Step 2: Add Public Key to Authorized Keys

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
```

Paste your public key content, save and exit (Ctrl+X, then Y, then Enter).

### Step 3: Set Correct Permissions

```bash
chmod 600 ~/.ssh/authorized_keys
```

### Step 4: Store PEM File Securely

Keep your `.pem` file in a secure location on your local machine. You will need its content for GitHub secrets later.

---

## Part 3: GitHub Actions Workflow Configuration

The workflow file (`.github/workflows/deploy.yaml`) is already configured with three stages:

1. **Lint and Format Check** - Validates code quality
2. **Build** - Builds the Next.js application
3. **Deploy** - Deploys to the appropriate environment based on branch

Trigger branches:

- `dev` → Development environment (Port 3001)
- `staging` → Staging environment (Port 3002)
- `main` → Production environment (Port 3000)

---

## Part 4: Configure GitHub Repository Secrets

### Step 1: Access Repository Settings

1. Go to your GitHub repository
2. Click on "Settings"
3. Navigate to "Secrets and variables" > "Actions"

### Step 2: Create Environments

1. Go to "Environments" in the left sidebar
2. Click "New environment"
3. Create three environments: `development`, `staging`, and `production`

### Step 3: Add Development Environment Secrets

For the `development` environment (triggered by `dev` branch), add these secrets:

```
DEV_HOST = your-dev-server-ip
DEV_USERNAME = ubuntu
DEV_SSH_KEY = [content of your .pem file]
DEV_PORT = 22
DEV_APP_DIRECTORY = /home/ubuntu/your-app
DEV_PM2_APP_NAME = your-app-dev
```

### Step 4: Add Staging Environment Secrets

For the `staging` environment (triggered by `staging` branch), add these secrets:

```
STAGING_HOST = your-staging-server-ip
STAGING_USERNAME = ubuntu
STAGING_SSH_KEY = [content of your .pem file]
STAGING_PORT = 22
STAGING_APP_DIRECTORY = /home/ubuntu/your-app
STAGING_PM2_APP_NAME = your-app-staging
```

### Step 5: Add Production Environment Secrets

For the `production` environment (triggered by `main` branch), add these secrets:

```
PRODUCTION_HOST = your-production-server-ip
PRODUCTION_USERNAME = ubuntu
PRODUCTION_SSH_KEY = [content of your .pem file]
PRODUCTION_PORT = 22
PRODUCTION_APP_DIRECTORY = /home/ubuntu/your-app
PRODUCTION_PM2_APP_NAME = your-app-prod
```

### Step 6: Copy PEM File Content

To get the SSH key content:

```bash
cat your-key.pem
```

Copy the entire output including the BEGIN and END lines.

---

## Part 5: Add Deploy Key to GitHub

### Step 1: Access GitHub Account Settings

1. Click your profile picture (top right)
2. Go to "Settings"
3. Navigate to "SSH and GPG keys"

### Step 2: Add New SSH Key

1. Click "New SSH key"
2. Give it a title (e.g., "CI/CD Deploy Key")
3. Paste your public key content from `your-key.pub`
4. Click "Add SSH key"

---

## Part 6: Server Preparation

### Step 1: Install Node.js and NPM

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Step 2: Install PM2 Globally

```bash
sudo npm install -g pm2
```

### Step 3: Clone Your Repository

```bash
cd /home/ubuntu
git clone git@github.com:your-username/your-repo.git your-app
cd your-app
```

### Step 4: Install Dependencies and Build

```bash
npm install --omit=dev
npm run build
```

### Step 5: Start Application with PM2

For development:

```bash
export PORT=3001
pm2 start "npm start" --name "your-app-dev"
pm2 save
pm2 startup
```

For staging:

```bash
export PORT=3002
pm2 start "npm start" --name "your-app-staging"
pm2 save
pm2 startup
```

For production:

```bash
export PORT=3000
pm2 start "npm start" --name "your-app-prod"
pm2 save
pm2 startup
```

Follow the command output to enable PM2 on system restart.

### Step 6: Configure PM2 Ecosystem (Optional)

Create `ecosystem.config.js` in your app directory:

```javascript
module.exports = {
	apps: [
		{
			name: "your-app-dev",
			script: "npm",
			args: "start",
			env: {
				NODE_ENV: "development",
				PORT: 3001,
			},
		},
		{
			name: "your-app-staging",
			script: "npm",
			args: "start",
			env: {
				NODE_ENV: "staging",
				PORT: 3002,
			},
		},
		{
			name: "your-app-prod",
			script: "npm",
			args: "start",
			env: {
				NODE_ENV: "production",
				PORT: 3000,
			},
		},
	],
};
```

### Step 7: Configure Nginx Reverse Proxy (Recommended)

Install Nginx:

```bash
sudo apt-get install -y nginx
```

Create Nginx config for each environment:

**Development** (`/etc/nginx/sites-available/dev-app`):

```nginx
server {
    listen 80;
    server_name your-dev-domain.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Staging** (`/etc/nginx/sites-available/staging-app`):

```nginx
server {
    listen 80;
    server_name your-staging-domain.com;

    location / {
        proxy_pass http://localhost:3002;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Production** (`/etc/nginx/sites-available/prod-app`):

```nginx
server {
    listen 80;
    server_name your-production-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable sites:

```bash
sudo ln -s /etc/nginx/sites-available/dev-app /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/staging-app /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/prod-app /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl restart nginx
```

---

## Part 7: Testing the Pipeline

### Step 1: Test Development Deployment

```bash
git checkout dev
echo "test" >> test.txt
git add test.txt
git commit -m "test: CI/CD pipeline"
git push origin dev
```

### Step 2: Test Staging Deployment

```bash
git checkout staging
git pull origin staging
git merge dev
git push origin staging
```

### Step 3: Test Production Deployment

```bash
git checkout main
git pull origin main
git merge staging
git push origin main
```

### Step 4: Monitor Workflow

1. Go to your GitHub repository
2. Click "Actions" tab
3. Watch the workflow execute through lint → build → deploy stages

---

## Part 8: Troubleshooting

### SSH Connection Issues

If deployment fails with SSH errors:

1. Verify SSH key format in secrets (include BEGIN/END lines)
2. Check server firewall allows SSH on port 22
3. Ensure AWS security group allows inbound SSH from GitHub Actions IPs

### Build Failures

If build stage fails:

1. Check Node.js version is 22+
2. Verify all dependencies are in package.json
3. Review build logs in GitHub Actions
4. Test build locally: `npm run build`

### PM2 Issues

If PM2 reload fails:

1. Verify PM2 app name matches secret for the environment
2. Check PM2 is running: `pm2 list`
3. Review PM2 logs: `pm2 logs`
4. Verify PORT environment variable is set correctly

### Permission Issues

If git pull fails:

1. Ensure server has SSH key to access GitHub
2. Verify application directory ownership: `sudo chown -R ubuntu:ubuntu /home/ubuntu/your-app`

### Next.js Build Issues

Common Next.js build errors:

1. Missing environment variables - ensure `.env.local` exists on server
2. Static generation errors - check for dynamic imports or external API calls
3. Image optimization issues - verify image sources are reachable

---

## Part 9: Security Best Practices

### Rotate SSH Keys Regularly

Update your PEM file and public key every 90 days.

### Use Minimal Permissions

Ensure the deploy user only has access to necessary directories.

### Monitor Deployment Logs

Regularly review GitHub Actions logs for suspicious activity.

### Keep Secrets Updated

When changing server IPs or credentials, immediately update GitHub secrets for all 3 environments.

### Enable Branch Protection

1. Go to repository Settings > Branches
2. Add protection rules for main, staging, and dev branches
3. Require status checks to pass before merging

### Environment-Specific Considerations

- **Development (Port 3001)**: Less strict requirements, allows frequent deployments
- **Staging (Port 3002)**: Mirror production setup, requires approval before merging
- **Production (Port 3000)**: Highest security, requires code review and status checks

### HTTPS/SSL Setup

For production, use Let's Encrypt with Certbot:

```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-production-domain.com
```

---

## Part 10: Workflow Diagram

The CI/CD pipeline follows this sequence for all 3 environments:

1. Developer pushes code to dev, staging, or main branch
2. GitHub Actions triggers workflow
3. **Lint and Format** stage:
   - Installs dependencies
   - Installs Husky hooks
   - Runs pre-commit hooks
   - Runs ESLint
   - Checks formatting
4. **Build** stage (if lint passes):
   - Installs production dependencies
   - Builds Next.js application
5. **Deploy** stage (if build succeeds):
   - SSH connects to target server
   - Pulls latest code from branch
   - Installs dependencies
   - Builds Next.js application
   - Sets PORT environment variable
   - Starts or reloads PM2 process

Deployment targets by branch:

- **dev branch** → Development server (Port 3001)
- **staging branch** → Staging server (Port 3002)
- **main branch** → Production server (Port 3000)

---

## Part 11: Environment Promotion Workflow

Recommended promotion path:

```
Dev Branch → Dev Server → Code Review
    ↓
Staging Branch → Staging Server → Testing
    ↓
Main Branch → Production Server → Live
```

### Promoting to Staging

```bash
git checkout staging
git pull origin staging
git merge dev
git push origin staging
```

### Promoting to Production

```bash
git checkout main
git pull origin main
git merge staging
git push origin main
```

---

## Part 12: Managing Environment Variables

### Development/Staging/Production .env Files

On each server, create `.env.local` in the app directory:

```bash
# Development
PORT=3001
NEXT_PUBLIC_API_URL=https://api-dev.example.com

# Staging
PORT=3002
NEXT_PUBLIC_API_URL=https://api-staging.example.com

# Production
PORT=3000
NEXT_PUBLIC_API_URL=https://api.example.com
```

The PORT variable from the workflow will override this, but you can set other environment variables here.

---

## Additional Resources

### Useful Commands

Check workflow status:

```bash
# List all workflows
gh workflow list

# View workflow runs
gh run list

# View specific workflow
gh run view <run-id>
```

Server management:

```bash
# Check PM2 status
pm2 status

# View application logs
pm2 logs your-app-dev

# Monitor server resources
htop

# Test linting locally
npm run lint

# Test formatting locally
npm run format

# Test build locally
npm run build

# Start Next.js in production mode
npm start
```

### Next.js Specific

- [Next.js Documentation](https://nextjs.org/docs)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Next.js Environment Variables](https://nextjs.org/docs/basic-features/environment-variables)

### PM2 Specific

- [PM2 Documentation](https://pm2.keymetrics.io/docs)
- [PM2 Startup](https://pm2.keymetrics.io/docs/usage/startup)
- [PM2 Ecosystem File](https://pm2.keymetrics.io/docs/usage/ecosystem-file)
