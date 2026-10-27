import type { NevermindExtension, ExtensionContext, ExtensionFile, ExtensionView } from './nevermind-extension-api'
// @ts-ignore Native Node modules are available in Electron; builder omits Node ambient declarations.
import { mkdir, stat, writeFile, rename, unlink } from 'node:fs/promises'
// @ts-ignore Native Node module; no Node ambient declarations in builder.
import { homedir } from 'node:os'
// @ts-ignore Native Node module; no Node ambient declarations in builder.
import { join } from 'node:path'
type RGB = [number,number,number]
type Palette = { tint:RGB; highlight:RGB; monochrome:boolean }
type Snapshot = Record<string,string|null>
type Wallpaper = { id:string; url:string; path:string; resolution:string; dimension_x:number; dimension_y:number; purity:string; file_type:string; file_size:number; favorites:number; thumbs:{large:string} }
type Listing = {data:Wallpaper[];meta:{last_page:number}}
type Browse = {feed:string;query:string;page:number}
const DIR:string=join(homedir(),'.config','wallpapers')
const BACKUP='appearance-original-v1'
const KEYS=['AppleHighlightColor','AppleIconAppearanceTintColor','AppleIconAppearanceCustomTintColor','AppleIconAppearanceTheme']
const FEEDS=[{title:'Top this month',value:'top'},{title:'Nature & landscapes',value:'nature'},{title:'Minimal',value:'minimal'},{title:'Abstract',value:'abstract'},{title:'Top this year',value:'year'}]
const message=(e:unknown)=>e instanceof Error?e.message:String(e)
const isMac=(ctx:ExtensionContext)=>/mac|darwin/i.test(ctx.system.os)
let busy=false
function shellFor(ctx:ExtensionContext){if(!ctx.desktop.shell)throw new Error('Desktop shell access is unavailable.');return ctx.desktop.shell}
async function locked<T>(fn:()=>Promise<T>):Promise<T>{if(busy)throw new Error('Another online wallpaper update is in progress. Please try again shortly.');busy=true;try{return await fn()}finally{busy=false}}
function checkedUrl(value:string,kind:'image'|'thumb'|'page'):string{
 const u=new URL(value),host=kind==='image'?'w.wallhaven.cc':kind==='thumb'?'th.wallhaven.cc':'wallhaven.cc'
 if(u.protocol!=='https:'||u.hostname!==host||u.username||u.password||u.port)throw new Error('Wallhaven returned an unexpected URL.')
 return u.href
}
async function listing(ctx:ExtensionContext,state:Browse):Promise<Listing>{
 return ctx.storage.memo('listing-v1:'+JSON.stringify(state),600000,async()=>{
  const url=new URL('https://wallhaven.cc/api/v1/search')
  const q=state.query||({nature:'nature',minimal:'minimalism',abstract:'abstract'} as Record<string,string>)[state.feed]||''
  const params:Record<string,string>={categories:'100',purity:'100',sorting:state.query?'relevance':'toplist',topRange:state.feed==='year'?'1y':'1M',atleast:'1920x1080',ratios:'16x9,16x10,21x9',order:'desc',page:String(state.page)}
  if(q)params.q=q
  Object.entries(params).forEach(([k,v])=>url.searchParams.set(k,v))
  let response:Response
  try{response=await fetch(url.href,{signal:AbortSignal.timeout(25000)})}catch(e){throw new Error('Cannot reach Wallhaven: '+message(e))}
  if(!response.ok)throw new Error(response.status===429?'Wallhaven rate limit reached. Please wait a minute before trying again.':`Wallhaven returned HTTP ${response.status}. Please try again later.`)
  const body=await response.json() as Listing
  if(!Array.isArray(body.data)||!Number.isInteger(body.meta?.last_page))throw new Error('Wallhaven returned an invalid listing.')
  body.data=body.data.filter(w=>/^[a-z0-9]{6}$/.test(w.id)&&w.purity==='sfw'&&w.dimension_x>=1920&&w.dimension_y>=1080&&w.dimension_x>w.dimension_y&&['image/jpeg','image/png'].includes(w.file_type))
  for(const w of body.data){checkedUrl(w.path,'image');checkedUrl(w.thumbs.large,'thumb');checkedUrl(w.url,'page')}
  return body
 })
}
async function download(ctx:ExtensionContext,w:Wallpaper):Promise<ExtensionFile>{
 const extension=w.file_type==='image/png'?'png':'jpg',path:string=join(DIR,`wallhaven-${w.id}.${extension}`)
 if(!/^[a-z0-9]{6}$/.test(w.id))throw new Error('Invalid wallpaper ID.')
 if(!ctx.desktop.files)throw new Error('File access is unavailable.')
 await mkdir(DIR,{recursive:true})
 try{const info=await stat(path);if(info.isFile()&&info.size>0)return await ctx.desktop.files.metadata(path)}catch(e){if((e as {code?:string}).code!=='ENOENT')throw e}
 const max=60*1024*1024
 if(w.file_size>max)throw new Error('This wallpaper exceeds the 60 MB download limit.')
 const response=await fetch(checkedUrl(w.path,'image'),{signal:AbortSignal.timeout(90000),redirect:'error'})
 if(!response.ok)throw new Error(`Wallpaper download failed (HTTP ${response.status}).`)
 if(!/^image\/(jpeg|png)(;|$)/i.test(response.headers.get('content-type')||''))throw new Error('The download was not a supported image.')
 if(Number(response.headers.get('content-length'))>max||!response.body)throw new Error('Wallpaper download is too large or empty.')
 const reader=response.body.getReader(),chunks:Uint8Array[]=[];let size=0
 try{while(true){const part=await reader.read();if(part.done)break;size+=part.value.length;if(size>max)throw new Error('Wallpaper exceeds the 60 MB download limit.');chunks.push(part.value)}}finally{await reader.cancel()}
 const bytes=new Uint8Array(size);let offset=0
 for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length}
 const png=bytes[0]===137&&bytes[1]===80&&bytes[2]===78&&bytes[3]===71,jpeg=bytes[0]===255&&bytes[1]===216&&bytes[2]===255
 if(!(extension==='png'?png:jpeg))throw new Error('Downloaded image has an unexpected file signature.')
 const temp=path+'.part'
 try{await writeFile(temp,bytes);await rename(temp,path)}catch(e){await unlink(temp).catch(()=>{});throw e}
 return ctx.desktop.files.metadata(path)
}
const SAMPLE_SCRIPT=`ObjC.import('AppKit');
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
function distance(a:RGB,b:RGB){return Math.sqrt(a.reduce((sum,v,i)=>sum+(v-b[i])**2,0))}
function hex(c:RGB){return '#'+c.map(v=>Math.round(v*255).toString(16).padStart(2,'0')).join('')}
function components(c:RGB){return c.map(v=>v.toFixed(6)).join(' ')}
async function extractPalette(ctx:ExtensionContext,file:ExtensionFile):Promise<Palette>{
 return ctx.storage.memo(`palette-v1:${file.path}:${file.mtimeMs}:${file.size}`,86400000,async()=>{
  const res=await shellFor(ctx).exec('/usr/bin/osascript',['-l','JavaScript','-e',SAMPLE_SCRIPT,file.path],{timeout:45000,outputLimit:200000})
  if(res.exitCode!==0)throw new Error('Local palette extraction failed: '+(res.stderr.trim()||res.stdout.trim()))
  const samples:unknown=JSON.parse(res.stdout.trim())
  if(!Array.isArray(samples))throw new Error('Image sampler returned invalid data.')
  const bins=new Map<string,{count:number;sum:RGB}>()
  for(const sample of samples){
   if(!Array.isArray(sample)||sample.length!==3||!sample.every(v=>typeof v==='number'&&Number.isFinite(v)&&v>=0&&v<=1))continue
   const rgb=sample as RGB,key=rgb.map(v=>Math.min(11,Math.floor(v*12))).join(','),bin=bins.get(key)??{count:0,sum:[0,0,0] as RGB}
   bin.count++;rgb.forEach((v,i)=>{bin.sum[i]+=v});bins.set(key,bin)
  }
  const clusters:{rgb:RGB;count:number}[]=[]
  for(const bin of [...bins.values()].sort((a,b)=>b.count-a.count)){
   const rgb=bin.sum.map(v=>v/bin.count) as RGB,nearby=clusters.find(c=>distance(c.rgb,rgb)<0.16)
   if(nearby){nearby.rgb=nearby.rgb.map((v,i)=>(v*nearby.count+rgb[i]*bin.count)/(nearby.count+bin.count)) as RGB;nearby.count+=bin.count}else clusters.push({rgb,count:bin.count})
  }
  clusters.sort((a,b)=>b.count-a.count)
  if(!clusters.length)throw new Error('No opaque colors could be extracted from this image.')
  const usable=clusters.filter(c=>Math.max(...c.rgb)>0.12&&Math.min(...c.rgb)<0.9),candidates=usable.length?usable:clusters
  const first=candidates[0].rgb,second=candidates.find(c=>distance(first,c.rgb)>=0.23)?.rgb??clusters.find(c=>distance(first,c.rgb)>=0.23)?.rgb
  return {tint:first,highlight:(second??first).map(v=>v*0.5+0.5) as RGB,monochrome:!second}
 })
}
function missing(res:{stdout:string;stderr:string},key:string){const text=res.stderr+'\n'+res.stdout;return text.includes(key)&&/does not exist|could not find key|domain\/default pair[^\n]*not found/i.test(text)}
async function readSnapshot(ctx:ExtensionContext,keys:string[]):Promise<Snapshot>{
 const shell=shellFor(ctx),snapshot:Snapshot={}
 for(const key of keys){
  const res=await shell.exec('/usr/bin/defaults',['read','-g',key])
  if(res.exitCode!==0){if(missing(res,key)){snapshot[key]=null;continue}throw new Error(`Cannot read ${key}: ${res.stderr.trim()||res.stdout.trim()}`)}
  const type=await shell.exec('/usr/bin/defaults',['read-type','-g',key])
  if(type.exitCode!==0||!/string/i.test(type.stdout))throw new Error(`Unexpected preference type for ${key}; preferences were not changed.`)
  snapshot[key]=res.stdout.trim()
 }
 return snapshot
}
async function writeSnapshot(ctx:ExtensionContext,snapshot:Snapshot){
 for(const [key,value]of Object.entries(snapshot)){
  if(!KEYS.includes(key))throw new Error('Invalid saved appearance preference.')
  const res=await shellFor(ctx).exec('/usr/bin/defaults',value===null?['delete','-g',key]:['write','-g',key,'-string',value])
  if(res.exitCode!==0&&!(value===null&&missing(res,key)))throw new Error(`Cannot update ${key}: ${res.stderr.trim()||res.stdout.trim()}`)
 }
}
async function applyColors(ctx:ExtensionContext,palette:Palette){
 const version=await shellFor(ctx).exec('/usr/bin/sw_vers',['-productVersion'])
 if(version.exitCode!==0)throw new Error('Cannot determine macOS version.')
 const tahoe=Number(version.stdout.trim().split('.')[0])>=26,values:Snapshot={AppleHighlightColor:components(palette.highlight)}
 if(tahoe)Object.assign(values,{AppleIconAppearanceTintColor:'Other',AppleIconAppearanceCustomTintColor:components(palette.tint)+' 1.0',AppleIconAppearanceTheme:'TintedLight'})
 const before=await readSnapshot(ctx,Object.keys(values)),original=await ctx.storage.get<Snapshot>(BACKUP)
 await ctx.storage.set(BACKUP,{...before,...original})
 try{await writeSnapshot(ctx,values);const check=await readSnapshot(ctx,Object.keys(values));if(Object.keys(values).some(k=>check[k]!==values[k]))throw new Error('macOS did not retain the requested colors.')}
 catch(e){try{await writeSnapshot(ctx,before)}catch(rollback){throw new Error(`${message(e)} Rollback failed: ${message(rollback)}. Use Restore Online Wallpaper Colors.`)}throw e}
 return tahoe?`Light tint ${hex(palette.tint)} · Highlight ${hex(palette.highlight)}`:`Highlight ${hex(palette.highlight)} · Icon tint requires macOS 26+`
}
async function restartDock(ctx:ExtensionContext){
 const res=await shellFor(ctx).exec('/usr/bin/killall',['Dock'],{timeout:10000})
 if(res.exitCode!==0&&!/no matching processes/i.test(res.stderr+res.stdout))throw new Error('Could not restart Dock: '+(res.stderr||res.stdout))
}
async function applyWallpaper(ctx:ExtensionContext,path:string){
 if(!isMac(ctx))throw new Error('This wallpaper setter currently supports macOS only.')
 const escaped=path.replace(/\\/g,'\\\\').replace(/"/g,'\\"');let error=''
 for(const script of [`tell application "System Events" to tell every desktop to set picture to POSIX file "${escaped}"`,`tell application "Finder" to set desktop picture to POSIX file "${escaped}"`]){
  try{const res=await shellFor(ctx).appleScript(script);if(res.exitCode===0)return;error=res.stderr||res.stdout}catch(e){error=message(e)}
 }
 throw new Error(error||'Cannot set wallpaper. Check macOS Automation permissions for Nevermind.')
}
async function useWallpaper(ctx:ExtensionContext,w:Wallpaper,mode:'colors'|'only'|'save'|'palette'){
 return locked(async()=>{
  const id='online-wallpaper'
  ctx.ui.indicator.show({id,title:'Downloading wallpaper…',status:'loading'})
  try{
   const file=await download(ctx,w)
   if(mode==='save'){ctx.ui.indicator.show({id,title:'Wallpaper saved',subtitle:file.path,status:'success',durationMs:4000});return}
   if(mode==='palette'){
    ctx.ui.indicator.update({id,title:'Extracting colors locally…',status:'loading'})
    const p=await extractPalette(ctx,file);ctx.ui.indicator.hide(id)
    return ctx.navigation.push(ctx.ui.preview({title:'Matching Colors',image:ctx.desktop.files!.toFileUrl(file.path),content:`Icon tint: ${hex(p.tint)} (Tinted Light)\nSelection highlight: ${hex(p.highlight)}${p.monochrome?' · Single-color fallback':''}\n\nPreview changes no settings. Applying colors uses the same local extraction as your Wallpapers extension and restarts Dock. System-wide Dark/Light appearance stays unchanged. Icon tint requires macOS 26+ and uses undocumented preferences.`,actions:[ctx.actions.run('Set Wallpaper & Match Colors',c=>useWallpaper(c,w,'colors')),ctx.actions.openUrl(w.url,'View on Wallhaven')]}))
   }
   await applyWallpaper(ctx,file.path)
   if(mode==='only'){ctx.ui.indicator.show({id,title:'Wallpaper updated',subtitle:w.resolution,status:'success',durationMs:3000});return}
   ctx.ui.indicator.update({id,title:'Wallpaper set · Matching colors…',status:'loading'})
   let summary:string
   try{summary=await applyColors(ctx,await extractPalette(ctx,file))}catch(e){throw new Error('Wallpaper was set, but color matching failed: '+message(e))}
   try{await restartDock(ctx)}catch(e){throw new Error('Wallpaper and colors were updated, but '+message(e))}
   ctx.ui.indicator.show({id,title:'Wallpaper and colors updated · Dock refreshed',subtitle:summary,status:'success',durationMs:6000})
  }catch(e){ctx.ui.indicator.hide(id);throw e}
 })
}
function searchPrompt(ctx:ExtensionContext){
 return ctx.input.prompt({title:'Search Online Wallpapers',message:'Landscape wallpapers only · SFW · at least 1920×1080',fields:[{id:'query',label:'Search wallpapers',type:'text',placeholder:'mountains, forest, space…',required:true}],action:ctx.actions.run('Search',async(c,a)=>{
  const query=String(a.formValues?.query||'').trim().slice(0,200)
  if(!query)throw new Error('Enter a search term.')
  return c.navigation.push(await browse(c,{feed:'top',query,page:1}))
 })})
}
async function browse(ctx:ExtensionContext,state:Browse):Promise<ExtensionView>{
 // Match the working local extension's delivery path: resolve data before returning the grid.
 // Browsing fetches thumbnails only, with no full-size downloads or color extraction.
 const result=await listing(ctx,state)
 const navigate=(c:ExtensionContext,s:Browse)=>browse(c,s).then(v=>c.navigation.replace(v))
 const paging=[...(state.page>1?[ctx.actions.run('Previous Page',c=>navigate(c,{...state,page:state.page-1}),{shortcut:'Control+P'})]:[]),...(state.page<result.meta.last_page?[ctx.actions.run('Next Page',c=>navigate(c,{...state,page:state.page+1}),{shortcut:'Control+N'})]:[])]
 const common=[...paging,ctx.actions.ref('search'),ctx.actions.run('Refresh Results',async c=>{await c.storage.delete('listing-v1:'+JSON.stringify(state));return navigate(c,state)}),ctx.actions.run('Open Download Folder',async c=>{await mkdir(DIR,{recursive:true});return c.navigation.run(c.actions.openPath(DIR))}),ctx.actions.ref('restore-colors')]
 return ctx.ui.grid({id:'online-wallpapers-grid',title:state.query?`Wallpapers: ${state.query}`:'Online Wallpapers',subtitle:`Wallhaven · ${state.query?'Search results':FEEDS.find(f=>f.value===state.feed)?.title} · Landscape · 1080p+ · Page ${state.page}/${Math.max(1,result.meta.last_page)}`,size:'large',layout:'wide',aspectRatio:'16/9',columns:3,searchBarPlaceholder:'Filter this page… · Use Search Online Wallpapers for a new search',emptyView:{title:'No matching wallpapers',subtitle:'Try another category or use Search Online Wallpapers.'},searchAccessory:{value:state.query?'search':state.feed,items:[...(state.query?[{title:'Search results',value:'search'}]:[]),...FEEDS],onChange:ctx.actions.run('Change Collection',async(c,a)=>{const feed=String(a.value||a.text||'top');if(feed==='search')return;return navigate(c,{feed,query:'',page:1})})},items:result.data.map(w=>({id:w.id,title:`Wallhaven · ${w.id}`,subtitle:`${w.resolution} · ♥ ${w.favorites}`,image:checkedUrl(w.thumbs.large,'thumb'),keywords:[w.id,w.resolution],primaryAction:ctx.actions.run('Set Wallpaper & Match Colors',c=>useWallpaper(c,w,'colors'),{icon:'image'}),actions:[ctx.actions.run('Set Wallpaper Only',c=>useWallpaper(c,w,'only')),ctx.actions.run('Preview Wallpaper',c=>c.navigation.push(c.ui.preview({title:`Wallhaven · ${w.id}`,image:w.path,content:`${w.resolution} · Full-resolution preview from Wallhaven`,actions:[ctx.actions.run('Set Wallpaper & Match Colors',cc=>useWallpaper(cc,w,'colors')),ctx.actions.run('Set Wallpaper Only',cc=>useWallpaper(cc,w,'only')),ctx.actions.openUrl(w.url,'View on Wallhaven')]}))),ctx.actions.run('Preview Matching Colors',c=>useWallpaper(c,w,'palette')),ctx.actions.run('Download Only',c=>useWallpaper(c,w,'save')),ctx.actions.openUrl(w.url,'View on Wallhaven'),...common]})),actions:common})
}
export default {
 id:'online-wallpapers',title:'Online Wallpapers',subtitle:'Community-ranked landscape wallpapers from Wallhaven · No API key',capabilities:['desktop.files','system'],
 commands:[{id:'browse',title:'Online Wallpapers',subtitle:'Browse top-rated landscape wallpapers · Wallhaven · No account needed',aliases:['wallhaven','online backgrounds','download wallpaper'],icon:'image',async run(ctx){if(!isMac(ctx))throw new Error('This extension currently supports macOS.');return browse(ctx,{feed:'top',query:'',page:1})}}],
 actions(ctx){return [
  {id:'search',title:'Search Online Wallpapers',subtitle:'Search Wallhaven for landscape wallpapers, 1080p+, SFW',icon:'search',action:searchPrompt(ctx)},
  {id:'restore-colors',title:'Restore Online Wallpaper Colors',subtitle:'Restore colors saved before this extension first applied matching colors',icon:'undo-2',run:async c=>locked(async()=>{
   const saved=await c.storage.get<Snapshot>(BACKUP)
   if(!saved)throw new Error('This extension has not saved any previous colors yet. Your local Wallpapers extension keeps its own backup.')
   const before=await readSnapshot(c,Object.keys(saved))
   try{await writeSnapshot(c,saved)}catch(e){try{await writeSnapshot(c,before)}catch(rollback){throw new Error(`${message(e)} Rollback also failed: ${message(rollback)}`)}throw e}
   await c.storage.delete(BACKUP)
   try{await restartDock(c)}catch(e){throw new Error('Previous colors were restored, but '+message(e))}
   c.ui.indicator.show({title:'Previous colors restored · Dock refreshed',status:'success',durationMs:4000})
  })},
 ]},
} satisfies NevermindExtension
