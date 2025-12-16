# 📧 FYI: CIE API Permission Issue Investigation

**To:** CIE Development Team
**From:** Infrastructure Team
**Subject:** FYI: Investigation of 403 Errors from Ingestion Service

---

Hi Team,

We wanted to keep you in the loop regarding an issue reported by the Curriculum Ingestion team.

**The Issue:**
The Ingestion service is receiving **403 Forbidden** errors when attempting to call your CIE API (`POST /api/v1/objectives/process`).

**Our Investigation:**
We have verified the infrastructure configuration:
1.  **IAM:** The Ingestion service account (`sa-curriculum-ingestion`) **HAS** the `roles/run.invoker` permission on your service.
2.  **Ingress:** Your service is correctly configured to accept traffic (`ingress: all`).

**Suspected Cause:**
Since the infrastructure permissions are correct, we suspect the issue lies in how the Ingestion service is generating its authentication token (likely an audience mismatch). We have communicated this to them.

**Action for You:**
No action is required from your side at this moment. However, if they reach out, please confirm that your service is not performing any additional application-level authorization checks that might be rejecting their requests.

Best,
Infrastructure Team
