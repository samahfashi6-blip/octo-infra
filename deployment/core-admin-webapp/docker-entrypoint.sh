#!/bin/sh
set -e

# Generate env.js from environment variables at runtime
cat > /usr/share/nginx/html/assets/env.js <<EOF
// Runtime Environment Configuration
// Generated at container startup - DO NOT EDIT
(function(window) {
  window.__env = window.__env || {};
  
  // Backend API URLs
  window.__env.apiCoreAdminUrl = '${API_CORE_ADMIN_URL:-}';
  window.__env.apiAiMentorUrl = '${API_AI_MENTOR_URL:-}';
  window.__env.apiCurriculumUrl = '${API_CURRICULUM_URL:-}';
  window.__env.apiCieUrl = '${API_CIE_URL:-}';
  window.__env.apiMathUrl = '${API_MATH_URL:-}';
  window.__env.apiPhysicsUrl = '${API_PHYSICS_URL:-}';
  window.__env.apiChemistryUrl = '${API_CHEMISTRY_URL:-}';
  window.__env.apiSquadUrl = '${API_SQUAD_URL:-}';
  
  // Firebase configuration
  window.__env.firebaseProjectId = '${FIREBASE_PROJECT_ID:-octo-education-ddc76}';
  
  // Application settings
  window.__env.environment = '${ENVIRONMENT:-production}';
  window.__env.appVersion = '${APP_VERSION:-1.0.0}';
  window.__env.enableAnalytics = ${ENABLE_ANALYTICS:-true};
  
  // Debug flag
  window.__env.debug = ${DEBUG:-false};
}(this));
EOF

echo "Environment configuration generated:"
cat /usr/share/nginx/html/assets/env.js

# Execute the CMD
exec "$@"
