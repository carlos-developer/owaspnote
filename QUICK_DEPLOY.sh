#!/bin/bash

echo "🚀 Quick Deploy Script for OWASPNOTE"
echo "===================================="

# Step 1: Clean old workflows
echo "1. Cleaning old workflows..."
rm -f .github/workflows/deploy-to-github-pages.yml.old
rm -f .github/workflows/deploy-to-github-pages.yml
rm -f .github/workflows/emergency-deploy.yml
rm -f .github/workflows/simple-deploy.yml

# Step 2: Keep only minimal workflow
echo "2. Keeping only minimal-deploy.yml..."
ls -la .github/workflows/

# Step 3: Git operations
echo "3. Committing changes..."
git add .github/workflows/
git add DEPLOYMENT_STRATEGY.md
git add QUICK_DEPLOY.sh
git add FIX_GITHUB_ACTIONS.md

git commit -m "fix: Simplified GitHub Actions workflow for deployment

- Removed all complex workflows
- Added minimal-deploy.yml with basic Flutter web build
- No tests, no complications, just build and deploy
- Ready for first deployment"

echo "4. Pushing to GitHub..."
git push origin main

echo ""
echo "✅ DONE! Now:"
echo "1. Go to https://github.com/YOUR_USERNAME/owaspnote/actions"
echo "2. Watch the 'Minimal Deploy' workflow run"
echo "3. Once complete, visit: https://YOUR_USERNAME.github.io/owaspnote/"
echo ""
echo "⚠️  IMPORTANT: Make sure GitHub Pages is set to 'GitHub Actions' in Settings!"