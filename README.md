# reworth

A new Flutter project.

## Realtime Waste Buyers

The logistics screen now reads buyers from Firestore in realtime from the `companies` collection.

If the app shows `PERMISSION_DENIED` for the `companies` listener, publish the rules from [firestore.rules](c:/Users/tkulk/Desktop/T%20Pro/reworth/firestore.rules) in Firebase Console or with Firebase CLI.

Create a Firestore collection named `companies` and store documents like this:

```json
{
	"name": "Green Scrap Traders",
	"category": "Scrap buyer",
	"wasteTypes": ["metal", "plastic", "paper"],
	"phone": "+91 9876543210",
	"website": "https://greenscrap.example",
	"address": "12 Market Road",
	"city": "Bengaluru",
	"location": {
		"latitude": 12.9716,
		"longitude": 77.5946
	},
	"isActive": true,
	"isVerified": true,
	"ownerUid": "firebase-auth-user-id"
}
```

`location` can also be stored as a Firestore `GeoPoint`.

Minimal rules for this app:

```txt
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		match /companies/{companyId} {
			allow read: if request.auth != null;
			allow create, update, delete: if request.auth != null;
		}

		match /user/{userDocId} {
			allow read, write: if request.auth != null;
		}
	}
}
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
