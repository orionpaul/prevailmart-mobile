# PrevailMart Mobile App Guide

## 📱 Mobile App vs 🖥️ Website Dashboard

### Mobile App (This App)
**Purpose**: Shopping & Delivery on-the-go

**Users**:
- ✅ **Customers**: Browse products, add to cart, checkout, track orders
- ✅ **Drivers**: Accept deliveries, navigate, update delivery status
- ❌ **Admin/SuperAdmin**: NOT available on mobile - use website instead

**Features**:
- 🛒 Product browsing (guest & authenticated)
- 🛍️ Shopping cart & checkout
- 📦 Order tracking
- 🚚 Driver delivery management
- 📍 Real-time location tracking (drivers)

### Website Dashboard (https://your-website.com)
**Purpose**: Administrative & Management Tasks

**Users**:
- ✅ **Admin**: Product management, order processing
- ✅ **SuperAdmin**: User management, driver creation, platform stats
- ✅ **All roles**: Can also access customer features

**Features**:
- 👥 User & driver management
- 📊 Analytics & reports
- 🏪 Product catalog management
- ⚙️ System configuration
- 📈 Platform statistics

## 🔐 User Role Behavior on Mobile

| Role | Login Status | Mobile App Behavior |
|------|--------------|---------------------|
| **Guest** | Not logged in | Browse products, see featured items (can't checkout) |
| **Customer** | Logged in | Full shopping experience + orders |
| **Driver** | Logged in | Delivery interface with active deliveries |
| **Admin** | Logged in | Shows customer view (use website for admin tasks) |
| **SuperAdmin** | Logged in | Shows customer view (use website for admin tasks) |

## 📝 Important Notes

1. **Admin Login on Mobile**: If an admin/superadmin logs into the mobile app, they will see the customer shopping interface. This is by design - all administrative features are exclusively on the website dashboard.

2. **Console Message**: When admin/superadmin logs in, you'll see:
   ```
   ⚠️ Admin/SuperAdmin detected - showing customer view
   ℹ️ Please use website dashboard for admin features
   ```

3. **User Management**: Creating drivers, managing users, and viewing platform stats should ONLY be done through the website dashboard.

## 🚀 Running the App

```bash
# Install dependencies
flutter pub get

# Run on device/simulator
flutter run

# Build for production
flutter build apk      # Android
flutter build ios      # iOS
```

## 🎨 App Features

- ✨ Smooth animations
- 🎨 Supermarket-themed UI
- 🔐 Secure storage (encrypted)
- 📱 Responsive design
- 🌐 Real-time updates
- 🛒 Guest browsing
- 📦 Order tracking

## 📂 Project Structure

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── providers/       # State management
├── screens/
│   ├── auth/       # Login/Register
│   ├── customer/   # Shopping screens
│   └── driver/     # Delivery screens
├── services/        # API & storage
└── widgets/         # Reusable components
```

## 🔗 Related

- **Backend API**: https://backend-prevailmart.onrender.com
- **Website Dashboard**: Use for all admin features
- **Documentation**: See project README files
