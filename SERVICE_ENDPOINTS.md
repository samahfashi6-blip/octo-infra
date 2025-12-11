# Service Endpoints - Frontend Integration Guide

**Project:** `octo-education-ddc76`  
**Environment:** Production  
**Region:** us-central1  
**Last Updated:** December 11, 2025

---

## 🌐 Service URLs

All services are deployed on GCP Cloud Run and are accessible via HTTPS.

### **Core Services**

| Service                | Endpoint                                             | Description                                |
| ---------------------- | ---------------------------------------------------- | ------------------------------------------ |
| **AI Mentor Service**  | `https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app`  | AI-powered mentoring and tutoring          |
| **Core Admin API**     | `https://core-admin-api-3dh2p4j4qq-uc.a.run.app`     | Administrative API for system management   |
| **Curriculum Service** | `https://curriculum-service-3dh2p4j4qq-uc.a.run.app` | Curriculum management and content delivery |

### **Intelligence Services**

| Service        | Endpoint                                                                | Description                                 |
| -------------- | ----------------------------------------------------------------------- | ------------------------------------------- |
| **CIE API**    | `https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app`    | Curriculum intelligence and recommendations |
| **CIE Worker** | `https://curriculum-intelligence-engine-worker-3dh2p4j4qq-uc.a.run.app` | Background processing for CIE               |

### **Subject Services**

| Service                      | Endpoint                                                   | Description                                   |
| ---------------------------- | ---------------------------------------------------------- | --------------------------------------------- |
| **Mathematics Service**      | `https://mathematic-service-3dh2p4j4qq-uc.a.run.app`       | Mathematics problem solving and exercises     |
| **Physics Gateway**          | `https://physics-gateway-3dh2p4j4qq-uc.a.run.app`          | Physics service gateway (use this endpoint)   |
| **Physics Python Sidecar**   | `https://physics-python-sidecar-3dh2p4j4qq-uc.a.run.app`   | Internal service - use Gateway instead        |
| **Chemistry Gateway**        | `https://chemistry-gateway-3dh2p4j4qq-uc.a.run.app`        | Chemistry service gateway (use this endpoint) |
| **Chemistry Python Sidecar** | `https://chemistry-python-sidecar-3dh2p4j4qq-uc.a.run.app` | Internal service - use Gateway instead        |
| **Squad Service**            | `https://squad-service-3dh2p4j4qq-uc.a.run.app`            | Team and collaboration management             |

---

## 📝 Environment Configuration

### **JSON Format** (for .env or config files)

```json
{
  "AI_MENTOR_SERVICE_URL": "https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app",
  "CORE_ADMIN_API_URL": "https://core-admin-api-3dh2p4j4qq-uc.a.run.app",
  "CURRICULUM_SERVICE_URL": "https://curriculum-service-3dh2p4j4qq-uc.a.run.app",
  "CIE_API_URL": "https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app",
  "CIE_WORKER_URL": "https://curriculum-intelligence-engine-worker-3dh2p4j4qq-uc.a.run.app",
  "MATH_SERVICE_URL": "https://mathematic-service-3dh2p4j4qq-uc.a.run.app",
  "PHYSICS_GATEWAY_URL": "https://physics-gateway-3dh2p4j4qq-uc.a.run.app",
  "CHEMISTRY_GATEWAY_URL": "https://chemistry-gateway-3dh2p4j4qq-uc.a.run.app",
  "SQUAD_SERVICE_URL": "https://squad-service-3dh2p4j4qq-uc.a.run.app"
}
```

### **.env Format**

```bash
AI_MENTOR_SERVICE_URL=https://ai-mentor-service-3dh2p4j4qq-uc.a.run.app
CORE_ADMIN_API_URL=https://core-admin-api-3dh2p4j4qq-uc.a.run.app
CURRICULUM_SERVICE_URL=https://curriculum-service-3dh2p4j4qq-uc.a.run.app
CIE_API_URL=https://curriculum-intelligence-engine-api-3dh2p4j4qq-uc.a.run.app
CIE_WORKER_URL=https://curriculum-intelligence-engine-worker-3dh2p4j4qq-uc.a.run.app
MATH_SERVICE_URL=https://mathematic-service-3dh2p4j4qq-uc.a.run.app
PHYSICS_GATEWAY_URL=https://physics-gateway-3dh2p4j4qq-uc.a.run.app
CHEMISTRY_GATEWAY_URL=https://chemistry-gateway-3dh2p4j4qq-uc.a.run.app
SQUAD_SERVICE_URL=https://squad-service-3dh2p4j4qq-uc.a.run.app
```

---

## ⚠️ Important Notes

### **Authentication**

- Most endpoints require **JWT authentication**
- Include the token in the `Authorization` header: `Bearer <token>`
- Authentication tokens should be obtained from the **Core Admin API**

### **Service Architecture**

- **Python Sidecars**: Internal gRPC services - **DO NOT call directly from frontend**
- **Gateways**: Use **Physics Gateway** and **Chemistry Gateway** instead of sidecars
- All services communicate internally using service accounts

### **CORS Configuration**

- Services are configured to accept requests from authorized origins
- If you encounter CORS issues, contact the backend team to whitelist your domain

### **Rate Limiting**

- Some services may implement rate limiting
- Respect HTTP 429 (Too Many Requests) responses
- Implement exponential backoff for retries

### **Health Checks**

- All services expose a `/health` endpoint for monitoring
- Use this for service availability checks before making requests

---

## 🔧 Integration Best Practices

1. **Use Environment Variables**: Store all URLs in your frontend environment configuration
2. **Error Handling**: Implement proper error handling for network failures and API errors
3. **Timeouts**: Set reasonable timeout values (recommended: 30 seconds)
4. **Retry Logic**: Implement retry logic with exponential backoff for transient failures
5. **Logging**: Log all API calls and responses for debugging purposes
6. **Security**: Never expose JWT tokens in client-side logs or browser console

---

## 📞 Support

For questions or issues with these endpoints:

- **Infrastructure Team**: octo.stars82@gmail.com
- **Backend Team**: Contact respective service teams via GitHub repositories
- **Documentation**: Check service-specific README files for API documentation

---

## 🔄 Service Status

All services are currently **LIVE** and operational:

- ✅ AI Mentor Service
- ✅ Core Admin API
- ✅ Curriculum Service
- ✅ CIE API
- ✅ CIE Worker
- ✅ Mathematics Service
- ✅ Physics Gateway
- ✅ Chemistry Gateway
- ✅ Squad Service

**Monitoring**: https://console.cloud.google.com/run?project=octo-education-ddc76

---

_This document is auto-generated from Terraform outputs. For the latest endpoints, run:_

```bash
cd infra/env/main && terraform output -json
```
