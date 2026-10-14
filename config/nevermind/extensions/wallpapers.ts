import type { NevermindExtension, ExtensionContext, ExtensionItem, ExtensionFile } from './nevermind-extension-api'
const WALLPAPERS_DIR = '~/.config/wallpapers'
const BACKUP_KEY = 'appearance-original-v1'
const COLOR_KEYS = ['AppleHighlightColor', 'AppleIconAppearanceTintColor', 'AppleIconAppearanceCustomTintColor', 'AppleIconAppearanceTheme']
type RGB = [number, number, number]
type Palette = { tint: RGB; highlight: RGB; monochrome: boolean }
type Snapshot = Record<string, string | null>
let busy = false
const message = (e: unknown) => e instanceof Error ? e.message : String(e)
const isMac = (ctx: ExtensionContext) => /mac|darwin/i.test(ctx.system.os)
// Unset defaults are normal, especially before a custom icon tint has been chosen.
// Recognize only missing-preference diagnostics; keep other failures visible.
function isMissingPreference(result: { stdout: string; stderr: string }, key: string): boolean {
 const diagnostic = result.stderr + '\n' + result.stdout
 return diagnostic.includes(key) && /does not exist|could not find key|domain\/default pair[^\n]*not found/i.test(diagnostic)
}
function shellFor(ctx: ExtensionContext) {
  if (!ctx.desktop.shell) throw new Error('Desktop shell access is unavailable.')
  return ctx.desktop.shell
}
async function locked<T>(fn: () => Promise<T>): Promise<T> {
  if (busy) throw new Error('Another wallpaper or color update is in progress. Please try again shortly.')
  busy = true
  try { return await fn() } finally { busy = false }
}
const SAMPLE_SCRIPT = `ObjC.import('AppKit');
function run(argv) {
 var image = $.NSImage.alloc.initWithContentsOfFile($(argv[0]));
 if (!image || image.isNil()) throw Error('Cannot decode wallpaper image');
 var bitmap = $.NSBitmapImageRep.imageRepWithData(image.TIFFRepresentation);
 if (!bitmap || bitmap.isNil()) throw Error('Cannot sample wallpaper image');
 var w = Number(bitmap.pixelsWide), h = Number(bitmap.pixelsHigh), samples = [];
 if (w < 1 || h < 1) throw Error('Wallpaper has no pixels');
 for (var y=0;y<40;y++) for (var x=0;x<40;x++) {
  var color = bitmap.colorAtXY(Math.min(w-1,Math.floor((x+0.5)*w/40)),Math.min(h-1,Math.floor((y+0.5)*h/40))).colorUsingColorSpace($.NSColorSpace.sRGBColorSpace);
  if (color && !color.isNil() && Number(color.alphaComponent)>0.5) samples.push([Number(color.redComponent),Number(color.greenComponent),Number(color.blueComponent)]);
 }
 return JSON.stringify(samples);
}`
function distance(a: RGB,b: RGB) { return Math.sqrt(a.reduce((sum,v,i)=>sum+(v-b[i])**2,0)) }
function hex(c: RGB) { return '#'+c.map(v=>Math.round(v*255).toString(16).padStart(2,'0')).join('') }
function components(c: RGB) { return c.map(v=>v.toFixed(6)).join(' ') }
async function extractPalette(ctx: ExtensionContext,file: ExtensionFile): Promise<Palette> {
 const metadata = await ctx.desktop.files?.metadata(file.path)
 const key = `palette-v1:${file.path}:${metadata?.mtimeMs ?? file.mtimeMs ?? metadata?.mtime ?? ''}:${metadata?.size ?? file.size ?? ''}`
 return ctx.storage.memo(key,86400000,async()=>{
  const res = await shellFor(ctx).exec('/usr/bin/osascript',['-l','JavaScript','-e',SAMPLE_SCRIPT,file.path],{timeout:45000,outputLimit:200000})
  if(res.exitCode!==0) throw new Error('Local palette extraction failed: '+(res.stderr.trim()||res.stdout.trim()))
  const samples: unknown = JSON.parse(res.stdout.trim())
  if(!Array.isArray(samples)) throw new Error('Image sampler returned invalid data.')
  const bins = new Map<string,{count:number;sum:RGB}>()
  for(const sample of samples) {
   if(!Array.isArray(sample)||sample.length!==3||!sample.every(v=>typeof v==='number'&&Number.isFinite(v)&&v>=0&&v<=1)) continue
   const rgb=sample as RGB, key=rgb.map(v=>Math.min(11,Math.floor(v*12))).join(',')
   const bin=bins.get(key)??{count:0,sum:[0,0,0] as RGB}
   bin.count++;rgb.forEach((v,i)=>{bin.sum[i]+=v});bins.set(key,bin)
  }
  const clusters:{rgb:RGB;count:number}[]=[]
  for(const bin of [...bins.values()].sort((a,b)=>b.count-a.count)) {
   const rgb=bin.sum.map(v=>v/bin.count) as RGB, nearby=clusters.find(c=>distance(c.rgb,rgb)<0.16)
   if(nearby) { nearby.rgb=nearby.rgb.map((v,i)=>(v*nearby.count+rgb[i]*bin.count)/(nearby.count+bin.count)) as RGB;nearby.count+=bin.count }
   else clusters.push({rgb,count:bin.count})
  }
  clusters.sort((a,b)=>b.count-a.count)
  if(!clusters.length) throw new Error('No opaque colors could be extracted from this image.')
  const usable=clusters.filter(c=>Math.max(...c.rgb)>0.12&&Math.min(...c.rgb)<0.9), candidates=usable.length?usable:clusters
  const first=candidates[0].rgb, second=candidates.find(c=>distance(first,c.rgb)>=0.23)?.rgb??clusters.find(c=>distance(first,c.rgb)>=0.23)?.rgb
  return {tint:first,highlight:(second??first).map(v=>v*0.5+0.5) as RGB,monochrome:!second}
 })
}
async function readSnapshot(ctx: ExtensionContext,keys:string[]):Promise<Snapshot> {
 const shell=shellFor(ctx), snapshot:Snapshot={}
 for(const key of keys) {
  const res=await shell.exec('/usr/bin/defaults',['read','-g',key])
  if(res.exitCode!==0) {
   if(isMissingPreference(res,key)){snapshot[key]=null;continue}
   throw new Error(`Cannot read ${key}: ${res.stderr.trim()||res.stdout.trim()}`)
  }
  const type=await shell.exec('/usr/bin/defaults',['read-type','-g',key])
  if(type.exitCode!==0||!/string/i.test(type.stdout)) throw new Error(`Unexpected preference type for ${key}; no color preferences were changed.`)
  snapshot[key]=res.stdout.trim()
 }
 return snapshot
}
async function writeSnapshot(ctx:ExtensionContext,snapshot:Snapshot) {
 for(const [key,value] of Object.entries(snapshot)) {
  if(!COLOR_KEYS.includes(key)) throw new Error('Invalid saved appearance preference.')
  const res=await shellFor(ctx).exec('/usr/bin/defaults',value===null?['delete','-g',key]:['write','-g',key,'-string',value])
  if(res.exitCode!==0&&!(value===null&&isMissingPreference(res,key))) throw new Error(`Cannot update ${key}: ${res.stderr.trim()||res.stdout.trim()}`)
 }
}
async function applyColors(ctx:ExtensionContext,palette:Palette):Promise<string> {
 const version=await shellFor(ctx).exec('/usr/bin/sw_vers',['-productVersion'])
 if(version.exitCode!==0) throw new Error('Cannot determine macOS version; appearance preferences were not changed.')
 const tahoe=Number(version.stdout.trim().split('.')[0])>=26
 const values:Snapshot={AppleHighlightColor:components(palette.highlight)}
 // Light tinted icons only; leave the system-wide Light/Dark appearance untouched.
 if(tahoe) Object.assign(values,{AppleIconAppearanceTintColor:'Other',AppleIconAppearanceCustomTintColor:components(palette.tint)+' 1.0',AppleIconAppearanceTheme:'TintedLight'})
 const before=await readSnapshot(ctx,Object.keys(values)), original=await ctx.storage.get<Snapshot>(BACKUP_KEY)
 await ctx.storage.set(BACKUP_KEY,{...before,...original})
 try {
  await writeSnapshot(ctx,values)
  const check=await readSnapshot(ctx,Object.keys(values))
  if(Object.keys(values).some(key=>check[key]!==values[key])) throw new Error('macOS did not retain the requested color preferences.')
 } catch(e) {
  try {await writeSnapshot(ctx,before)} catch(rollback){throw new Error(`${message(e)} Rollback also failed: ${message(rollback)}. Use Restore Previous Colors.`)}
  throw e
 }
 return tahoe?`Light tint ${hex(palette.tint)} · Highlight ${hex(palette.highlight)}${palette.monochrome?' (single-color fallback)':''}`:`Highlight ${hex(palette.highlight)} · Icon tint requires macOS Tahoe 26+`
}
async function restoreColors(ctx:ExtensionContext) {
 await locked(async()=>{
  const saved=await ctx.storage.get<Snapshot>(BACKUP_KEY)
  if(!saved) throw new Error('No previous colors have been saved yet.')
  const before=await readSnapshot(ctx,Object.keys(saved))
  try {await writeSnapshot(ctx,saved)} catch(e) {
   try {await writeSnapshot(ctx,before)} catch(rollback){throw new Error(`${message(e)} Rollback also failed: ${message(rollback)}`)}
   throw e
  }
  await ctx.storage.delete(BACKUP_KEY)
  ctx.ui.indicator.show({title:'Previous color preferences restored',subtitle:'Reopen apps or log out/in if the appearance has not refreshed.',status:'success',durationMs:6000})
 })
}
const quote=(s:string)=>"'"+s.replace(/'/g,"'\\''")+"'"
async function applyWallpaper(ctx:ExtensionContext,filePath:string):Promise<void> {
 const shell=shellFor(ctx), escaped=filePath.replace(/\\/g,'\\\\').replace(/"/g,'\\"')
 if(ctx.system.os.toLowerCase().includes('linux')) {
  const res=await shell.script(`if command -v gsettings >/dev/null 2>&1; then
   gsettings set org.gnome.desktop.background picture-uri ${quote('file://'+filePath)} && gsettings set org.gnome.desktop.background picture-uri-dark ${quote('file://'+filePath)}
   elif command -v feh >/dev/null 2>&1; then feh --bg-fill ${quote(filePath)}
   elif command -v swww >/dev/null 2>&1; then swww img ${quote(filePath)}
   elif command -v hyprctl >/dev/null 2>&1; then hyprctl hyprpaper wallpaper ${quote(','+filePath)}
   else echo 'No supported wallpaper setter is installed.' >&2; exit 1; fi`)
  if(res.exitCode!==0) throw new Error(res.stderr.trim()||'Failed to set wallpaper on Linux.')
  return
 }
 let lastError=''
 for(const script of [
  `tell application "System Events"\n tell every desktop\n set picture to POSIX file "${escaped}"\n end tell\n end tell`,
  `tell application "System Events" to set picture of every desktop to POSIX file "${escaped}"`,
  `tell application "Finder" to set desktop picture to POSIX file "${escaped}"`,
 ]) {
  try {const res=await shell.appleScript(script);if(res.exitCode===0)return;lastError=res.stderr||res.stdout||lastError} catch(e){lastError=message(e)}
 }
 try {
  const res=await shell.exec('/usr/bin/osascript',['-e',`tell application "System Events" to tell every desktop to set picture to POSIX file "${escaped}"`])
  if(res.exitCode===0)return;lastError=res.stderr||res.stdout||lastError
 } catch(e){lastError=message(e)}
 throw new Error(lastError.trim()||'Could not set wallpaper. Check System Settings > Privacy & Security > Automation permissions.')
}
async function setPicture(ctx:ExtensionContext,file:ExtensionFile,colors:boolean) {
 return locked(async()=>{
  await applyWallpaper(ctx,file.path)
  if(!colors||!isMac(ctx)){ctx.ui.indicator.show({title:'Wallpaper updated',subtitle:file.name,status:'success',durationMs:2000});return}
  ctx.ui.indicator.show({id:'wallpaper-colors',title:'Wallpaper updated · Extracting colors…',status:'loading'})
  let summary: string
  try {
   const palette=await extractPalette(ctx,file)
   summary=await applyColors(ctx,palette)
  } catch(e){ctx.ui.indicator.hide('wallpaper-colors');throw new Error(`Wallpaper was set, but color matching failed: ${message(e)}`)}
  // Refresh only Dock, after color preferences were successfully verified.
  // Do not restart anything when opening the grid, previewing, or setting wallpaper only.
  try {
   const res=await shellFor(ctx).exec('/usr/bin/killall',['Dock'],{timeout:10000})
   if(res.exitCode!==0&&!/no matching processes/i.test(res.stderr+res.stdout)) throw new Error(res.stderr.trim()||res.stdout.trim()||`killall exited with code ${res.exitCode}`)
  } catch(e){ctx.ui.indicator.hide('wallpaper-colors');throw new Error(`Wallpaper and colors were updated, but Dock could not be restarted: ${message(e)}`)}
  ctx.ui.indicator.show({id:'wallpaper-colors',title:'Wallpaper and colors updated · Dock refreshed',subtitle:summary+' · Other apps may still need reopening or logout/login.',status:'success',durationMs:8000})
 })
}
// Resolve the home directory through the documented shell helper, rather than
// depending on Node globals or file-scan tilde expansion in the installed host.
async function wallpaperRoot(ctx:ExtensionContext):Promise<string> {
 const cached=ctx.cache.get<string>('wallpaper-root')
 if(cached)return cached
 const res=await shellFor(ctx).exec('/bin/sh',['-c','printf "%s" "$HOME"'],{timeout:5000})
 const home=res.stdout.trim()
 if(res.exitCode!==0||!home.startsWith('/')) throw new Error('Cannot resolve your home directory for ~/.config/wallpapers.')
 return ctx.cache.set('wallpaper-root',home+'/.config/wallpapers')
}
async function loadWallpapers(ctx:ExtensionContext):Promise<ExtensionItem[]> {
 const filesApi=ctx.desktop.files
 if(!filesApi)throw new Error('File access is unavailable.')
 const root=await wallpaperRoot(ctx), started=Date.now()
 ctx.logs.info('wallpapers.scan.start',{root})
 try {
  const files=await filesApi.findImages([root],{depth:2,limit:300,sortBy:'name',order:'asc',includeDimensions:false})
  ctx.logs.info('wallpapers.scan.complete',{root,count:files.length,durationMs:Date.now()-started})
  return files.map(file=>({
   id:file.path,title:file.name,subtitle:file.displayPath||file.path,image:file.url||filesApi.toFileUrl(file.path),
   primaryAction:ctx.actions.run(isMac(ctx)?'Set Wallpaper & Match Colors':'Set as Wallpaper',c=>setPicture(c,file,true),{icon:'image'}),
   actions:[
    ...(isMac(ctx)?[
     ctx.actions.run('Set Wallpaper Only',c=>setPicture(c,file,false)),
     ctx.actions.run('Preview Matching Colors',async c=>{
      const palette=await extractPalette(c,file)
      return c.navigation.push(c.ui.preview({title:'Wallpaper Palette',image:file.url||filesApi.toFileUrl(file.path),content:`Icon tint (first dominant color, Light style): ${hex(palette.tint)}\nSelection highlight (second color, softened): ${hex(palette.highlight)}\n${palette.monochrome?'Single-color fallback: no sufficiently distinct second color was found.\n':''}Icon tint requires macOS 26+. Changes use undocumented preferences; applying colors selects Tinted Light and automatically restarts Dock without changing system-wide appearance. Some apps need reopening or logout/login. Preview does not change any settings.`}))
     }),ctx.actions.ref('restore-colors'),ctx.actions.ref('refresh-icon-appearance'),
    ]:[]),
    ctx.actions.quickLook(file.path,'Quick Look'),ctx.actions.revealPath(file.path,'Reveal in Finder'),ctx.actions.openPath(file.path,'Open Image'),ctx.actions.copyText(file.path,'Copy Path'),
   ],
  }))
 } catch(e){ctx.logs.error('wallpapers.scan.failed',{root,error:message(e)});throw new Error('Could not load wallpapers: '+message(e))}
}
export default {
 id:'wallpapers',title:'Wallpapers',subtitle:'Desktop background and matching macOS colors',capabilities:['desktop.files','system'],
 actions(ctx) {
  if(!isMac(ctx))return []
  return [
   {id:'restore-colors',title:'Restore Previous Colors',subtitle:'Restore the appearance preferences saved before wallpaper color matching',aliases:['restore wallpaper colors'],icon:'undo-2',run:restoreColors},
   {id:'refresh-icon-appearance',title:'Refresh Wallpaper Icon Appearance',subtitle:'Restart Finder and Dock to reload icon preferences',icon:'refresh-cw',action:ctx.ui.confirm({title:'Restart Finder and Dock?',message:'Finder windows and the Dock may briefly disappear. This may refresh icons; some changes still require logout/login. Other apps will not be restarted.',onConfirm:ctx.actions.run('Restart Finder and Dock',async c=>{
    for(const name of ['Finder','Dock']){const res=await shellFor(c).exec('/usr/bin/killall',[name]);if(res.exitCode!==0&&!/no matching processes/i.test(res.stderr))throw new Error(`Could not restart ${name}: ${res.stderr.trim()}`)}
    c.ui.indicator.show({title:'Finder and Dock restarted',status:'success',durationMs:2500})
   })})},
  ]
 },
 commands:[{
  id:'wallpapers.grid',title:'Set Desktop Wallpaper',subtitle:'Browse ~/.config/wallpapers; match icon tint and selection highlight',icon:'image',aliases:['wallpapers','wallpaper','background','desktop picture'],
  triggers:[{type:'files.changed',roots:WALLPAPERS_DIR,debounceMs:500,kind:'image'}],
  async run(ctx) {
   // Resolve the scan before returning a view: avoid the lazy-loader delivery
   // path that left the reported grid blank. Palette extraction is NOT called.
   const items=await loadWallpapers(ctx)
   ctx.logs.info('wallpapers.grid.ready',{count:items.length})
   return ctx.ui.grid({id:'wallpapers-grid',title:'Wallpapers',subtitle:WALLPAPERS_DIR,layout:'wide',size:'large',searchBarPlaceholder:'Search wallpapers…',
    emptyView:{title:'No Wallpapers Found',subtitle:'Place your image files in ~/.config/wallpapers to get started.'},items,
    refresh:{intervalMs:10000,mode:'replace'},
    actions:isMac(ctx)?[ctx.actions.ref('restore-colors'),ctx.actions.ref('refresh-icon-appearance')]:[],
   })
  },
 }],
} satisfies NevermindExtension
