#!/usr/bin/env node
/**
 * Web Reader - Fetch content from URLs
 * Usage: ./fetch.js <url> [output-file]
 */

const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

const url = process.argv[2];
let outputFile = process.argv[3];

if (!url) {
  console.error('Usage: ./fetch.js <url> [output-file]');
  process.exit(1);
}

// Determine protocol
const client = url.startsWith('https:') ? https : http;

const options = {
  headers: {
    'User-Agent': 'Mozilla/5.0 (compatible; Pi-Agent/1.0)'
  }
};

client.get(url, options, (res) => {
  // Handle redirects
  if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
    const redirectUrl = new URL(res.headers.location, url).toString();
    console.log(`Redirecting to: ${redirectUrl}`);
    process.argv[2] = redirectUrl;
    require('child_process').execFileSync(process.argv[0], process.argv.slice(1), { stdio: 'inherit' });
    return;
  }

  if (res.statusCode !== 200) {
    console.error(`Error: HTTP ${res.statusCode}`);
    process.exit(1);
  }

  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    // Detect content type
    const contentType = res.headers['content-type'] || '';
    const isJson = contentType.includes('application/json');
    
    // Auto-generate filename if not provided
    if (!outputFile) {
      if (isJson) {
        outputFile = 'fetched-content.json';
      } else {
        outputFile = 'fetched-content.html';
      }
    }

    // Pretty print JSON
    if (isJson) {
      try {
        const parsed = JSON.parse(data);
        data = JSON.stringify(parsed, null, 2);
      } catch (e) {
        // Not valid JSON, save as-is
      }
    }

    fs.writeFileSync(outputFile, data);
    console.log(`Saved to: ${outputFile}`);
    console.log(`Content-Type: ${contentType}`);
    console.log(`Size: ${data.length} bytes`);
  });
}).on('error', (err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});