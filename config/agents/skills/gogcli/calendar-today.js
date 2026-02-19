#!/usr/bin/env node

/**
 * Helper script to show today's calendar events
 * Usage: node calendar-today.js [--json]
 */

const { execSync } = require('child_process');

const useJson = process.argv.includes('--json');

// Get today's date range
const today = new Date();
const tomorrow = new Date(today);
tomorrow.setDate(tomorrow.getDate() + 1);

const formatDate = (date) => date.toISOString().split('T')[0];
const fromDate = formatDate(today);
const toDate = formatDate(tomorrow);

try {
  // Check if gog is installed
  execSync('which gog', { stdio: 'ignore' });
} catch {
  console.error('❌ gogcli is not installed or not in PATH');
  console.error('Install with: brew install steipete/tap/gogcli');
  process.exit(1);
}

// Run the calendar command with JSON output
const command = `gog calendar events --from ${fromDate} --to ${toDate} --json 2>/dev/null`;

try {
  const output = execSync(command, { encoding: 'utf8' });
  const data = JSON.parse(output);
  
  if (!data.events || data.events.length === 0) {
    console.log('📅 No events scheduled for today');
    process.exit(0);
  }
  
  if (useJson) {
    console.log(JSON.stringify(data, null, 2));
    process.exit(0);
  }
  
  // Sort events by start time
  const sortedEvents = data.events.sort((a, b) => {
    return new Date(a.start.dateTime) - new Date(b.start.dateTime);
  });
  
  console.log(`📅 ${sortedEvents.length} event(s) today (${today.toLocaleDateString()}):\n`);
  
  sortedEvents.forEach((event, i) => {
    const start = new Date(event.start.dateTime);
    const end = new Date(event.end.dateTime);
    const startTime = start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const endTime = end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    
    const status = event.status === 'confirmed' ? '✓' : '⏳';
    const allDay = event.start.date ? '📌 All-day' : `🕐 ${startTime} - ${endTime}`;
    
    console.log(` ${i + 1}. ${event.summary}`);
    console.log(`    ${allDay}`);
    if (event.location) console.log(`    📍 ${event.location}`);
    if (event.attendees && event.attendees.length > 0) {
      console.log(`    👥 ${event.attendees.length} attendee(s)`);
    }
    console.log();
  });
  
} catch (error) {
  console.error('❌ Error fetching calendar events:', error.message);
  console.error('\nMake sure you have:');
  console.error('  1. gogcli installed: brew install steipete/tap/gogcli');
  console.error('  2. Authenticated: gog auth add your.email@gmail.com');
  console.error('  3. Set default account: export GOG_ACCOUNT=your.email@gmail.com');
  process.exit(1);
}
