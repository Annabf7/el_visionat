// Use the same firebase-admin instance as the function code
const admin = require('./functions/node_modules/firebase-admin');
const fs = require('fs');
const serviceAccount = JSON.parse(fs.readFileSync('./serviceAccountKey.json.bak', 'utf8'));

// Initialize with databaseURL if needed, though Firestore works with just creds usually
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'el-visionat' // Assuming projectId from context
});

const { triggerSyncWeeklyVoting } = require('./functions/lib/fcbq/sync_weekly_voting');

async function main() {
  console.log('🚀 Forcing sync for break week (target date: 2025-02-28)...');
  
  // We simulate a request with a future date to find the next matches
  const req = {
    data: { targetDate: '2025-02-28' }, // Friday before the weekend of 1st/2nd March
  };

  try {
    // Attempt to use .run() which is often available in test/emulated environments
    // or if the function is exported in a specific way.
    if (triggerSyncWeeklyVoting && typeof triggerSyncWeeklyVoting.run === 'function') {
        const result = await triggerSyncWeeklyVoting.run(req);
        console.log('✅ Result:', result);
    } else {
        console.log('⚠️ .run() method not found on exported function.');
        console.log('Export type:', typeof triggerSyncWeeklyVoting);
        // If it's just the function handler (sometimes v1)
        if (typeof triggerSyncWeeklyVoting === 'function') {
            const res = await triggerSyncWeeklyVoting(req);
            console.log('✅ Result (direct):', res);
        }
    }
  } catch (error) {
    console.error('❌ Error executing function:', error);
  }
}

main();
