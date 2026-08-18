# KamJodo — Two-App Architecture Workflow
### Version: 2.0 | Status: Engineering Source of Truth
### Model: Rapido + Rapido Captain (Customer App + Worker App + Shared Backend)

---

## Table of Contents

1. [Product Vision](#1-product-vision)
2. [Two-App Strategy](#2-two-app-strategy)
3. [App 1 — KamJodo (Customer App)](#3-app-1--kamjodo-customer-app)
4. [App 2 — KamJodo Cap (Worker App)](#4-app-2--kamjodo-cap-worker-app)
5. [Shared Backend](#5-shared-backend)
6. [How Posts Flow Between Apps](#6-how-posts-flow-between-apps)
7. [Booking Lifecycle (End-to-End)](#7-booking-lifecycle-end-to-end)
8. [Data Models](#8-data-models)
9. [Realtime Architecture](#9-realtime-architecture)
10. [MVP Build Phases](#10-mvp-build-phases)
11. [Folder Structure](#11-folder-structure)
12. [Screen-by-Screen Spec](#12-screen-by-screen-spec)

---

## 1. Product Vision

KamJodo is a **two-sided local-services marketplace** for India.

### The Analogy (Rapido Model)

```
Rapido          →  Rider books a ride
Rapido Captain  →  Driver accepts ride requests

KamJodo         →  Customer finds & books a worker
KamJodo Cap     →  Worker creates profile, posts services & accepts job requests
```

### How it works

```
KamJodo Cap (Worker posts service)
        ↓
  Post visible in KamJodo (Customer sees it)
        ↓
  Customer books worker
        ↓
  KamJodo Cap receives notification (Accept / Reject)
        ↓
  Worker goes to customer location
        ↓
  Service done → Payment → Rating
```

**Both apps are completely separate APKs/apps** but share ONE backend API.

---

## 2. Two-App Strategy

| Feature | KamJodo (Customer) | KamJodo Cap (Worker) |
|---|---|---|
| **App Name** | KamJodo | KamJodo Cap |
| **Icon Color** | Blue / Indigo | Orange / Amber |
| **Target User** | People who need a service | Skilled workers who want jobs |
| **Primary Action** | Find & Book a Worker | Receive & Complete Jobs |
| **Package ID** | `com.kamjodo.app` | `com.kamjodo.cap` |
| **Flutter Folder** | `frontend/` | `frontend_cap/` |
| **Shared Backend** | ✅ Yes | ✅ Yes |
| **Login Method** | Name + Password (Quick) | Name + Password (Quick) |
| **Home Screen** | Search + Worker List | Dashboard (Online/Offline toggle) |

---

## 3. App 1 — KamJodo (Customer App)

### App Summary
- Customer opens **KamJodo**
- Sees nearby worker posts (like a service feed)
- Books a worker
- Tracks job status in real time
- Pays & rates the worker

### Navigation Shell (Bottom Nav)

```
🏠 Home    📰 Feed    💬 Messages    🔍 Search    👤 Profile
```

### Screen Flow

```
Splash Screen
    ↓
Role Not Selected → Role Selection (only for new users in single-app model)
    ↓              [NOW DEPRECATED — KamJodo = Customer Only]
Login Screen (Name + Password)
    ↓
Home Screen
```

### Home Screen Layout

```
┌─────────────────────────────────┐
│  Good Morning, Rahul 👋          │
│  [ 🔍 Search workers / services ] │
│                                  │
│  Popular Categories              │
│  🔧 🔌 🚿 🪟 🎨 🏠 🚗 📚        │
│                                  │
│  Nearby Workers                  │
│  ┌──────┐  ┌──────┐              │
│  │ Card │  │ Card │              │
│  └──────┘  └──────┘              │
│                                  │
│  Latest Service Posts            │
│  [Worker posts from KamJodo Cap] │
└─────────────────────────────────┘
```

### Worker Card (shown on Home / Search)

```
┌────────────────────────────────┐
│  [Photo]  Rahul Kumar          │
│           ✅ Verified           │
│           Plumber              │
│           ⭐ 4.8 (126 reviews)  │
│           📍 2.3 km away        │
│           ₹300 starting         │
│                                 │
│  [View Profile]    [Book Now]   │
└────────────────────────────────┘
```

### Worker Profile Screen (3 tabs)

```
Tab 1: About
- Photo, Name, Skills, Experience, Rating, Verified badge
- [Follow] [Message] [Call] [Book Now]

Tab 2: Posts
- All posts created by this worker in KamJodo Cap
- Customer can browse & book from post

Tab 3: Reviews
- Reviews from verified completed bookings only
```

### Booking Flow

```
[Book Now]
    ↓
Booking Form:
  - Service description
  - Preferred date & time
  - Location / Address
  - Budget (optional)
  - Notes (optional)
    ↓
[Confirm Booking]
    ↓
Booking Created (status: REQUESTED)
    ↓
Worker notified in KamJodo Cap
    ↓
Waiting for acceptance...
    ↓
Worker Accepted → Customer sees: "Rahul is coming!"
    ↓
Live Status Updates:
  WORKER_ON_THE_WAY → ARRIVED → SERVICE_STARTED → SERVICE_COMPLETED
    ↓
Payment → Rating
```

### Customer Bottom Tabs Explained

| Tab | Screen | Purpose |
|---|---|---|
| 🏠 Home | HomeScreen | Categories + Nearby Workers + Posts |
| 📰 Feed | FeedScreen | Worker posts & updates from followed workers |
| 💬 Messages | MessagesScreen | Chat with workers |
| 🔍 Search | SearchScreen | Search workers by category/name/skill |
| 👤 Profile | ProfileScreen | Account, Bookings, Settings |

---

## 4. App 2 — KamJodo Cap (Worker App)

### App Summary
- Worker opens **KamJodo Cap**
- Sets up a professional profile
- Creates service posts (visible in KamJodo customer app)
- Toggles Online/Offline
- Receives job requests (like Rapido Captain)
- Accepts → Goes → Completes → Gets paid → Earns reputation

### Navigation Shell (Bottom Nav)

```
🏠 Dashboard    📝 Posts    💬 Messages    📊 Earnings    👤 Profile
```

### Screen Flow

```
Splash Screen
    ↓
Login Screen (Name + Password)
    ↓
Worker Onboarding (first time only):
  Step 1: Personal Info (Name, City, Profile Photo)
  Step 2: What Work Do You Do? (Category selection)
  Step 3: Experience & Skills
  Step 4: Service Area & Availability
  Step 5: Create First Post
    ↓
Dashboard (Main Screen)
```

### Dashboard Screen Layout

```
┌─────────────────────────────────┐
│  KamJodo Cap 🧢                  │
│                                  │
│  [  🟢 ONLINE  ]  ← Toggle      │
│                                  │
│  Today's Stats                   │
│  ┌────────┬────────┬────────┐   │
│  │ 3 Jobs │ ₹1,450 │ 4.8⭐  │   │
│  └────────┴────────┴────────┘   │
│                                  │
│  ─────── INCOMING REQUESTS ─────│
│  ┌────────────────────────────┐ │
│  │ 🔔 New Job Request!         │ │
│  │  Plumbing — Saiful Ahmed   │ │
│  │  📍 2.3 km | ₹300+         │ │
│  │  [ACCEPT ✅]  [REJECT ❌]   │ │
│  └────────────────────────────┘ │
│                                  │
│  ─────── ACTIVE JOB ────────────│
│  ┌────────────────────────────┐ │
│  │  Rahul's Booking — ACTIVE  │ │
│  │  Status: On the Way 🏍️     │ │
│  │  [Update Status]           │ │
│  └────────────────────────────┘ │
└─────────────────────────────────┘
```

### Job Status Update Flow (Worker Side)

```
Incoming Request
    ↓
[ACCEPT]
    ↓
Status: ACCEPTED
    ↓
[I'm on my way →]
    ↓
Status: WORKER_ON_THE_WAY
    ↓
[I've Arrived ✅]
    ↓
Status: ARRIVED
    ↓
[Start Work 🔧]
    ↓
Status: SERVICE_STARTED
    ↓
[Work Complete ✅]
    ↓
Status: SERVICE_COMPLETED
    ↓
Customer confirms → Payment → Rating
```

### Create Post Screen (in KamJodo Cap)

```
[ + Create New Post ]

Title:       [ Professional Home Plumbing ]
Category:    [ Plumber ▼ ]
Description: [ Bathroom, kitchen pipe repair... ]
Starting ₹:  [ 300 ]
Service Area:[ 10 km ]
Photos:      [ + Add Photos ]

[Publish Post →]
```

### Posts Screen (Worker's Posts)

```
My Posts
─────────────────────────────
Active Posts  ●3
┌────────────────────────────┐
│  Professional Plumbing     │
│  Plumber | ₹300+ | 10 km  │
│  👁 42 views | 📅 3 bookings│
│  [Edit] [Pause] [Delete]   │
└────────────────────────────┘
```

### Earnings Screen

```
Earnings Dashboard
─────────────────────────
Today:     ₹ 1,450
This Week: ₹ 8,200
This Month:₹ 28,500

Completed Jobs: 312
Avg Rating: 4.8 ⭐
Followers: 1,248

─── Recent Transactions ───
✅ Plumbing — Saiful  ₹500
✅ Tap repair — Amit  ₹300
✅ Pipe fix — Priya   ₹650
```

### Worker Bottom Tabs Explained

| Tab | Screen | Purpose |
|---|---|---|
| 🏠 Dashboard | DashboardScreen | Online toggle, Incoming requests, Active job |
| 📝 Posts | PostsScreen | Create & manage service posts |
| 💬 Messages | MessagesScreen | Chat with customers |
| 📊 Earnings | EarningsScreen | Earnings, job history, analytics |
| 👤 Profile | WorkerProfileScreen | Profile, skills, reviews, verification status |

---

## 5. Shared Backend

### Architecture Overview

```
┌──────────────────┐     ┌──────────────────┐
│  KamJodo App     │     │  KamJodo Cap App  │
│  (Customer)      │     │  (Worker)         │
│  Flutter         │     │  Flutter          │
└────────┬─────────┘     └────────┬──────────┘
         │                        │
         └──────────┬─────────────┘
                    ↓
           HTTPS REST API + Socket.IO
                    ↓
         ┌──────────────────────┐
         │   Node.js + Express  │
         │   Backend Server     │
         └──────────┬───────────┘
                    │
           ┌────────┴─────────┐
           ↓                   ↓
      MongoDB Atlas         Firebase FCM
     (Persistent DB)    (Push Notifications)
```

### Backend API Endpoints (Shared)

| Method | Endpoint | Who Uses It |
|---|---|---|
| POST | `/api/v1/auth/quick-login` | Both apps |
| GET | `/api/v1/auth/me` | Both apps |
| GET | `/api/v1/workers/search` | KamJodo (Customer) |
| GET | `/api/v1/workers/:id` | KamJodo (Customer) |
| POST | `/api/v1/workers/availability` | KamJodo Cap (Worker) |
| GET | `/api/v1/posts` | KamJodo (Customer sees posts) |
| POST | `/api/v1/posts` | KamJodo Cap (Worker creates post) |
| POST | `/api/v1/bookings` | KamJodo (Customer creates) |
| PATCH | `/api/v1/bookings/:id/accept` | KamJodo Cap (Worker accepts) |
| PATCH | `/api/v1/bookings/:id/status` | KamJodo Cap (Worker updates) |
| GET | `/api/v1/bookings/my` | Both apps |
| POST | `/api/v1/reviews` | KamJodo (Customer reviews) |
| GET | `/api/v1/categories` | Both apps |

### Same JWT Auth, Different Roles

```
User Login with role = 'customer' → KamJodo App
User Login with role = 'worker'   → KamJodo Cap App

Same /api/v1/auth/quick-login endpoint
Same JWT token format
Backend checks req.user.role for access control
```

---

## 6. How Posts Flow Between Apps

This is the core **Rapido-style** data flow:

```
┌────────────────────────────┐
│  KamJodo Cap (Worker App)  │
│                            │
│  Worker creates a post:    │
│  "Professional Plumbing"   │
│  ₹300+ | 10km | Plumber    │
│                            │
│  [Publish →]               │
└────────────┬───────────────┘
             │ POST /api/v1/posts
             ↓
┌────────────────────────────┐
│       Backend              │
│                            │
│  workerPosts collection    │
│  status: 'active'          │
│  workerId: xyz             │
│  category: 'plumber'       │
└────────────┬───────────────┘
             │ GET /api/v1/posts?category=plumber&lat=..&lng=..
             ↓
┌────────────────────────────┐
│  KamJodo (Customer App)    │
│                            │
│  Home Screen / Feed:       │
│                            │
│  "Professional Plumbing"   │
│  Rahul Kumar | ⭐ 4.8       │
│  2.3 km away | ₹300+       │
│  [View Profile] [Book Now] │
└────────────────────────────┘
```

**Key Rule:**
- Worker creates post in **KamJodo Cap**
- Customer sees post in **KamJodo**
- Same backend, same MongoDB collection (`workerPosts`)

---

## 7. Booking Lifecycle (End-to-End)

```
CUSTOMER (KamJodo)              BACKEND              WORKER (KamJodo Cap)
─────────────────────────────────────────────────────────────────────────

[Book Now] taps                    →
                            Booking created
                            status: REQUESTED         ← 🔔 Notification
                                                      Worker sees request
                                                      [ACCEPT] / [REJECT]
                                                      Worker taps ACCEPT  →
                            status: ACCEPTED
"Worker Accepted!" shown   ←
[Track Worker]

                                                      [I'm on my way] →
                            status: WORKER_ON_THE_WAY
"Rahul is coming! 🏍️"     ←

                                                      [I've Arrived] →
                            status: ARRIVED
"Worker has arrived ✅"    ←

                                                      [Start Work] →
                            status: SERVICE_STARTED
"Service in progress 🔧"  ←

                                                      [Work Complete] →
                            status: SERVICE_COMPLETED
"Service done! Pay ₹450" ←
[Pay Now]
                            status: PAID
[Rate Worker ⭐⭐⭐⭐⭐]     ←
                            status: RATED             ← "New Review! ⭐4.8"
```

### Booking Status Machine

```
REQUESTED
    ↓ (Worker Accepts)
ACCEPTED
    ↓ (Worker taps "On My Way")
WORKER_ON_THE_WAY
    ↓ (Worker taps "Arrived")
ARRIVED
    ↓ (Worker taps "Start Work")
SERVICE_STARTED
    ↓ (Worker taps "Complete")
SERVICE_COMPLETED
    ↓ (Customer pays)
PAID
    ↓ (Customer rates)
RATED

Alternate States:
REJECTED              (Worker rejected)
CANCELLED_BY_CUSTOMER (Customer cancelled)
CANCELLED_BY_WORKER   (Worker cancelled)
EXPIRED               (No response in time)
DISPUTED              (Reported by either side)
```

---

## 8. Data Models

### User (Shared)

```js
{
  _id: ObjectId,
  name: String,
  phone: String,
  email: String (optional),
  role: 'customer' | 'worker',
  profilePhoto: String (URL),
  fcmToken: String,          // For push notifications
  status: 'active' | 'suspended',
  createdAt: Date
}
```

### WorkerProfile

```js
{
  _id: ObjectId,
  userId: ObjectId,
  category: String,           // 'plumber', 'electrician', etc.
  skills: [String],
  experienceYears: Number,
  bio: String,
  serviceAreaKm: Number,
  availabilityDays: [String], // ['Mon','Tue',...]
  workingHours: { start: '09:00', end: '20:00' },
  isOnline: Boolean,
  location: {                 // GeoJSON
    type: 'Point',
    coordinates: [lng, lat]
  },
  rating: Number,
  totalReviews: Number,
  completedJobs: Number,
  verificationStatus: 'pending' | 'verified' | 'rejected',
  followersCount: Number,
  startingPrice: Number
}
```

### WorkerPost

```js
{
  _id: ObjectId,
  workerId: ObjectId,
  title: String,
  description: String,
  category: String,
  photos: [String],
  startingPrice: Number,
  serviceAreaKm: Number,
  status: 'active' | 'paused' | 'expired' | 'deleted',
  viewCount: Number,
  bookingCount: Number,
  location: { type: 'Point', coordinates: [lng, lat] },
  createdAt: Date
}
```

### Booking

```js
{
  _id: ObjectId,
  customerId: ObjectId,
  workerId: ObjectId,
  postId: ObjectId (optional),
  serviceDescription: String,
  scheduledAt: Date,
  address: String,
  location: { type: 'Point', coordinates: [lng, lat] },
  budgetEstimate: Number,
  finalAmount: Number,
  status: 'requested' | 'accepted' | 'worker_on_the_way' | 'arrived' |
          'service_started' | 'service_completed' | 'paid' | 'rated' |
          'rejected' | 'cancelled_by_customer' | 'cancelled_by_worker' |
          'expired' | 'disputed',
  notes: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Review

```js
{
  _id: ObjectId,
  bookingId: ObjectId,   // Must reference a completed booking
  customerId: ObjectId,
  workerId: ObjectId,
  rating: Number,        // 1–5
  comment: String,
  createdAt: Date
}
```

---

## 9. Realtime Architecture

### Socket.IO Events

| Event | Direction | Description |
|---|---|---|
| `booking:new_request` | Server → Worker | New job request |
| `booking:accepted` | Server → Customer | Worker accepted |
| `booking:status_update` | Server → Customer | Status changed |
| `booking:rejected` | Server → Customer | Worker rejected |
| `worker:location_update` | Worker → Server → Customer | Live location |
| `chat:message` | Both ↔ Server | New chat message |
| `chat:typing` | Both ↔ Server | Typing indicator |
| `worker:online` | Worker → Server | Went online |
| `worker:offline` | Worker → Server | Went offline |

### FCM Push Notifications

| Trigger | Recipient | Message |
|---|---|---|
| Booking created | Worker | "New job request! ₹300 — Plumbing" |
| Booking accepted | Customer | "Rahul accepted your booking" |
| Worker on the way | Customer | "Rahul is on his way!" |
| Worker arrived | Customer | "Rahul has arrived" |
| Service complete | Customer | "Service done. Pay ₹450" |
| Payment received | Worker | "₹450 received for Plumbing" |
| New review | Worker | "You got a 5⭐ review!" |
| Booking cancelled | Both | "Booking cancelled" |

---

## 10. MVP Build Phases

### Phase 1 — Foundation (DONE ✅)
- JWT authentication
- User model (customer + worker roles)
- WorkerProfile model
- Categories API
- Quick login (Name + Password)
- Basic Flutter screens (Role selection, Login, Home, Profile)

### Phase 2 — Worker Discovery (DONE ✅)
- Worker search API (by category, location, skills)
- WorkerPost model + CRUD API
- Customer screens: WorkerCard, WorkerList, WorkerProfile, Search
- Follow/Unfollow API

### Phase 3 — Booking System (DONE ✅)
- Booking model with state machine
- Booking CRUD API
- Worker Dashboard (Online/Offline, Accept/Reject, Status updates)
- Customer Booking History screen

### Phase 4 — TWO APPS (CURRENT 🔄)
> This is the new phase added per user request.

**Goals:**
1. Create `frontend_cap/` — a new Flutter project for **KamJodo Cap** (Worker App)
2. Move all worker screens into **KamJodo Cap**
3. Clean `frontend/` (KamJodo) to only have customer screens
4. Both apps point to the same backend

**Tasks:**
- [ ] Create `d:\KamJodo\frontend_cap\` Flutter project (`com.kamjodo.cap`)
- [ ] Copy shared services (`auth_service.dart`, `booking_service.dart`, etc.)
- [ ] Move worker screens to `frontend_cap/`
- [ ] Worker login → role = 'worker'
- [ ] Customer login → role = 'customer'
- [ ] Update `README.md` with new structure
- [ ] Update `KAMJODO_APP_WORKFLOW.md`

### Phase 5 — Realtime (Next)
- Socket.IO integration (booking notifications)
- Live status updates without polling
- Worker live location tracking during active booking
- Real-time chat (Customer ↔ Worker)

### Phase 6 — Reputation
- Review system (post-booking only)
- Worker ranking algorithm
- Trust badges (Verified, Top Rated, New)
- Worker analytics in KamJodo Cap

### Phase 7 — Payments
- Razorpay / Stripe integration
- Booking payment flow
- Worker earnings dashboard with withdrawals

### Phase 8 — Production Ready
- FCM push notifications
- Admin Web dashboard
- MongoDB Atlas production setup
- Docker + Nginx deployment
- App Store / Play Store release

---

## 11. Folder Structure

```
d:\KamJodo\
│
├── backend\                    ← Shared Node.js + Express API
│   ├── src\
│   │   ├── controllers\
│   │   │   ├── auth.controller.js
│   │   │   ├── worker.controller.js
│   │   │   ├── booking.controller.js
│   │   │   ├── post.controller.js
│   │   │   └── review.controller.js
│   │   ├── models\
│   │   │   ├── User.js
│   │   │   ├── WorkerProfile.js
│   │   │   ├── WorkerPost.js
│   │   │   ├── Booking.js
│   │   │   └── Review.js
│   │   ├── routes\v1\
│   │   └── middleware\
│   └── server.js
│
├── frontend\                   ← KamJodo (Customer App)
│   ├── lib\
│   │   ├── main.dart
│   │   ├── screens\
│   │   │   ├── home_screen.dart
│   │   │   ├── search_screen.dart
│   │   │   ├── feed_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── auth\login_screen.dart
│   │   │   └── customer\
│   │   │       ├── worker_card.dart
│   │   │       ├── worker_profile_screen.dart
│   │   │       ├── booking_screen.dart
│   │   │       └── booking_history_screen.dart
│   │   └── services\
│   │       ├── auth_service.dart
│   │       └── booking_service.dart
│   └── pubspec.yaml            (name: kamjodo, com.kamjodo.app)
│
├── frontend_cap\               ← KamJodo Cap (Worker App) [NEW]
│   ├── lib\
│   │   ├── main.dart
│   │   ├── screens\
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── posts_screen.dart
│   │   │   ├── earnings_screen.dart
│   │   │   ├── messages_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── auth\login_screen.dart
│   │   │   └── worker\
│   │   │       ├── worker_dashboard_screen.dart
│   │   │       ├── worker_onboarding_screen.dart
│   │   │       └── create_post_screen.dart
│   │   └── services\
│   │       ├── auth_service.dart
│   │       └── worker_service.dart
│   └── pubspec.yaml            (name: kamjodo_cap, com.kamjodo.cap)
│
├── admin-web\                  ← Admin Panel (Web)
│
└── agent\
    ├── KAMJODO_APP_WORKFLOW.md ← This file (Updated)
    └── KAMJODO_API_DOCUMENTATION.md
```

---

## 12. Screen-by-Screen Spec

### KamJodo (Customer App) — All Screens

| Screen | File | Description |
|---|---|---|
| Splash | `splash_screen.dart` | Logo animation, check auth |
| Login | `auth/login_screen.dart` | Name + Password → role=customer |
| Home | `home_screen.dart` | Categories, nearby workers, posts |
| Feed | `feed_screen.dart` | Posts from followed workers |
| Search | `search_screen.dart` | Filter by category, location, rating |
| Worker List | `customer/worker_list_screen.dart` | Category results |
| Worker Profile | `customer/worker_profile_screen.dart` | About, Posts, Reviews |
| Booking | `customer/booking_screen.dart` | Booking form + submission |
| Booking History | `customer/booking_history_screen.dart` | All bookings with status |
| Messages | `messages_screen.dart` | Chat threads list |
| Chat | `chat_screen.dart` | 1:1 chat with worker |
| Profile | `profile_screen.dart` | Account settings, logout |

### KamJodo Cap (Worker App) — All Screens

| Screen | File | Description |
|---|---|---|
| Splash | `splash_screen.dart` | Logo animation, check auth |
| Login | `auth/login_screen.dart` | Name + Password → role=worker |
| Onboarding | `worker/worker_onboarding_screen.dart` | Profile setup (first time) |
| Dashboard | `worker/worker_dashboard_screen.dart` | Online/Offline, requests, active job |
| Posts | `worker/posts_screen.dart` | Manage service posts |
| Create Post | `worker/create_post_screen.dart` | Create new service post |
| Earnings | `worker/earnings_screen.dart` | Earnings, job history |
| Messages | `messages_screen.dart` | Chat threads list |
| Chat | `chat_screen.dart` | 1:1 chat with customer |
| Profile | `worker/worker_profile_screen.dart` | Worker profile, skills, reviews |

---

## Golden Rules

### For KamJodo (Customer)
```
OPEN APP → SEARCH → SEE WORKERS → BOOK → TRACK → PAY → RATE
```
Keep it as simple as **ordering food on Swiggy** — minimal friction.

### For KamJodo Cap (Worker)
```
SETUP PROFILE → CREATE POST → GO ONLINE → ACCEPT JOB → GO → COMPLETE → EARN
```
Make it feel like **Rapido Captain** — one big toggle to go online, then notifications take over.

### For the Backend (Shared)
```
ONE backend. ONE database. Role-based access control.
Worker posts → Customer sees. Customer books → Worker notified.
```

---

*This document is the updated engineering source of truth for the KamJodo platform (Two-App Model).*
*Previous version (v1.0) is archived in git history.*