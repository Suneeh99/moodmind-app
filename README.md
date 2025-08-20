# MoodMind App

A Flutter app that helps users verify task completion using AI-assisted image analysis with free-tier Hugging Face models, plus fast local fallbacks. Sentiment analysis is available via MeaningCloud (optional) with an offline fallback. Secrets are managed securely via compile-time environment defines (no keys in the repo).

---

## ✨ Features

- ✅ AI task verification from photos
- 🌐 Remote verification with Hugging Face Inference API (free-tier models)
- 💾 Local-only fallback (no network, zero cost)
- 🔁 Multiple captioning models with retry/backoff
- 🧠 Sentiment analysis
  - MeaningCloud API (optional)
  - Optimized local sentiment fallback
- 🎯 Points calculation with task-based heuristics
- 🔐 Secret-safe by default

---

## 🔐 Secrets and Environment

No API keys are committed. Provide them at build/run time:

- `HUGGING_FACE_API_KEY`: Hugging Face Inference API token
- `MEANINGCLOUD_API_KEY`: MeaningCloud API key (optional; required only for remote sentiment)

### Ways to supply:

#### Command-line:

```bash
flutter run --dart-define=HUGGING_FACE_API_KEY=your_hf_key --dart-define=MEANINGCLOUD_API_KEY=your_mc_key
flutter build apk --dart-define=HUGGING_FACE_API_KEY=your_hf_key --dart-define=MEANINGCLOUD_API_KEY=your_mc_key
```

#### From a file (recommended for local dev):

Create `env.json` at project root:

```json
{
  "HUGGING_FACE_API_KEY": "your_hf_key",
  "MEANINGCLOUD_API_KEY": "your_mc_key"
}
```

Run with:

```bash
flutter run --dart-define-from-file=env.json
```

If keys are omitted, the app automatically runs in local-only mode.

---

## 🤖 Hugging Face Models

Configured in `AIConfig.availableModels`:

- `Salesforce/blip-image-captioning-base`
- `nlpconnect/vit-gpt2-image-captioning`
- `microsoft/git-base-coco`

`EnhancedAIService` cycles through these with retries, then falls back to local verification.

---

## 📷 Local Verification

When no key is present or the API is unavailable, the app:

- Generates image captions locally (heuristics-free path)
- Performs lightweight checks (file size sanity, context heuristics)
- Accepts a lenient threshold to keep UX friendly

---

## 😄 Sentiment Analysis

- **Remote:** MeaningCloud (fast timeout)
- **Local:** Keyword-based sentiment with normalization and confidence scoring

If text is empty or API fails, defaults to neutral with safe values.

---

## 🧮 Points System

Points are computed based on:

- Base points + verification bonus
- Task category heuristics (fitness, study, work, cleaning, cooking)
- Time-of-day bonus (morning/evening)
- Title complexity (word count)

See `calculatePoints` in services for details.

---

## 🏗️ Project Setup

### Requirements

- Flutter SDK installed
- Dart SDK (bundled with Flutter)
- A Hugging Face token (if using remote verification)

### Installation Guide

```bash
git clone <repo-url>
cd moodmind
flutter pub get
```

### Run the App

#### Local-only (no keys):

```bash
flutter run
```

#### With API keys:

```bash
flutter run --dart-define=HUGGING_FACE_API_KEY=your_hf_key --dart-define=MEANINGCLOUD_API_KEY=your_mc_key
```

### Build Release APK

```bash
flutter build apk --release --dart-define=HUGGING_FACE_API_KEY=your_hf_key --dart-define=MEANINGCLOUD_API_KEY=your_mc_key
```

---

## 🔥 Firebase and Secrets

This repo ignores typical secret-bearing files:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `macos/Runner/GoogleService-Info.plist`
- `.env`, `.env.*`

If you add Firebase:

- Place `google-services.json` locally (ignored by Git)
- Follow FlutterFire docs for initialization

---

## 🗂️ Directory Structure

```
lib/
├── config/
│   └── ai_config.dart
├── services/
│   ├── enhanced_ai_service.dart
│   ├── ai_verification_service.dart
│   └── sentiment_analysis_service.dart
└── providers/
    └── auth_provider.dart
```

---

## 🛠 Troubleshooting

- ❌ GitHub push blocked due to secrets: Remove committed keys, rewrite history with `git filter-repo`, and rotate tokens.
- ⚠️ API 503 from Hugging Face: Model is loading; app retries then falls back to local.
- ❓ Empty API keys: App runs in local-only mode by design.
- 🐢 Slow network calls: Adjust timeouts/retries in `AIConfig`.

---

## 🤝 Contributing

- Fork, branch, and open a PR
- Keep secrets out of commits
- Prefer environment defines over hardcoding

---

## 📝 License

Add your preferred license here (e.g., MIT).
