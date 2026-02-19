#!/usr/bin/env node
/**
 * Web Reader - Extract and read article content from URLs
 * Usage: ./read.js <url> [options]
 * 
 * Options:
 *   --raw          Save raw HTML instead of extracted article
 *   --json         Output as JSON with metadata
 *   --md, --markdown  Force markdown output (default for articles)
 *   -o <file>      Specify output file (default: /tmp)
 *   --stdout       Print to stdout instead of saving to file
 */

import https from 'https';
import http from 'http';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { JSDOM } from 'jsdom';
import { Readability } from '@mozilla/readability';
import TurndownService from 'turndown';

const args = process.argv.slice(2);
const url = args.find(arg => !arg.startsWith('-') && !arg.startsWith('http') === false) || args[0];
const outputFile = args.includes('-o') ? args[args.indexOf('-o') + 1] : null;
const stdoutMode = args.includes('--stdout');
const rawMode = args.includes('--raw');
const jsonMode = args.includes('--json');
const mdMode = args.includes('--md') || args.includes('--markdown');

if (!url || !url.startsWith('http')) {
  console.error('Usage: ./read.js <url> [options]');
  console.error('');
  console.error('Options:');
  console.error('  --raw          Save raw HTML instead of extracted article');
  console.error('  --json         Output as JSON with metadata');
  console.error('  --md           Force markdown output (default for articles)');
  console.error('  -o <file>      Specify output file (default: /tmp)');
  console.error('  --stdout       Print to stdout instead of saving to file');
  console.error('');
  console.error('Examples:');
  console.error('  ./read.js https://example.com/article');
  console.error('  ./read.js https://example.com --raw -o page.html');
  console.error('  ./read.js https://example.com --json');
  console.error('  ./read.js https://example.com --stdout');
  process.exit(1);
}

const turndownService = new TurndownService({
  headingStyle: 'atx',
  codeBlockStyle: 'fenced',
  bulletListMarker: '-'
});

// Clean up markdown - remove excessive newlines
turndownService.addRule('cleanNewlines', {
  filter: () => true,
  replacement: (content) => content.replace(/\n{3,}/g, '\n\n')
});

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https:') ? https : http;
    const options = {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'identity'
      }
    };

    const req = client.get(url, options, (res) => {
      // Handle redirects
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        const redirectUrl = new URL(res.headers.location, url).toString();
        console.log(`🔄 Redirecting to: ${redirectUrl}`);
        fetchUrl(redirectUrl).then(resolve).catch(reject);
        return;
      }

      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }

      const contentType = res.headers['content-type'] || '';
      
      // Handle JSON directly
      if (contentType.includes('application/json')) {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({
              type: 'json',
              data: parsed,
              contentType
            });
          } catch (e) {
            resolve({
              type: 'text',
              data,
              contentType
            });
          }
        });
        return;
      }

      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        resolve({
          type: 'html',
          data,
          contentType,
          finalUrl: url
        });
      });
    });

    req.on('error', reject);
    req.setTimeout(30000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

function extractArticle(html, url) {
  const dom = new JSDOM(html, { url });
  const reader = new Readability(dom.window.document);
  const article = reader.parse();
  
  if (!article) {
    return null;
  }
  
  return article;
}

function generateFilename(title, type) {
  if (outputFile) return outputFile;
  
  const safeTitle = title 
    ? title.toLowerCase().replace(/[^a-z0-9]+/g, '-').substring(0, 50)
    : 'article';
    
  const ext = jsonMode ? 'json' : rawMode ? 'html' : 'md';
  return path.join(os.tmpdir(), `${safeTitle}.${ext}`);
}

async function main() {
  console.log(`📥 Fetching: ${url}`);
  
  try {
    const response = await fetchUrl(url);
    
    if (response.type === 'json') {
      const content = JSON.stringify(response.data, null, 2);
      if (stdoutMode) {
        console.log(content);
      } else {
        const filename = outputFile || path.join(os.tmpdir(), 'data.json');
        fs.writeFileSync(filename, content);
        console.log(`✅ Saved JSON to: ${filename}`);
        console.log(`📊 Size: ${content.length} bytes`);
      }
      return;
    }
    
    const html = response.data;
    
    // Raw mode - just save HTML
    if (rawMode) {
      if (stdoutMode) {
        console.log(html);
      } else {
        const filename = generateFilename(null, 'html');
        fs.writeFileSync(filename, html);
        console.log(`✅ Saved raw HTML to: ${filename}`);
        console.log(`📊 Size: ${html.length} bytes`);
      }
      return;
    }
    
    // Extract article
    console.log('🔍 Extracting article content...');
    const article = extractArticle(html, url);
    
    if (!article) {
      console.log('⚠️  Could not extract article, falling back to raw HTML');
      if (stdoutMode) {
        console.log(html);
      } else {
        const filename = outputFile || path.join(os.tmpdir(), 'page.html');
        fs.writeFileSync(filename, html);
        console.log(`✅ Saved raw HTML to: ${filename}`);
      }
      return;
    }
    
    // Convert to markdown
    const markdown = turndownService.turndown(article.content);
    
    // Build output
    let output;
    if (jsonMode) {
      output = JSON.stringify({
        title: article.title,
        byline: article.byline,
        excerpt: article.excerpt,
        siteName: article.siteName,
        publishedTime: article.publishedTime,
        url: response.finalUrl,
        content: markdown,
        length: article.length,
        readingTime: Math.ceil(article.length / 200) // Approx 200 WPM
      }, null, 2);
    } else {
      const meta = [];
      meta.push(`# ${article.title}`);
      if (article.byline) meta.push(`**By:** ${article.byline}`);
      if (article.siteName) meta.push(`**Source:** ${article.siteName}`);
      if (article.publishedTime) meta.push(`**Published:** ${article.publishedTime}`);
      meta.push(`**URL:** ${response.finalUrl}`);
      if (article.excerpt) meta.push(`\n> ${article.excerpt}`);
      meta.push(`\n---\n`);
      
      output = meta.join('\n') + '\n\n' + markdown;
    }
    
    if (stdoutMode) {
      console.log(output);
    } else {
      const filename = generateFilename(article.title, jsonMode ? 'json' : 'md');
      fs.writeFileSync(filename, output);
      
      console.log(`✅ Saved to: ${filename}`);
      console.log(`📰 Title: ${article.title}`);
      if (article.byline) console.log(`✍️  Author: ${article.byline}`);
      if (article.siteName) console.log(`🏢 Site: ${article.siteName}`);
      console.log(`📊 Length: ${article.length} chars (~${Math.ceil(article.length / 200)} min read)`);
      console.log(`📄 Type: ${jsonMode ? 'JSON' : 'Markdown'}`);
    }
    
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    process.exit(1);
  }
}

main();