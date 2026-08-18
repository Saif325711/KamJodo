KamJodo — API Documentation & Backend Contract

Version: 1.0
Status: Proposed API contract / implementation reference
Backend target: Node.js + Express.js + MongoDB/Mongoose + Socket.IO + FCM
Deployment target: DigitalOcean + Docker + Nginx + HTTPS

1. API Conventions

Base production URL:

https://api.kamjodo.com

Do not hardcode this URL in application source until the domain is actually configured.

Recommended local development URL:

http://localhost:5000

API prefix:

/api/v1

Example:

https://api.kamjodo.com/api/v1

All production API communication must use HTTPS.

2. Authentication

Recommended authentication:

Phone Number
    ↓
OTP
    ↓
JWT access token

Header:

Authorization: Bearer <ACCESS_TOKEN>

Do not expose:

passwords

OTP values

JWT secrets

MongoDB credentials

PAN numbers

government ID numbers

in logs or API responses.

3. Standard Response Format

Success:

{
  "success": true,
  "message": "Request successful",
  "data": {}
}

Error:

{
  "success": false,
  "message": "Readable error message",
  "code": "ERROR_CODE"
}

Validation error:

{
  "success": false,
  "message": "Validation failed",
  "code": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "phone",
      "message": "Invalid phone number"
    }
  ]
}

4. Roles

Supported roles:

customer
worker
admin

Authorization must be enforced on protected endpoints.

5. Authentication API

Send OTP

POST /api/v1/auth/send-otp

Request:

{
  "phone": "+91XXXXXXXXXX"
}

Response:

{
  "success": true,
  "message": "OTP sent"
}

Verify OTP

POST /api/v1/auth/verify-otp

Request:

{
  "phone": "+91XXXXXXXXXX",
  "otp": "123456"
}

Response:

{
  "success": true,
  "data": {
    "accessToken": "JWT_TOKEN",
    "user": {
      "id": "USER_ID",
      "role": "customer",
      "profileComplete": false
    }
  }
}

Get Current User

GET /api/v1/auth/me

Auth required.

Logout

POST /api/v1/auth/logout

Auth required.

If JWT is stateless, client-side token removal may be enough; if refresh-token/session revocation exists, revoke it server-side.

6. Customer Profile API

Get Profile

GET /api/v1/customers/me

Update Profile

PATCH /api/v1/customers/me

Example:

{
  "name": "Saiful",
  "profilePhoto": "FILE_URL"
}

Do not accept protected fields such as:

role
isAdmin
verificationStatus

from the client.

Customer Addresses

GET    /api/v1/customers/me/addresses
POST   /api/v1/customers/me/addresses
PATCH  /api/v1/customers/me/addresses/:addressId
DELETE /api/v1/customers/me/addresses/:addressId

Example:

{
  "label": "Home",
  "addressLine": "Example address",
  "city": "Example City",
  "state": "Example State",
  "postalCode": "000000",
  "location": {
    "type": "Point",
    "coordinates": [88.3639, 22.5726]
  }
}

Use GeoJSON for location.

7. Worker Onboarding API

Create/Update Worker Profile

POST /api/v1/workers/onboarding

or use:

PATCH /api/v1/workers/me

Fields may include:

{
  "fullName": "Rahul Kumar",
  "profilePhoto": "FILE_URL",
  "primaryCategoryId": "CATEGORY_ID",
  "experienceYears": 7,
  "skills": [
    "Pipe Repair",
    "Tap Installation"
  ],
  "serviceRadiusKm": 10,
  "startingPrice": 300
}

Sensitive identity fields must not be returned unnecessarily.

8. Worker Verification

Submit Verification

POST /api/v1/workers/me/verification

Possible request:

{
  "identityDocumentType": "government_id",
  "identityDocumentFile": "FILE_REFERENCE",
  "panVerificationRequested": true
}

Do not expose raw PAN number in worker profile.

Verification Status

GET /api/v1/workers/me/verification

Response:

{
  "success": true,
  "data": {
    "identityStatus": "verified",
    "panStatus": "verified",
    "overallStatus": "verified"
  }
}

Possible states:

pending
verified
rejected
expired

9. Categories

Get Categories

GET /api/v1/categories

Example:

{
  "success": true,
  "data": [
    {
      "id": "CAT_DRIVER",
      "name": "Driver",
      "icon": "..."
    },
    {
      "id": "CAT_PLUMBER",
      "name": "Plumber",
      "icon": "..."
    }
  ]
}

Get Category

GET /api/v1/categories/:categoryId

10. Worker Discovery

Search Workers

GET /api/v1/workers

Recommended query parameters:

categoryId
latitude
longitude
radiusKm
minRating
availableNow
verifiedOnly
search
page
limit
sort

Example:

GET /api/v1/workers?categoryId=CAT_PLUMBER&latitude=22.5726&longitude=88.3639&radiusKm=10&availableNow=true

Response:

{
  "success": true,
  "data": {
    "workers": [],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100
    }
  }
}

11. Worker Profile

Public Worker Profile

GET /api/v1/workers/:workerId

Public response may contain:

name

profile photo

category

skills

experience

rating

reviews count

completed jobs

service area

starting price

verification badges

active posts

followers count

Do NOT return:

PAN

government ID

private address

private phone number

private documents

private location history

12. Worker Availability

Set Online/Offline

PATCH /api/v1/workers/me/availability

Request:

{
  "isOnline": true,
  "isAvailable": true
}

Get Availability

GET /api/v1/workers/:workerId/availability

13. Worker Service Posts

Workers can advertise their services.

Create Post

POST /api/v1/worker-posts

Request:

{
  "title": "Professional Home Plumbing Service",
  "categoryId": "CAT_PLUMBER",
  "description": "Bathroom, kitchen and pipe repair.",
  "startingPrice": 300,
  "serviceRadiusKm": 10,
  "images": [
    "FILE_URL"
  ]
}

Get My Posts

GET /api/v1/worker-posts/me

Get Worker Posts

GET /api/v1/workers/:workerId/posts

Get Post

GET /api/v1/worker-posts/:postId

Update Post

PATCH /api/v1/worker-posts/:postId

Delete/Deactivate Post

DELETE /api/v1/worker-posts/:postId

or preferably:

PATCH /api/v1/worker-posts/:postId/status

with:

{
  "status": "paused"
}

14. Follow Worker

Follow

POST /api/v1/workers/:workerId/follow

Unfollow

DELETE /api/v1/workers/:workerId/follow

Follow Status

GET /api/v1/workers/:workerId/follow-status

My Following

GET /api/v1/me/following

15. Booking API

Create Booking

Customer only.

POST /api/v1/bookings

Request:

{
  "workerId": "WORKER_ID",
  "serviceId": "SERVICE_ID",
  "scheduledAt": "2026-08-15T17:00:00+05:30",
  "addressId": "ADDRESS_ID",
  "description": "Bathroom tap repair",
  "customerLocation": {
    "type": "Point",
    "coordinates": [88.3639, 22.5726]
  },
  "notes": "Please call before arrival"
}

Response:

{
  "success": true,
  "data": {
    "bookingId": "BOOKING_ID",
    "status": "requested"
  }
}

16. Booking Status Machine

Allowed state transitions:

REQUESTED
    ↓
ACCEPTED
    ↓
WORKER_ON_THE_WAY
    ↓
ARRIVED
    ↓
SERVICE_STARTED
    ↓
SERVICE_COMPLETED
    ↓
PAYMENT_PENDING
    ↓
PAID
    ↓
RATED

Alternative:

REQUESTED → REJECTED
REQUESTED → CANCELLED_BY_CUSTOMER
ACCEPTED → CANCELLED_BY_CUSTOMER
ACCEPTED → CANCELLED_BY_WORKER

Backend must reject illegal transitions.

17. Worker Booking Requests

Get Pending Requests

GET /api/v1/workers/me/bookings?status=requested

Accept Booking

POST /api/v1/bookings/:bookingId/accept

Worker only.

The backend must perform an atomic/conditional update so that only one worker can claim a booking.

Reject Booking

POST /api/v1/bookings/:bookingId/reject

Request:

{
  "reason": "Not available at requested time"
}

18. Booking Details

GET /api/v1/bookings/:bookingId

Authorization must verify that the requester is:

booking customer

assigned worker

authorized admin

19. Booking Status Update

PATCH /api/v1/bookings/:bookingId/status

Request:

{
  "status": "arrived"
}

The backend must validate the current status and the user's role.

Do not trust the client to perform arbitrary state changes.

20. Customer Booking History

GET /api/v1/bookings/me?role=customer

Recommended filters:

status
from
to
page
limit

21. Worker Job History

GET /api/v1/bookings/me?role=worker

or a dedicated endpoint:

GET /api/v1/workers/me/jobs

22. Cancel Booking

POST /api/v1/bookings/:bookingId/cancel

Request:

{
  "reason": "Changed my plan"
}

The backend should calculate whether cancellation is allowed.

23. Live Location

Worker sends location only when appropriate.

Update Worker Location

POST /api/v1/bookings/:bookingId/location

Request:

{
  "latitude": 22.5726,
  "longitude": 88.3639,
  "accuracy": 10
}

Only the assigned worker can update their active booking location.

Do not expose unrestricted location history.

24. Socket.IO Events

Recommended namespace:

/socket.io

Authenticate the socket connection using a valid access token.

Booking Room

Example room:

booking:BOOKING_ID

Participants:

customer

assigned worker

authorized admin if required

Booking Events

Client/server events:

booking:created
booking:accepted
booking:rejected
booking:cancelled
booking:status_changed
booking:worker_arrived
booking:service_started
booking:service_completed

Live Location Event

Worker:

worker:location_update

Payload:

{
  "bookingId": "BOOKING_ID",
  "latitude": 22.5726,
  "longitude": 88.3639
}

Customer receives:

worker:location_updated

Only authorized booking participants receive the event.

25. Chat API

Get Conversations

GET /api/v1/conversations

Get Messages

GET /api/v1/conversations/:conversationId/messages

Use pagination.

Create/Open Conversation

POST /api/v1/conversations

Request:

{
  "workerId": "WORKER_ID",
  "bookingId": "BOOKING_ID"
}

26. Socket.IO Chat Events

message:send
message:new
message:read
typing:start
typing:stop

Example:

{
  "conversationId": "CONVERSATION_ID",
  "message": "I will reach in 10 minutes."
}

27. Reviews & Ratings

Create Review

Only after an eligible completed booking.

POST /api/v1/bookings/:bookingId/review

Request:

{
  "rating": 5,
  "comment": "Very professional and on time."
}

The backend must verify:

User participated in booking.

Booking is completed.

Review does not already exist.

User is allowed to review the target.

Get Worker Reviews

GET /api/v1/workers/:workerId/reviews

28. Worker Reputation

Worker profile can expose:

{
  "rating": 4.8,
  "reviewCount": 126,
  "completedJobs": 312,
  "followersCount": 1248
}

The rating should be calculated server-side.

Do not allow clients to submit:

ratingAverage
completedJobs
followersCount

as trusted values.

29. Notifications

Get Notifications

GET /api/v1/notifications

Mark Notification Read

PATCH /api/v1/notifications/:notificationId/read

30. FCM Device Token

Register Device

POST /api/v1/devices

Request:

{
  "token": "FCM_DEVICE_TOKEN",
  "platform": "android"
}

The backend can use this token to send push notifications.

31. Payment API

Payment implementation depends on the selected gateway.

Conceptual endpoints:

POST /api/v1/payments/create
GET  /api/v1/payments/:paymentId
POST /api/v1/payments/:paymentId/verify

Never trust the client to declare:

paymentStatus = paid

Payment status must be verified through the payment provider/webhook.

32. Worker Earnings

GET /api/v1/workers/me/earnings

Possible filters:

today
week
month
custom

Response may contain:

{
  "total": 45000,
  "completedJobs": 72,
  "pending": 1200
}

Actual settlement rules depend on payment architecture.

33. Reports

Report Worker

POST /api/v1/reports

Example:

{
  "targetType": "worker",
  "targetId": "WORKER_ID",
  "bookingId": "BOOKING_ID",
  "reason": "service_issue",
  "description": "..."
}

Report Customer

Same endpoint with:

targetType = customer

34. Admin API

Admin authentication required.

Examples:

GET    /api/v1/admin/users
GET    /api/v1/admin/workers
GET    /api/v1/admin/bookings
GET    /api/v1/admin/reports
GET    /api/v1/admin/verifications
PATCH  /api/v1/admin/workers/:workerId/verification
PATCH  /api/v1/admin/users/:userId/status
PATCH  /api/v1/admin/worker-posts/:postId/moderation

Only admin roles can access these endpoints.

35. Health Check

GET /api/health

Response:

{
  "success": true,
  "message": "KamJodo API is running"
}

This endpoint should not expose database credentials or internal secrets.

36. MongoDB Data Model — Conceptual

users

_id
role
phone
email
name
profilePhoto
status
createdAt
updatedAt

workerProfiles

_id
userId
primaryCategoryId
categoryIds
experienceYears
skills
startingPrice
serviceRadiusKm
location
isOnline
isAvailable
ratingAverage
ratingCount
completedJobs
followersCount
verificationStatus
createdAt
updatedAt

Use GeoJSON:

{
  "type": "Point",
  "coordinates": [longitude, latitude]
}

Create a 2dsphere index for nearby-worker queries.

workerPosts

_id
workerId
categoryId
title
description
images
startingPrice
serviceRadiusKm
status
createdAt
updatedAt

bookings

_id
customerId
workerId
serviceId
status
scheduledAt
customerAddress
customerLocation
workerLocation
price
finalPrice
notes
createdAt
acceptedAt
arrivedAt
startedAt
completedAt
cancelledAt

follows

_id
customerId
workerId
createdAt

Create a unique index:

customerId + workerId

to prevent duplicate follows.

reviews

_id
bookingId
customerId
workerId
rating
comment
createdAt

Create a unique constraint for the review-per-booking rule.

conversations

_id
customerId
workerId
bookingId
lastMessageAt
createdAt

messages

_id
conversationId
senderId
receiverId
message
messageType
readAt
createdAt

notifications

_id
userId
type
title
body
data
readAt
createdAt

37. Important Security Rules

Never trust role information sent by the client.

Never trust worker/customer IDs from the client without authorization checks.

Never expose PAN or government ID numbers.

Never allow a customer to update worker verification.

Never allow a worker to update another worker's profile.

Never allow arbitrary booking status changes.

Never allow arbitrary location access.

Never allow a user to review a booking they did not participate in.

Never allow duplicate reviews.

Never allow duplicate follows.

Use input validation.

Rate-limit OTP endpoints.

Protect authentication endpoints.

Use HTTPS in production.

Keep MongoDB credentials only in environment variables.

Do not expose MongoDB publicly.

Validate payment using provider-side verification/webhooks.

Log security events without logging secrets.

38. API Error Codes

Recommended examples:

AUTH_REQUIRED
INVALID_TOKEN
OTP_INVALID
OTP_EXPIRED
USER_NOT_FOUND
WORKER_NOT_FOUND
PROFILE_INCOMPLETE
VERIFICATION_REQUIRED
BOOKING_NOT_FOUND
BOOKING_NOT_AVAILABLE
INVALID_BOOKING_STATUS
UNAUTHORIZED_BOOKING_ACCESS
WORKER_NOT_AVAILABLE
ALREADY_FOLLOWING
NOT_FOLLOWING
REVIEW_NOT_ALLOWED
REVIEW_ALREADY_EXISTS
VALIDATION_ERROR
RATE_LIMITED
PAYMENT_FAILED
INTERNAL_ERROR

39. API Development Priority

Implement in this order:

1. Authentication
2. User profile
3. Worker onboarding
4. Categories
5. Worker verification
6. Worker discovery
7. Worker posts
8. Follow
9. Booking
10. Booking state machine
11. Socket.IO
12. Live location
13. Chat
14. Notifications / FCM
15. Reviews
16. Earnings
17. Payments
18. Reports
19. Admin APIs

40. Final API Architecture

Customer Flutter App
        │
        ├── REST API ─────────────┐
        │                         │
        ├── Socket.IO ───────────┤
        │                         ↓
        │                 Node.js / Express
        │                         │
Worker Flutter App               │
        │                         │
        ├── REST API ─────────────┤
        │                         │
        ├── Socket.IO ───────────┤
        │                         │
        │                         ↓
        │                    Mongoose
        │                         │
        │                         ↓
        │                   MongoDB Atlas
        │
        └── FCM Push Notifications

Admin Web
   │
   └──── REST API ─────→ Node.js / Express

41. Important Implementation Rule

This document is an API contract/reference, not permission to invent endpoints blindly.

When implementing the real backend:

Inspect existing KamJodo APIs.

Reuse existing endpoints where possible.

Preserve existing working routes.

Add missing endpoints following this naming convention.

Update Flutter and admin-web clients together.

Test authorization for every protected endpoint.

Test booking race conditions.

Test location privacy.

Test review ownership.

Test worker/customer role permissions.

The API implementation must remain consistent with the actual database models and application workflow.