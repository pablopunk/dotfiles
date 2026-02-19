#!/usr/bin/env node

/**
 * Helper script to search calendar events with flexible date ranges
 * Usage: node calendar-events.js [options]
 * 
 * Options:
 *   --from, -f    Start date (YYYY-MM-DD or relative: today, tomorrow, yesterday, week, month)
 *   --to, -t      End date (YYYY-MM-DD or relative: today, tomorrow, week, month)
 *   --days, -d    Number of days from start date (alternative to --to)
 *   --json        Output raw JSON
 *   --max         Maximum events to show (default: 50)
 * 
 * Examples:
 *   node calendar-events.js                    # Today only
 *   node calendar-events.js --from today --to week     # Next 7 days
 *   node calendar-events.js --from tomorrow --days 3   # Tomorrow + 2 days
 *   node calendar-events.js --from 2024-02-01 --to 2024-02-28
 */

const { execSync } = require('child_process');

// Parse arguments
const args = process.argv.slice(2);
const useJson = args.includes('--json');
const maxIndex = args.findIndex(a => a === '--max');
const maxValue = maxIndex !== -1 ? args[maxIndex + 1] : '50';

const fromIndex = Math.max(args.findIndex(a => a === '--from' || a === '-f'), 0);
const toIndex = Math.max(args.findIndex(a => a === '--to' || a === '-t'), 0);
const daysIndex = Math.max(args.findIndex(a => a === '--days' || a === '-d'), 0);

let fromArg = fromIndex > 0 ? args[fromIndex + 1] : 'today';
let toArg = toIndex > 0 ? args[toIndex + 1] : null;
const daysArg = daysIndex > 0 ? parseInt(args[daysIndex + 1]) : null;

// Parse relative dates
function parseDate(input, isEnd = false) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  switch (input?.toLowerCase()) {
    case 'today':
      return today;
    case 'yesterday':
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      return yesterday;
    case 'tomorrow':
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow;
    case 'week':
      const week = new Date(today);
      week.setDate(week.getDate() + (isEnd ? 7 : 0));
      return week;
    case 'month':
      const month = new Date(today);
      month.setMonth(month.getMonth() + (isEnd ? 1 : 0));
      return month;
    default:
      // Try parsing as YYYY-MM-DD
      if (input && /^\d{4}-\d{2}-\d{2}$/.test(input)) {
        return new Date(input);
      }
      return today;
  }
}

// Calculate date range
let startDate = parseDate(fromArg, false);
let endDate;

if (daysArg) {
  endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + daysArg);
} else if (toArg) {
  endDate = parseDate(toArg, true);
  // If end date is same as start (e.g., both 'today'), add one day to include full day
  if (endDate.getTime() === startDate.getTime()) {
    endDate.setDate(endDate.getDate() + 1);
  }
} else {
  // Default: show just the one day (start to start+1)
  endDate = new Date(startDate);
  endDate.setDate(endDate.getDate() + 1);
}

const formatDate = (date) => date.toISOString().split('T')[0];
const fromDate = formatDate(startDate);
const toDate = formatDate(endDate);

// Calculate display info
const daysDiff = Math.ceil((endDate - startDate) / (1000 * 60 * 60 * 24));
const timeframe = daysDiff === 1 
  ? startDate.toLocaleDateString() 
  : `${startDate.toLocaleDateString()} to ${new Date(endDate.getTime() - 1).toLocaleDateString()}`;

try {
  execSync('which gog', { stdio: 'ignore' });
} catch {
  console.error('❌ gogcli is not installed or not in PATH');
  console.error('Install with: brew install steipete/tap/gogcli');
  process.exit(1);
}

const command = `gog calendar events --from ${fromDate} --to ${toDate} --max ${maxValue} --json 2>/dev/null`;

try {
  const output = execSync(command, { encoding: 'utf8' });
  const data = JSON.parse(output);
  
  if (!data.events || data.events.length === 0) {
    console.log(`📅 No events found for ${timeframe}`);
    process.exit(0);
  }
  
  if (useJson) {
    console.log(JSON.stringify(data, null, 2));
    process.exit(0);
  }
  
  // Sort events by start time
  const sortedEvents = data.events.sort((a, b) => {
    const aTime = a.start.dateTime || a.start.date;
    const bTime = b.start.dateTime || b.start.date;
    return new Date(aTime) - new Date(bTime);
  });
  
  console.log(`📅 ${sortedEvents.length} event(s) for ${timeframe}:\n`);
  
  let currentDate = null;
  
  sortedEvents.forEach((event, i) => {
    const isAllDay = !event.start.dateTime;
    const eventDate = isAllDay 
      ? new Date(event.start.date) 
      : new Date(event.start.dateTime);
    
    // Print date header if new day
    const dateStr = eventDate.toLocaleDateString(undefined, { 
      weekday: 'long', 
      month: 'short', 
      day: 'numeric' 
    });
    
    if (dateStr !== currentDate) {
      currentDate = dateStr;
      console.log(`${isAllDay ? '📌' : ''} ${currentDate}`);
      console.log('─'.repeat(40));
    }
    
    // Format time
    let timeStr;
    if (isAllDay) {
      timeStr = '📌 All-day';
    } else {
      const start = new Date(event.start.dateTime);
      const end = new Date(event.end.dateTime);
      const startTime = start.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      const endTime = end.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      timeStr = `${startTime} - ${endTime}`;
    }
    
    // Event status icon
    const statusIcon = event.status === 'confirmed' ? '✓' : '⏳';
    
    console.log(`  ${timeStr.padEnd(15)} │ ${event.summary}`);
    
    if (event.location) {
      console.log(`  ${''.padEnd(15)} │ 📍 ${event.location}`);
    }
    
    if (event.attendees && event.attendees.length > 0) {
      const attendeeStr = event.attendees.map(a => a.email.split('@')[0]).join(', ');
      console.log(`  ${''.padEnd(15)} │ 👥 ${attendeeStr.substring(0, 40)}${attendeeStr.length > 40 ? '...' : ''}`);
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
