**Subject:** Re: Configuration Update Request - Clarification & Action Items

Hi Infrastructure Team,

Thank you for the detailed check. This clears up the confusion!

### 1. Function Name & Status

You are correct. The function is **`curriculum-ingestion`**.

- We were using a local script with an outdated name (`pdf-curriculum-extractor`).
- **Why it seems "working" but isn't:** The currently running version (Go 1.21) is likely the **old codebase**. It might be processing files successfully _technically_, but it is not executing the **new logic** we just wrote (which includes the Gemini 2.5 upgrade, improved prompt engineering, and correct Firestore schema). This explains why we don't see the expected data in our collections.

### 2. Action Items (Please Apply)

To roll out our new code, we need the following updates to the `curriculum-ingestion` function:

**A. Runtime Upgrade (Required)**

- Please upgrade to **Go 1.25** (`go125`). Our new codebase relies on features/dependencies in this version.

**B. Environment Variables (Required)**
Yes, our **new code** specifically reads these variables to control the AI behavior. Please add:

- `GEMINI_MODEL_ID` = `gemini-2.5-pro` (Critical for our quality improvements)
- `GEMINI_LOCATION` = `us-central1`
- `DOCUMENT_AI_LOCATION` = `us`

**C. Processor ID**

- You mentioned using `a81a921a9fa90f91`.
- Our local config had `bc9747f84fc1beb1`.
- **Decision:** If `a81a921a9fa90f91` is currently active and working, **please keep it**. We will update our local config to match yours.

### Summary

The infrastructure is correctly wired (Bucket/PubSub/IAM), but the **Compute (Runtime)** and **Configuration (Env Vars)** are outdated.

Once you apply the **Go 1.25 upgrade** and add the **Gemini Env Vars**, we will trigger a new build/deploy from our CI/CD (or however code is synced) to ensure the new logic is running.

Thanks,
Curriculum Ingestion Team
