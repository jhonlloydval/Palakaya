# Palakaya: Complete App Guide

*Catch. Connect. Get a Fair Price.*

This guide explains what Palakaya does, how each screen works, what changed for the finals build, and how the app was built step by step. Use it to present and defend the project.

---

## 1. The app in one minute

Palakaya is an iPhone app for small-scale Filipino municipal fishers. A fisher logs each catch at the landing site, sees the fair price for that fish, and sells directly to verified buyers (market stalls, carinderias, cooperatives) instead of accepting whatever the first trader names.

There are two kinds of accounts:

| Account | What they do |
|---|---|
| **Fisher** | Logs catches, checks fair prices and the sea forecast, lists catches, accepts buyer offers, records sales, asks the Advisor, sees monthly reports |
| **Buyer** | Browses fresh catch, makes offers, pays accepted offers in a demo checkout, keeps receipts, gets verified |

Behind the scenes, every sale feeds an anonymous, province-level picture of catch volume and prices that BFAR and local fisheries offices could use.

---

## 2. The main workflow (fisher)

```
Onboarding → Create account → Welcome tour → Home
   │
   ├─ Check "Sea today" (go / careful / stay ashore)
   ├─ Log Catch: pick fish → kilos, ground, time, photo → review → Save (or Save & List)
   │        └─ Catch Details: edit, delete, or List for Sale
   ├─ Create Listing: set price (fair price pre-filled) → Publish
   │        └─ Buyers see it in Market (with the photo) and send offers
   ├─ Buyer Matches: compare offers, call or text, Accept or Decline
   │        └─ Record Sale → Sale Recorded (fair-sale score, e.g. 99%)
   ├─ Fair Prices: any fish, any province, with the source and confidence
   ├─ Advisor: ask in English or Filipino
   ├─ Notifications: tap to open the related screen
   └─ Profile: details, landing site, reports, sync status, privacy, help, about, demo tools, appearance
```

## 3. The buyer workflow

```
Create account (Buyer) → Market ("Buy") → open a listing → Make an Offer
   → My Offers: Waiting → Accepted → Pay (GCash / Maya / LandBank demo) → Receipt
   → Profile → Buyer Verification (how to earn the Verified badge)
```

---

## 4. Every feature, screen by screen

### Onboarding (5 steps)
Full-screen photos of Filipino fishers fade into the app's night-sea navy, with the message on the faded part.
1. **Know what your catch is worth**: the core idea, shown plain.
2. **Check the sea before you go**: the daily sea forecast.
3. **Sell straight to buyers near you**: the marketplace.
4. **Ask in English or Filipino**: the Advisor.
5. **Catch smarter, sell fairer**: records, local prices, and offline use.

Each step has one see-through "glass" strip with a real example from the app. **Skip** jumps to the end. The animation turns off when the phone's Reduce Motion setting is on.

### Create account and log in
- Choose **Fisher** or **Buyer**. Buyers also enter their store or cooperative name.
- The mobile number is the login. It is checked as an 11-digit 09XX number, and spaces don't matter.
- **Password rules**, shown live with checkmarks: at least 8 characters, with an uppercase letter, a lowercase letter and a number (for example `Kahitano1Jl`). Weak passwords are rejected.
- Placeholders use Lucena City, Quezon, CALABARZON and Dalahican Landing Site.
- **Forgot Password?** explains how to recover the account.
- Logging in on a new phone restores the account and its catches from the cloud.

### Welcome tour
Shown once after sign-up, and skippable. Five quick tips for fishers (or four for buyers) on where everything is.

### Home
- Greets by time of day and first name. Honorifics like "Mang" and "Aling" are skipped.
- **Today's Catch**: kilos and estimated value for today only, compared with the fisher's own average.
- **Sea today**: compact by default; tap to open the full forecast.
  - Temperature, sky, waves, wind and chance of rain for the fisher's town.
  - A plain **Good to go / Be careful / Stay ashore** guide for small boats (waves of 2 m or more, or wind of 39 km/h or more, means stay ashore).
  - The card's sky colour follows the conditions, and the animated waves grow with the real wave forecast.
  - A sunrise-to-sunset track shows where the sun is now.
  - The data comes from Open-Meteo (free, no key needed). The card always reminds users to follow PAGASA and the Coast Guard.
- **Fair Price Today**, quick actions, recent catches and Price Watch.
- The avatar opens Profile, and the bell opens Notifications.

### Log Catch (3 steps)
1. **Fish**: search the list or **type any fish name** that isn't listed (for example "Lapu-lapu").
2. **Details**: kilos (accepts 8.5 or 8,5), fishing ground (starts as the home landing site), date and time (no future times), and an **optional photo** taken with the camera or picked from the gallery. Photos are shrunk to about 200 KB.
3. **Review**: shows the estimated fair price and potential value, then **Save** or **Save & List for Sale**.

### My Catch and Catch Details
- This month's kilos, sales total and fishing days, with All / Available / Sold filters.
- Catch Details shows the photo, weight, time, ground and fair-price breakdown.
- **Edit Record**: change the fish, kilos, ground, time or photo, or **delete** the catch (it is also removed from the cloud on the next sync).

### Market
- **Your Listings**, with the number of offers waiting on each.
- **From Other Fishers**: real listings from the cloud, with search (fish, seller or place) and **sort** (Newest, Lowest price, Fair price first, Most kilos).
- Each listing shows a **Fair price** or **Below fair** badge, and **Fresh today** for catches landed today.
- Opening a listing shows its **photo**, the seller, the landing site, and buttons to Call, Text or **Make an Offer** (buyers).

### Buyer Matches → Record Sale → Sale Recorded
- All offers on a listing, side by side: price per kilo, whether it's within the fair range, the buyer's verified badge and paid-purchase count, and their message.
- **Call** or **Text** the buyer, then **Accept** or **Decline**.
- Record Sale confirms the price, kilos and total.
- **Sale Recorded** shows the **price alignment score**: how close the sale price was to the fair midpoint.

### Fair Prices
- Search any fish and **pick any province** (or all of the Philippines).
- The price comes from, in order:
  1. Sales in that province over the last 30 days (needs at least 5 sales),
  2. Otherwise, all Palakaya sales nationwide,
  3. Otherwise, a regional estimate, clearly labelled as one.
- The middle 50% of sale prices becomes the range, and the median becomes the middle price. The screen shows how many sales were counted, the confidence level, and when the data last updated. Pull down to refresh.

### Advisor (AI)
- Type a question or tap a suggestion, in **English or Filipino**.
- It answers using the person's own catch records and current fair prices.
- **Guardrails**: it only answers fishing, catch, price, selling and app questions. It politely refuses off-topic questions (politics, homework and so on), refuses help with illegal fishing (dynamite, cyanide, fine-mesh nets, protected species), points to PAGASA, the Coast Guard and BFAR for safety and legal matters, never asks for money, PINs or IDs, and ignores attempts to change its rules.
- It runs on a Supabase Edge Function using Google Gemini's free tier. Answers take about 30–60 seconds.
- When there is no signal, a built-in offline advisor answers common questions using the app's own data.

### Notifications
Built from the user's real activity: new offers, accepted or declined offers, payments, sales, listings, records waiting to upload, and fair-price updates. **Tapping one opens the related screen.**

### Profile
- **Appearance**: Auto, Light or Dark, switchable right on the Profile page.
- **Personal Information**: edit name and location, and **change password** (on the phone and in the cloud).
- **Fisherfolk Details**: FishR ID and why registering matters.
- **Landing Site**: edit the home port, and see totals for each fishing ground.
- **Reports**: monthly kilos, sales, price alignment, fishing days, top species, with **Share**.
- **Connectivity & Offline Data**: live sync status, records waiting to upload, and **Sync now**.
- **Privacy**: who sees what, what is stored, and the user's rights under the Data Privacy Act of 2012.
- **Help Center**: an expandable FAQ.
- **About Palakaya**: the problem, statistics, features, audience, how fair prices work, and the maker.
- **Demo Tools**: fill an account with three weeks of sample catches (they stay on the phone and never affect real prices), replay the welcome tour or the intro, and tips for presenting.
- **Log Out**.

### Works offline
Everything saves on the phone first (SwiftData). Waiting records upload automatically when there is signal, or with Sync now or the Wi-Fi button on Home.

### Dark Mode
Every color has a light and a dark version. Dark Mode uses a deep "night sea" navy instead of plain black, and the logo has a light-text version for dark backgrounds.

---

## 5. What changed for the finals build

The midterm was a clickable prototype with fixed sample data. The finals build turned it into a working, connected app:

**Real data and cloud**
- Supabase backend: accounts, catches, listings, offers and payments, protected by Row Level Security.
- Sync that works offline-first, cloud restore on a new phone, and cloud deletes.
- Fair prices computed from real recorded sales, with a new per-province view.
- Catch photos uploaded to Supabase Storage and shown on listings.

**New features**
- Buyer accounts, offers, a demo checkout (GCash, Maya, LandBank) and receipts.
- The AI Advisor with strict guardrails, plus an offline fallback.
- The daily sea and weather forecast with a go / careful / stay-ashore guide.
- Edit and delete catches, any fish species, real photos.
- Notifications built from real activity that open the related screen.
- Editable profile, password change, sync status, full privacy, help and about pages.
- Demo Tools, an Appearance switch and a welcome tour.

**Quality fixes found by testing on a real iPhone and the simulator**
- Accounts saved by the old version couldn't log in. They are now upgraded automatically.
- Screens couldn't scroll to their last items behind the tab bar. Fixed on every tab.
- Dark Mode was unreadable. There is now a complete dark palette.
- Weak passwords were accepted. They are now checked, with a live checklist.
- Placeholders and fallbacks were hard-coded to Batangas. They now use the user's own place.
- Dead buttons ("Edit Record", "Contact", "Forgot Password?", the profile avatar) all work now.
- Home's "Today's Catch" counted every catch ever. It now counts only today's.
- A notification could show a future time ("in 1 hr."). Fixed.
- Keyboard autocorrect garbled Filipino words in the Advisor. Autocorrect is now off there.

---

## 6. How the app was built, step by step

1. **Problem research.** Studied the consignacion system, RA 8550 and RA 11321, fish production and poverty data, and existing tools (ISDApp, Fish Landing, FishLink, ABALOBI). Found the gap: no Filipino tool joins catch logging, fair prices and direct buyers.
2. **Design.** Wrote user flows for fishers and buyers, built a Figma prototype, and chose a palette taken from the logo (ocean blue, navy, sea teal).
3. **Midterm prototype.** Built the SwiftUI screens with sample data to test the flow.
4. **Clean structure (MVC).** Split the code into Models (SwiftData records), Views (SwiftUI screens), Controllers (rules for auth, catches, market, offers, reports, the Advisor and sync) and Services (the cloud client, sync, fair prices, weather).
5. **Local data first.** Stored accounts and catches with SwiftData, hashed passwords with salted SHA-256, and validated mobile numbers, weights and dates.
6. **Cloud backend.** Created a Supabase project: Postgres tables, Row Level Security so each account sees only its own rows, views for the marketplace and fair prices, and an anonymous regional summary.
7. **Sync.** Wrote a small REST client (no extra libraries), offline-first uploads, restore on login, and token refresh.
8. **Marketplace and buyers.** Added buyer roles, offers, admin-only verification, and the demo payment flow.
9. **Fair-price engine.** Calculated the middle range of the last 30 days of sales per species, then per province, with a minimum of 5 sales for privacy.
10. **AI Advisor.** Deployed a Supabase Edge Function that calls Google Gemini with the user's data and strict scope and safety rules, plus an offline rule-based fallback.
11. **Sea forecast.** Connected Open-Meteo's weather and marine APIs and turned the raw numbers into a simple go / careful / stay-ashore guide.
12. **Real-device testing.** Installed the app on an iPhone and an iOS 26.4 simulator, went through every flow, and fixed each problem in its own small commit.
13. **Polish.** Added Dark Mode, the photo onboarding, the welcome tour, accessibility labels, 44-point tap targets, Reduce Motion support and Demo Tools.

---

## 7. Tech stack

| Part | Technology |
|---|---|
| App | Swift, SwiftUI, SwiftData, iOS 17+ |
| Architecture | Model–View–Controller |
| Cloud | Supabase (Postgres, Auth, Row Level Security, Storage, Edge Functions) |
| AI | Google Gemini (free tier) through a Supabase Edge Function |
| Weather | Open-Meteo forecast and marine APIs (free, no key) |
| Design | Figma |

---

## 8. Demo script (about 3 minutes)

1. Open the app and swipe through the five intro screens.
2. Log in as the demo fisher (`09172345678` / `password`).
3. On Home, tap **Sea today** to open the forecast.
4. **Log Catch**: type a fish that isn't listed, add a photo, save and list it.
5. Open **Market → your listing → offers**, accept one, and show the **price alignment score**.
6. Open **Fair Prices** and switch provinces.
7. Ask the **Advisor** a price question in Filipino, then an off-topic question to show the guardrails.
8. In **Profile**, switch **Appearance** to Dark and open **About**.
