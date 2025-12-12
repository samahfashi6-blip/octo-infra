// Environment Template
// This file is replaced at runtime with actual environment variables
(function(window) {
  window.__env = window.__env || {};
  
  // Default values - will be replaced by docker-entrypoint.sh
  window.__env.apiCoreAdminUrl = '';
  window.__env.apiAiMentorUrl = '';
  window.__env.apiCurriculumUrl = '';
  window.__env.apiCieUrl = '';
  window.__env.apiMathUrl = '';
  window.__env.apiPhysicsUrl = '';
  window.__env.apiChemistryUrl = '';
  window.__env.apiSquadUrl = '';
  window.__env.firebaseProjectId = 'octo-education-ddc76';
  window.__env.environment = 'production';
  window.__env.appVersion = '1.0.0';
  window.__env.enableAnalytics = true;
  window.__env.debug = false;
}(this));
