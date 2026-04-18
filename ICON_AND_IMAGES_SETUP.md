# App Icon Replacement & Profile Image Setup Guide

## 🎨 Step 1: Replace App Icon with VF Logo

### For Android:
1. Save your VF logo image as: `lib/assets/icon.jpeg` (1024x1024 pixels recommended)
2. Run: `flutter pub run flutter_launcher_icons:main`
3. This generates icons for all sizes automatically

### For iOS:
- The icon will be generated automatically from `lib/assets/icon.jpeg`

### For All Platforms:
```bash
cd vettri
flutter pub run flutter_launcher_icons:main
flutter clean
flutter pub get
flutter run
```

---

## 📸 Step 2: Setup Profile Image Uploads

### Backend Setup (PHP):

1. **Create uploads directory** by visiting:
   ```
   https://pcstech.in/gym/gym_api/setup_uploads.php
   ```
   Should show: "✅ Uploads directory created successfully"

2. **Verify directory permissions**:
   - Directory must be writable (chmod 777 on Linux/Mac)
   - Windows should allow write access automatically

### Database Setup:

1. **Check if photo column exists**:
   ```sql
   SHOW COLUMNS FROM members LIKE 'photo';
   ```

2. **If photo column doesn't exist, add it**:
   ```sql
   ALTER TABLE members ADD COLUMN photo VARCHAR(255) DEFAULT NULL;
   ```

---

## 🖼️ Step 3: Add Sample Member Images

### Upload sample images:

1. **Via Add Member Screen** (In-app):
   - Click "Add Members"
   - Enter member details
   - Click "Capture Photo" to take/upload image
   - Complete registration

2. **Via Direct File Upload** (If members already exist):
   - Save images to: `/gym/gym_api/uploads/`
   - Name format: `{timestamp}_{unique_id}.jpg`
   - Example: `1713386400_5f8c1d2a.jpg`
   - Update database: 
     ```sql
     UPDATE members SET photo='1713386400_5f8c1d2a.jpg' WHERE id=1;
     ```

---

## 🐛 Step 4: Debug Profile Image Loading

### Check logs in Flutter console:

When you load a member profile, you should see:
```
📸 Member Photo URL: https://pcstech.in/gym/gym_api/uploads/1713386400_5f8c1d2a.jpg
```

If you see:
```
📸 Member Photo URL: 
```
Then photo is NULL in database - upload a new member with a photo.

### Test API directly:

Visit this URL in browser:
```
https://pcstech.in/gym/gym_api/get_member_profile.php?id=1
```

Should return:
```json
{
  "status": "success",
  "member": {
    "id": "1",
    "name": "Member Name",
    "phone": "1234567890",
    "photo": "https://pcstech.in/gym/gym_api/uploads/filename.jpg",
    ...
  }
}
```

---

## ✅ Checklist

- [ ] VF logo image saved as `lib/assets/icon.jpeg` (1024x1024px)
- [ ] Ran `flutter pub run flutter_launcher_icons:main`
- [ ] Uploads directory exists and is writable
- [ ] Photo column exists in members table
- [ ] Tested profile image loading with debugging logs
- [ ] At least one member has a photo uploaded

---

## 🔄 Full Rebuild Commands

```bash
cd c:\wamp64\www\gym\vettri

# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Generate icons
flutter pub run flutter_launcher_icons:main

# Run app
flutter run
```

---

## 📝 Notes

- App icon changes won't show until you uninstall and reinstall the app
- Profile images use caching - clear app cache if old images still show
- Supported image formats: JPG, PNG
- Max file size: 5MB (configurable in member.php)
