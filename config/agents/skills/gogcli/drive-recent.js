#!/usr/bin/env node

/**
 * Helper script to list recent Drive files
 * Usage: node drive-recent.js [--max 10] [--type pdf]
 */

const { execSync } = require('child_process');

const maxFlag = process.argv.includes('--max');
const maxValue = maxFlag ? process.argv[process.argv.indexOf('--max') + 1] : '10';

const typeFlag = process.argv.includes('--type');
const typeValue = typeFlag ? process.argv[process.argv.indexOf('--type') + 1] : null;

// Build query
let query = '';
if (typeValue) {
  const mimeTypes = {
    'pdf': 'application/pdf',
    'doc': 'application/vnd.google-apps.document',
    'sheet': 'application/vnd.google-apps.spreadsheet',
    'slide': 'application/vnd.google-apps.presentation',
    'folder': 'application/vnd.google-apps.folder'
  };
  const mimeType = mimeTypes[typeValue] || typeValue;
  query = `--query "mimeType='${mimeType}'"`;
}

try {
  // Check if gog is installed
  execSync('which gog', { stdio: 'ignore' });
} catch {
  console.error('❌ gogcli is not installed or not in PATH');
  console.error('Install with: brew install steipete/tap/gogcli');
  process.exit(1);
}

// Run the drive command with JSON output
const command = `gog drive ls --max ${maxValue} ${query} --json 2>/dev/null`;

try {
  const output = execSync(command, { encoding: 'utf8' });
  const data = JSON.parse(output);
  
  if (!data.files || data.files.length === 0) {
    console.log('📁 No files found');
    process.exit(0);
  }
  
  console.log(`📁 ${data.files.length} file(s):\n`);
  
  data.files.forEach((file, i) => {
    const date = new Date(file.modifiedTime).toLocaleDateString();
    const icon = getIcon(file.mimeType);
    const size = file.size ? formatBytes(file.size) : '-';
    
    console.log(` ${i + 1}. ${icon} ${file.name}`);
    console.log(`    Modified: ${date} | Size: ${size}`);
    console.log(`    ID: ${file.id}`);
    console.log();
  });
  
} catch (error) {
  console.error('❌ Error fetching Drive files:', error.message);
  console.error('\nMake sure you have:');
  console.error('  1. gogcli installed: brew install steipete/tap/gogcli');
  console.error('  2. Authenticated: gog auth add your.email@gmail.com');
  console.error('  3. Set default account: export GOG_ACCOUNT=your.email@gmail.com');
  process.exit(1);
}

function getIcon(mimeType) {
  if (mimeType === 'application/vnd.google-apps.folder') return '📂';
  if (mimeType.includes('pdf')) return '📄';
  if (mimeType.includes('document')) return '📝';
  if (mimeType.includes('spreadsheet')) return '📊';
  if (mimeType.includes('presentation')) return '📽️';
  if (mimeType.includes('image')) return '🖼️';
  if (mimeType.includes('video')) return '🎬';
  if (mimeType.includes('audio')) return '🎵';
  return '📎';
}

function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}
