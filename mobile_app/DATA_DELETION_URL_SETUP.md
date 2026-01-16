# Data Deletion URL Setup for Google Play

## 🎯 **Google Play Requirement**

Google Play requires apps that collect user data to provide a **Data Deletion URL** that allows users to request account and data deletion.

## 📋 **What You Need to Provide**

### **Delete Account URL**
You need to enter a valid URL in Google Play Console that:
- Refers to your app name "Dakshin Postal Academy"
- Prominently features steps for account deletion
- Specifies what data is deleted/kept and retention periods

## 🌐 **URL Options**

### **Option 1: Host on Your Website (Recommended)**
If you have a website, upload the HTML file and use:
```
https://yourdomain.com/data-deletion-policy.html
```

### **Option 2: GitHub Pages (Free Hosting)**
1. Create a GitHub repository
2. Upload `data_deletion_policy.html`
3. Enable GitHub Pages
4. Use URL like:
```
https://yourusername.github.io/repository-name/data_deletion_policy.html
```

### **Option 3: Google Sites (Free)**
1. Create a Google Site
2. Copy the content from the HTML file
3. Publish and use the Google Sites URL

### **Option 4: Simple Landing Page Service**
Use services like:
- Netlify (free)
- Vercel (free)
- Firebase Hosting (free)

## 📧 **Email Setup Required**

The deletion policy references these email addresses. You need to set up:

### **Required Email Addresses**
- `privacy@dakshinpostalacademy.com` - For deletion requests
- `support@dakshinpostalacademy.com` - For general support
- `tech@dakshinpostalacademy.com` - For technical issues

### **Alternative Email Setup**
If you don't have a custom domain, you can use:
- Gmail with custom aliases
- Your existing support email
- Update the HTML file with your actual email addresses

## 🔧 **Quick Setup Instructions**

### **Step 1: Choose Hosting Option**
Pick one of the hosting options above based on your needs.

### **Step 2: Update Email Addresses**
Edit the HTML file to replace email addresses with your actual ones:
```html
<!-- Replace these in the HTML file -->
privacy@dakshinpostalacademy.com → your-privacy-email@gmail.com
support@dakshinpostalacademy.com → your-support-email@gmail.com
tech@dakshinpostalacademy.com → your-tech-email@gmail.com
```

### **Step 3: Upload and Get URL**
Upload the file to your chosen hosting service and get the public URL.

### **Step 4: Enter URL in Google Play Console**
Go to Google Play Console → App Content → Data Safety → Data Deletion and enter your URL.

## 📝 **Content Compliance**

The provided HTML page includes all required elements:

### ✅ **App/Developer Name Reference**
- Prominently displays "Dakshin Postal Academy"
- Matches your Google Play store listing

### ✅ **Clear Deletion Steps**
1. Send email to privacy team
2. Include registered phone/email
3. Specify subject line
4. 30-day processing time

### ✅ **Data Types Specified**
- **Deleted**: Personal info, quiz data, app usage, profile data
- **Retained**: Payment records (7 years), support communications (3 years)
- **Retention Periods**: Clearly specified with legal justification

### ✅ **Contact Information**
- Multiple contact methods provided
- Clear email templates included
- Response time commitments

## 🚀 **Quick Implementation (GitHub Pages)**

If you want to set this up quickly using GitHub Pages:

### **Step 1: Create GitHub Repository**
1. Go to GitHub.com
2. Create new repository (e.g., "dakshin-postal-academy-policies")
3. Make it public

### **Step 2: Upload File**
1. Upload `data_deletion_policy.html` to the repository
2. Go to Settings → Pages
3. Enable GitHub Pages from main branch

### **Step 3: Get URL**
Your URL will be:
```
https://yourusername.github.io/dakshin-postal-academy-policies/data_deletion_policy.html
```

### **Step 4: Test and Submit**
1. Test the URL in a browser
2. Verify all links work
3. Enter URL in Google Play Console

## 📧 **Email Template for Deletion Requests**

When users click the email link, they'll get this pre-filled template:

```
Subject: Account Deletion Request

Hello,

I would like to request the deletion of my Dakshin Postal Academy account and all associated data.

My registered phone number/email: [User enters their details]

Thank you.
```

## 🔍 **Testing Checklist**

Before submitting to Google Play, verify:

- [ ] URL loads correctly
- [ ] Page displays "Dakshin Postal Academy" prominently
- [ ] Deletion steps are clear and prominent
- [ ] Data types and retention periods are specified
- [ ] Email links work correctly
- [ ] Contact information is accurate
- [ ] Page is mobile-friendly
- [ ] All links are functional

## 📱 **Google Play Console Entry**

### **Where to Enter**
1. Google Play Console
2. Your App → App Content
3. Data Safety section
4. "Data Deletion" section
5. Enter your URL in "Delete account URL" field

### **URL Format**
Make sure your URL:
- Starts with `https://`
- Is publicly accessible
- Loads quickly
- Works on mobile devices

## 🛠️ **Maintenance**

### **Keep Updated**
- Review the page annually
- Update contact information if changed
- Ensure email addresses remain active
- Monitor for broken links

### **Response Process**
When you receive deletion requests:
1. Acknowledge receipt within 48 hours
2. Process deletion within 30 days
3. Send confirmation when complete
4. Keep records of deletion requests

## ✅ **Ready to Submit**

Once you have:
1. ✅ Hosted the HTML file publicly
2. ✅ Tested the URL works
3. ✅ Updated email addresses
4. ✅ Verified all content is accurate

You can enter the URL in Google Play Console and resubmit your app!

---

## 📞 **Need Help?**

If you need assistance with:
- Setting up hosting
- Configuring email addresses
- Customizing the content
- Technical implementation

The HTML file is ready to use and fully compliant with Google Play requirements!
