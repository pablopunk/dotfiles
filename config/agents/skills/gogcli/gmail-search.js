#!/usr/bin/env node

/**
 * Helper script to search Gmail and format results nicely
 * Usage: node gmail-search.js "search query" [--max 10]
 */

const { execSync } = require('child_process');

const query = process.argv[2] || 'newer_than:7d';
const maxFlag = process.argv.includes('--max');
const maxValue = maxFlag ? process.argv[process.argv.indexOf('--max') + 1] : '10';

if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log('Usage: node gmail-search.js "search query" [--max 10]');
  console.log('');
  console.log('Examples:');
  console.log('  node gmail-search.js "is:unread" --max 5');
  console.log('  node gmail-search.js "newer_than:7d"');
  console.log('  node gmail-search.js "from:boss@company.com"');
  process.exit(0);
}

try {
  // Check if gog is installed
  execSync('which gog', { stdio: 'ignore' });
} catch {
  console.error('❌ gogcli is not installed or not in PATH');
  console.error('Install with: brew install steipete/tap/gogcli');
  process.exit(1);
}

// Run the search with JSON output
const command = `gog gmail search '${query}' --max ${maxValue} --json 2>/dev/null`;

try {
  const output = execSync(command, { encoding: 'utf8' });
  const data = JSON.parse(output);
  
  if (!data.threads || data.threads.length === 0) {
    console.log('📭 No emails found matching your query');
    process.exit(0);
  }
  
  console.log(`📧 ${data.threads.length} email(s):\n`);
  
  data.threads.forEach((thread, i) => {
    const date = thread.date || 'Unknown';
    const from = thread.from || 'Unknown sender';
    const subject = thread.subject || '(No subject)';
    const messages = thread.messageCount || 1;
    
    // Format labels
    const labels = thread.labels || [];
    const isUnread = labels.includes('UNREAD');
    const isImportant = labels.includes('IMPORTANT');
    const statusIcon = isUnread ? '🔴' : '⚪';
    const importantIcon = isImportant ? '⭐' : '';
    
    // Extract name from email
    const fromName = from.split('<')[0].trim() || from;
    
    console.log(`${statusIcon} ${subject} ${importantIcon}`);
    console.log(`   From: ${fromName}`);
    console.log(`   Date: ${date}${messages > 1 ? ` | ${messages} messages` : ''}`);
    console.log();
  });
  
} catch (error) {
  console.error('❌ Error fetching emails:', error.message);
  console.error('\nMake sure you have:');
  console.error('  1. gogcli installed: brew install steipete/tap/gogcli');
  console.error('  2. Authenticated: gog auth add your.email@gmail.com');
  console.error('  3. Set default account: export GOG_ACCOUNT=your.email@gmail.com');
  process.exit(1);
}
