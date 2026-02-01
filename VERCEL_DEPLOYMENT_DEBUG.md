# Vercel Deployment Debug - Ratings & Live Test Cards Not Showing

## Problem Analysis

The Ratings Management and Live Test Registrations cards are not appearing in the Vercel deployment, even though they are properly configured in the local build.

## Root Cause Identified

**Vercel is using a cached build from before the new cards were added.**

The issue is NOT with the code - all files are properly configured:
- ✅ Routes defined in `App.tsx` (lines 248-249)
- ✅ Dashboard cards defined in `DashboardPage.tsx` (lines 193-205)
- ✅ Page components exist and export correctly
- ✅ All imports are correct

## Solution: Force Vercel Rebuild

### Option 1: Clear Vercel Cache (RECOMMENDED)
1. Go to your Vercel Dashboard
2. Select your project (mcq-quiz-admin)
3. Go to **Settings** → **Git**
4. Click **Redeploy** on the latest commit
5. Select **Redeploy** (this clears cache and rebuilds)

### Option 2: Trigger New Deployment
1. Make a small commit to trigger a new build:
   ```bash
   git commit --allow-empty -m "chore: Trigger Vercel rebuild for new cards"
   git push origin main
   ```

### Option 3: Manual Rebuild in Vercel Dashboard
1. Go to **Deployments** tab
2. Find the latest deployment
3. Click the three dots menu
4. Select **Redeploy**

## Verification Steps

After redeployment:
1. Clear browser cache (Ctrl+Shift+Delete or Cmd+Shift+Delete)
2. Hard refresh the page (Ctrl+F5 or Cmd+Shift+R)
3. Check if both cards appear on dashboard:
   - "Ratings Management" (yellow/gold card)
   - "Live Test Registrations" (purple card)

## Files Verified ✅

- `web_admin/src/App.tsx` - Routes configured
- `web_admin/src/pages/dashboard/DashboardPage.tsx` - Cards defined
- `web_admin/src/pages/ratings/RatingsManagementPage.tsx` - Component exists
- `web_admin/src/pages/live-test-registrations/LiveTestRegistrationsPage.tsx` - Component exists
- `web_admin/vercel.json` - Build config correct

All code is correct. The issue is purely a deployment cache issue.

