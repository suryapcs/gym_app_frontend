# 🚀 Quick Start: App Icon & Profile Images

## ⚡ 5-Minute Setup

### Step 1: Verify Backend Setup (1 min)
Visit this URL to auto-fix database schema:
```
https://pcstech.in/gym/gym_api/check_schema.php
```

You should see:
```json
{
  "members_columns": [..., "photo"],
  "has_photo": true,
  "uploads_dir_exists": true,
  "uploads_dir_writable": true,
  "total_members": 5,
  "members_with_photos": 0,
  "sample_members": [...]
}
```

---

### Step 2: Replace App Icon (2 min)

**Your VF logo image:**
1. Save as: `c:\wamp64\www\gym\vettri\lib\assets\icon.jpeg`
   - **Size**: 1024x1024 pixels (or larger)
   - **Format**: JPEG or PNG
   - **Quality**: High quality (no compression artifacts)

2. Run in terminal:
```bash
cd c:\wamp64\www\gym\vettri
flutter pub run flutter_launcher_icons:main
```

---

### Step 3: Upload Member Photos (1 min)

In the Flutter app:
1. Click **"Add Members"** from Dashboard
2. Enter member details (Name, Phone, Address)
3. Click **"Capture Photo"** button
4. Take/select a photo from gallery
5. Click **"Proceed to Payment"**
6. Complete the payment

Now that member will have a profile photo! ✅

---

### Step 4: Rebuild App (1 min)

```bash
cd c:\wamp64\www\gym\vettri
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Verify It's Working

1. **Open Members list** - Should see member photos with names
2. **Click on a member** - Profile page shows larger photo
3. **Check app icon** - Should show your VF logo (may need to uninstall first)

---

## ❓ Troubleshooting

### Photos still empty?
✅ **Check database:**
```
https://pcstech.in/gym/gym_api/check_schema.php
```

### Check API response:
```
https://pcstech.in/gym/gym_api/get_member_profile.php?id=1
```

Should show:
```json
{
  "photo": "https://pcstech.in/gym/gym_api/uploads/1713386400_abc123.jpg"
}
```

### Icon not updating?
1. Uninstall app from device
2. Run `flutter clean`
3. Rebuild and reinstall

---

## 📂 File Locations

| What | Location |
|------|----------|
| App Icon | `c:\wamp64\www\gym\vettri\lib\assets\icon.jpeg` |
| Uploads | `c:\wamp64\www\gym\gym_api\uploads\` |
| Member Photos | Database photo column + uploads folder |

---

## ✅ Checklist

- [ ] Icon saved as `lib/assets/icon.jpeg` (1024x1024px)
- [ ] Ran `flutter pub run flutter_launcher_icons:main`
- [ ] Check schema returned `"has_photo": true`
- [ ] Uploaded at least one member with photo
- [ ] App rebuilt and shows new icon
- [ ] Profile page displays member photos

---

**That's it! Your app should now have:**
- ✅ VF logo as app icon
- ✅ Member profile photos displaying
- ✅ Professional appearance
