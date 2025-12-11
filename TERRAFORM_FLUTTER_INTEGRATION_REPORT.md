# Terraform Infrastructure → Flutter App Integration Report

**Date:** December 11, 2025  
**Project:** Octo Stars Student App  
**Backend Project:** `octo-education-ddc76`  
**Status:** 🟡 Integration Blocked - Configuration Mismatches Found

---

## Executive Summary

The Terraform infrastructure migration to `octo-education-ddc76` is complete and all backend services are successfully deployed. However, **critical configuration mismatches** exist between the Terraform-generated service endpoints and the Flutter app's configuration system that will prevent successful integration.

**Impact:** The Flutter app cannot connect to the new backend infrastructure without resolving these mismatches.

**Priority:** 🔴 **HIGH** - Blocks production deployment

---

## ✅ What's Working

1. **Terraform Infrastructure**: All services deployed successfully to Cloud Run
2. **Service URLs Generated**: SERVICE_ENDPOINTS.md contains correct URLs
3. **Project Migration**: Backend running on new project `octo-education-ddc76`
4. **Service Availability**: All 9+ microservices are operational

---

## ❌ Critical Issues Found

### **Issue #1: Environment Variable Naming Mismatch**

**Severity:** 🔴 CRITICAL  
**Impact:** App will fail to load service URLs from .env file

#### The Problem

**Terraform-generated `SERVICE_ENDPOINTS.md` provides:**

```bash
AI_MENTOR_SERVICE_URL=https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app
SQUAD_SERVICE_URL=https://squad-service-3dh2p4j4qq-uc.a.run.app
CURRICULUM_SERVICE_URL=https://curriculum-service-3dh2p4j4qq-uc.a.run.app
```

**Flutter app's `api_config.dart` expects:**

```dart
AI_MENTOR_SERVICE_API_URL      // Note: _API suffix added
SQUAD_SERVICE_API_URL          // Note: _API suffix added
CURRICULUM_API_URL             // Note: Different pattern entirely
```

#### Impact

- App will throw exceptions: `"AI_MENTOR_SERVICE_API_URL not configured in .env"`
- None of the microservices will be accessible
- App will be non-functional

#### Recommendation

**Choose one standard and enforce it everywhere:**

**Option A** (Recommended): Terraform adopts Flutter's naming

```bash
AI_MENTOR_SERVICE_API_URL=...
SQUAD_SERVICE_API_URL=...
CURRICULUM_API_URL=...
```

**Option B**: Flutter adopts Terraform's simpler naming

```bash
AI_MENTOR_SERVICE_URL=...
SQUAD_SERVICE_URL=...
CURRICULUM_SERVICE_URL=...
```

We recommend **Option B** - simpler, cleaner, follows REST conventions.

---

### **Issue #2: Incomplete Service Coverage**

**Severity:** 🟡 MEDIUM  
**Impact:** Flutter app may use undocumented services

#### The Problem

**Terraform documented these services:**

- ✅ AI Mentor Service
- ✅ Squad Service
- ✅ Curriculum Service
- ✅ CIE API
- ✅ CIE Worker
- ✅ Mathematics Service
- ✅ Physics Gateway
- ✅ Chemistry Gateway
- ✅ Core Admin API

**Flutter `api_config.dart` only has configuration for:**

- ✅ AI Mentor Service
- ✅ Squad Service
- ✅ Curriculum Service

#### Questions for Terraform Team

1. **Does the Flutter app need access to other services?**

   - CIE API
   - CIE Worker
   - Mathematics Service
   - Physics Gateway
   - Chemistry Gateway
   - Core Admin API

2. **If YES**: Should these be added to the standard .env template?

3. **If NO**: Are these services backend-only? Should they be marked as internal-only?

---

### **Issue #3: API Path Structure Ambiguity**

**Severity:** 🟡 MEDIUM  
**Impact:** May cause 404 errors on API calls

#### The Problem

**Flutter app appends paths to base URLs:**

```dart
// Takes base URL from Terraform
mentorServiceBaseUrl = "https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app"

// Then adds /api/v1
mentorServiceApiPath = "$mentorServiceBaseUrl/api/$version"
// Result: https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app/api/v1
```

**Questions:**

1. Do the Cloud Run services expect `/api/v1` prefix in URLs?
2. Or should Terraform provide full API paths including version?
3. Or should Flutter NOT append paths?

#### Current Behavior

| Service       | Flutter Constructs | Does Backend Expect This? |
| ------------- | ------------------ | ------------------------- |
| AI Mentor     | `{url}/api/v1`     | ❓ Unknown                |
| Squad Service | `{url}/v1`         | ❓ Unknown                |
| Curriculum    | `{url}/api/v1`     | ❓ Unknown                |

**We need clarification on the correct URL structure for each service.**

---

### **Issue #4: Service Naming Inconsistency**

**Severity:** 🟢 LOW  
**Impact:** Documentation confusion only

**Backend overview document says:** "Mathematics MCP"  
**SERVICE_ENDPOINTS.md says:** "Mathematics Service"  
**Cloud Run service name:** `mathematic-service` (singular, not plural)

**Recommendation:** Standardize on one name across all documentation.

---

## 🔥 Blocking Issue: Firebase Configuration

**Severity:** 🔴 CRITICAL - Highest Priority  
**Impact:** Authentication and Firestore will not work

### Current State

**Flutter app Firebase config:**

```dart
projectId: 'octo-education-96e36'  // ❌ OLD PROJECT
storageBucket: 'octo-education-96e36.firebasestorage.app'
```

**This is still pointing to the DEPRECATED project!**

### Required Files from Terraform/Backend Team

To complete Firebase migration, Flutter team needs:

1. **`google-services.json`** (Android) - From new project console
2. **`GoogleService-Info.plist`** (iOS) - From new project console
3. **Firebase config values** for regenerating `firebase_options.dart`:
   - API Key (Android)
   - API Key (iOS)
   - App ID (Android)
   - App ID (iOS)
   - Messaging Sender ID
   - Storage Bucket URL

**Where to get these:**

- Firebase Console: `https://console.firebase.google.com/project/octo-education-ddc76/settings/general`
- Download both platform config files
- Provide to Flutter team

---

## 📋 Action Items for Terraform Team

### **Immediate Actions (Today)**

1. **Standardize environment variable names**

   - Decide: Keep `_URL` suffix or adopt `_API_URL`?
   - Update `SERVICE_ENDPOINTS.md` accordingly
   - Update Terraform output variable names to match

2. **Provide Firebase configuration files**

   - Download `google-services.json` from Firebase Console
   - Download `GoogleService-Info.plist` from Firebase Console
   - Send to Flutter team via secure channel

3. **Clarify API path structure**
   - For each service, document whether base URL includes `/api/v1` or not
   - Example: Should we call `https://ai-mentor-service.../api/v1/chat` or just `https://ai-mentor-service.../chat`?

### **Short-term Actions (This Week)**

4. **Define service access matrix**

   - Document which services are "public" (Flutter app can call)
   - Document which services are "internal" (backend-only)
   - Create `.env.template` file with ONLY public services

5. **Standardize service naming**

   - Pick one name for each service
   - Update all documentation
   - Update Terraform variable names if needed

6. **Create integration testing checklist**
   - Health check endpoints for each service
   - Auth token validation process
   - Sample API call for each service

---

## 📂 Suggested Deliverables

### **From Terraform Team to Flutter Team:**

```
📦 integration-package/
├── .env.production              # Production environment variables
├── google-services.json         # Android Firebase config
├── GoogleService-Info.plist     # iOS Firebase config
├── firebase-config.json         # Structured Firebase config
├── service-health-check.sh      # Script to verify all services are up
└── INTEGRATION_GUIDE.md         # Step-by-step Flutter integration guide
```

### **Suggested `.env.production` format:**

```bash
# ===========================================
# Backend Services - Production
# Project: octo-education-ddc76
# Generated: 2025-12-11
# ===========================================

# Core Services
AI_MENTOR_SERVICE_URL=https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app
CORE_ADMIN_API_URL=https://core-admin-api-3dh2p4j4qq-uc.a.run.app
CURRICULUM_SERVICE_URL=https://curriculum-service-3dh2p4j4qq-uc.a.run.app

# Intelligence Services
CIE_API_URL=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
CIE_WORKER_URL=https://curriculum-intelligence-engine-worker-3dh2p4j4qq-uc.a.run.app

# Subject Services
MATH_SERVICE_URL=https://mathematic-service-3dh2p4j4qq-uc.a.run.app
PHYSICS_GATEWAY_URL=https://physics-gateway-3dh2p4j4qq-uc.a.run.app
CHEMISTRY_GATEWAY_URL=https://chemistry-gateway-3dh2p4j4qq-uc.a.run.app

# Collaboration Services
SQUAD_SERVICE_URL=https://squad-service-3dh2p4j4qq-uc.a.run.app

# API Versions (if needed)
AI_MENTOR_SERVICE_API_VERSION=v1
SQUAD_SERVICE_API_VERSION=v1
```

---

## 🤝 Coordination Needed

### **Cross-team Discussion Topics:**

1. **URL Structure Convention**

   - Should Terraform output base URLs only?
   - Should Flutter append `/api/version`?
   - Or should Terraform output full API paths?

2. **Environment Variable Standard**

   - Agree on naming convention for all future services
   - Document in shared Wiki/Confluence

3. **Service Discovery**

   - Should Flutter app hardcode URLs?
   - Or should there be a service discovery endpoint?
   - Consider: `GET /config/services` returning all URLs

4. **Deployment Coordination**
   - When Terraform updates URLs (new deployment), how does Flutter team get notified?
   - Should URLs be published to a shared S3/GCS bucket?
   - Automated notification system?

---

## 📊 Integration Readiness Matrix

| Component                  | Status         | Blocker  |
| -------------------------- | -------------- | -------- |
| Terraform Infrastructure   | ✅ Ready       | None     |
| Backend Services           | ✅ Deployed    | None     |
| SERVICE_ENDPOINTS.md       | ✅ Generated   | None     |
| Environment Variable Names | ❌ Mismatched  | Issue #1 |
| Firebase Configuration     | ❌ Old Project | Issue #4 |
| API Path Structure         | ⚠️ Unclear     | Issue #3 |
| Service Coverage           | ⚠️ Incomplete  | Issue #2 |
| **Overall Status**         | ❌ **BLOCKED** | Multiple |

---

## 🎯 Success Criteria

Integration will be complete when:

- [ ] Flutter app uses standardized environment variable names matching Terraform
- [ ] Firebase configuration updated to `octo-education-ddc76`
- [ ] All required services have URLs in `.env` file
- [ ] API path structure is documented and working
- [ ] Health checks pass for all services
- [ ] Authentication flow works end-to-end
- [ ] Sample API call succeeds for each service Flutter uses

---

## 📞 Contact Information

**Flutter Team Lead:** [Add contact]  
**Terraform Team Lead:** [Add contact]  
**Backend Team Lead:** [Add contact]

**Slack Channel:** #backend-migration  
**Emergency Contact:** octo.stars82@gmail.com

---

## Appendix A: Current api_config.dart Structure

```dart
class ApiConfig {
  // Curriculum Service
  static String get curriculumBaseUrl {
    return dotenv.env['CURRICULUM_API_URL'] ?? _prodCurriculumUrl;
  }

  // Squad Service
  static String get squadServiceBaseUrl {
    final envUrl = dotenv.env['SQUAD_SERVICE_API_URL'];
    if (envUrl == null || envUrl.isEmpty) {
      throw Exception('SQUAD_SERVICE_API_URL not configured in .env');
    }
    return envUrl;
  }

  // AI Mentor Service
  static String get mentorServiceBaseUrl {
    final envUrl = dotenv.env['AI_MENTOR_SERVICE_API_URL'];
    if (envUrl == null || envUrl.isEmpty) {
      throw Exception('AI_MENTOR_SERVICE_API_URL not configured in .env');
    }
    return envUrl;
  }

  // Constructs full paths by appending /api/v1 or /v1
  static String get curriculumApiPath => '$curriculumBaseUrl/api/v1';
  static String get squadServiceApiPath => '$squadServiceBaseUrl/$squadServiceVersion';
  static String get mentorServiceApiPath => '$mentorServiceBaseUrl/api/$mentorServiceVersion';
}
```

**This shows Flutter app WILL append path segments to base URLs.**

---

## Appendix B: Files Requiring Updates

### Flutter App Files:

- `/lib/core/config/api_config.dart` - Service URL configuration
- `/lib/firebase_options.dart` - Firebase project config
- `/android/app/google-services.json` - Android Firebase config
- `/ios/Runner/GoogleService-Info.plist` - iOS Firebase config
- `/.env` - Environment variables (not committed to git)

### Terraform Files:

- Service endpoint output configuration
- Variable naming conventions
- Documentation templates

---

**Report prepared by:** GitHub Copilot (AI Assistant)  
**Review required by:** Flutter Team Lead + Terraform Team Lead  
**Next meeting:** Schedule coordination call within 24 hours
