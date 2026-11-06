const fs=require('fs'), path=require('path'), {chromium}=require('playwright'), {spawn}=require('child_process');
const W=__dirname, GAP=0.45, FPS=25;
const durs=JSON.parse(fs.readFileSync(`${W}/audio/durs.json`));
const tc=s=>{const [h,m,r]=s.split(':');const [sec,ms]=r.split(',');return +h*3600+ +m*60+ +sec+ +ms/1000;};
let t=0; const scenes=durs.map((d,i)=>{
  const srt=fs.readFileSync(`${W}/audio/${String(i).padStart(2,'0')}.srt`,'utf8').trim().split(/\n\s*\n/);
  const sent=srt.map(b=>{const l=b.split('\n');const [a,c]=l[1].split(' --> ');return [tc(a),tc(c),l.slice(2).join(' ')];});
  const s={kind:d.kind,start:t,len:d.dur+GAP,sent}; t+=s.len; return s;});
const total=t;
(async()=>{
  const mode=process.argv[2]||'preview';
  const b=await chromium.launch(); const p=await b.newPage({viewport:{width:1920,height:1080}});
  await p.addInitScript(`window.TIMELINE=${JSON.stringify({scenes})}`);
  await p.goto('file://'+W+'/video.html'); await p.evaluate(()=>document.fonts.ready);
  if(mode==='preview'){
    fs.mkdirSync(`${W}/prev`,{recursive:true});
    for(const [i,s] of scenes.entries()){ const tt=s.start+Math.min(s.len-0.5, s.sent[s.sent.length-1][0]+2.5);
      await p.evaluate(x=>renderAt(x),tt); await p.screenshot({path:`${W}/prev/${String(i).padStart(2,'0')}-${s.kind}.png`}); }
  } else {
    const n=Math.ceil(total*FPS);
    const ff=spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate',String(FPS),'-c:v','mjpeg','-i','-','-c:v','libx264','-preset','veryfast','-crf','20','-pix_fmt','yuv420p',`${W}/silent.mp4`],{stdio:['pipe','inherit','inherit']});
    for(let f=0;f<n;f++){ await p.evaluate(x=>renderAt(x),f/FPS);
      const buf=await p.screenshot({type:'jpeg',quality:90});
      if(!ff.stdin.write(buf)) await new Promise(r=>ff.stdin.once('drain',r));
      if(f%500===0) console.log('frame',f,'/',n); }
    ff.stdin.end(); await new Promise(r=>ff.on('close',r));
  }
  fs.writeFileSync(`${W}/timeline.json`,JSON.stringify({total,scenes:scenes.map(s=>({kind:s.kind,start:s.start,len:s.len}))}));
  await b.close(); console.log('total',total.toFixed(1));
})();
