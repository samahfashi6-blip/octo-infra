#!/bin/bash

set -euo pipefail

#########################
# VALIDATION SCRIPT
# Use this after migration to compare collection counts
#########################

OLD_PROJECT="octo-education-96e36"
NEW_PROJECT="octo-education-ddc76"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "============================================"
echo "   FIRESTORE MIGRATION VALIDATION"
echo "============================================"
echo ""

log_info "This script requires a service account key with Firestore access."
log_info "It uses the Firebase Admin SDK to count documents."
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_error "Node.js is required but not installed."
    log_info "Install from: https://nodejs.org/"
    exit 1
fi

# Check if validation script exists
if [ ! -f "validate-firestore-counts.js" ]; then
    log_warn "Creating validation Node.js script..."
    
    cat > validate-firestore-counts.js << 'EOFJS'
const admin = require('firebase-admin');

async function countDocuments(db, collectionPath) {
  try {
    const snapshot = await db.collection(collectionPath).count().get();
    return snapshot.data().count;
  } catch (error) {
    console.error(`Error counting ${collectionPath}:`, error.message);
    return -1;
  }
}

async function listCollections(db) {
  const collections = await db.listCollections();
  return collections.map(col => col.id);
}

async function validateProjects(oldProject, newProject) {
  // Initialize both projects
  const oldApp = admin.initializeApp({
    projectId: oldProject
  }, 'old');
  
  const newApp = admin.initializeApp({
    projectId: newProject
  }, 'new');
  
  const oldDb = oldApp.firestore();
  const newDb = newApp.firestore();
  
  console.log('\nFetching collections from old project...');
  const oldCollections = await listCollections(oldDb);
  
  console.log('\nFetching collections from new project...');
  const newCollections = await listCollections(newDb);
  
  console.log('\n===========================================');
  console.log('COLLECTION COMPARISON');
  console.log('===========================================\n');
  
  const allCollections = new Set([...oldCollections, ...newCollections]);
  
  let mismatches = 0;
  let matches = 0;
  
  for (const collection of allCollections) {
    const oldExists = oldCollections.includes(collection);
    const newExists = newCollections.includes(collection);
    
    if (!oldExists) {
      console.log(`❌ ${collection}: Only in NEW project`);
      mismatches++;
      continue;
    }
    
    if (!newExists) {
      console.log(`❌ ${collection}: Missing in NEW project`);
      mismatches++;
      continue;
    }
    
    // Count documents
    const oldCount = await countDocuments(oldDb, collection);
    const newCount = await countDocuments(newDb, collection);
    
    if (oldCount === newCount) {
      console.log(`✅ ${collection}: ${oldCount} documents (match)`);
      matches++;
    } else {
      console.log(`❌ ${collection}: OLD=${oldCount}, NEW=${newCount} (mismatch)`);
      mismatches++;
    }
  }
  
  console.log('\n===========================================');
  console.log('VALIDATION SUMMARY');
  console.log('===========================================\n');
  console.log(`Total collections checked: ${allCollections.size}`);
  console.log(`Matches: ${matches}`);
  console.log(`Mismatches: ${mismatches}`);
  
  if (mismatches === 0) {
    console.log('\n✅ Migration validation PASSED');
    process.exit(0);
  } else {
    console.log('\n❌ Migration validation FAILED');
    console.log('Please investigate mismatches before proceeding.');
    process.exit(1);
  }
}

const oldProject = process.env.OLD_PROJECT || 'octo-education-96e36';
const newProject = process.env.NEW_PROJECT || 'octo-education-ddc76';

validateProjects(oldProject, newProject)
  .catch(error => {
    console.error('Validation failed:', error);
    process.exit(1);
  });
EOFJS

    log_info "Created validate-firestore-counts.js"
fi

# Check if package.json exists
if [ ! -f "package.json" ]; then
    log_info "Creating package.json..."
    cat > package.json << 'EOF'
{
  "name": "firestore-validation",
  "version": "1.0.0",
  "description": "Firestore migration validation",
  "main": "validate-firestore-counts.js",
  "scripts": {
    "validate": "node validate-firestore-counts.js"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0"
  }
}
EOF
fi

# Install dependencies
if [ ! -d "node_modules" ]; then
    log_info "Installing dependencies..."
    npm install
fi

# Set environment variables
export OLD_PROJECT="${OLD_PROJECT}"
export NEW_PROJECT="${NEW_PROJECT}"

# Set Google Application Credentials if needed
if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    log_warn "GOOGLE_APPLICATION_CREDENTIALS not set."
    log_info "Using gcloud default credentials..."
    export GOOGLE_APPLICATION_CREDENTIALS="$(gcloud auth application-default print-access-token 2>/dev/null | head -c 0 && echo '')"
fi

log_info "Starting validation..."
echo ""

node validate-firestore-counts.js

echo ""
log_info "Validation complete."
