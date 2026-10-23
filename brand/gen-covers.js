// Genera portadas SVG por género/subgénero con la identidad SYNC (ciruela / lima / marfil sobre neutro).
// Uso: node gen-covers.js canales.json outdir
const fs=require('fs'), path=require('path');
const [,, jsonPath, outDir]=process.argv;
const chans=JSON.parse(fs.readFileSync(jsonPath,'utf8'));
fs.mkdirSync(outDir,{recursive:true});
const W=900,H=1200;
const P='#542C5F', L='#C7E84B', I='#F5F1E8', BG='#121116', BG2='#1b1a1f', P2='#7a4a8a';
// RNG determinista por slug
function rng(seed){ let h=2166136261; for(const c of seed) h=Math.imul(h^c.charCodeAt(0),16777619); return ()=>{ h+=0x6D2B79F5; let t=Math.imul(h^h>>>15,1|h); t^=t+Math.imul(t^t>>>7,61|t); return ((t^t>>>14)>>>0)/4294967296; }; }
const pick=(r,arr)=>arr[Math.floor(r()*arr.length)];
// ---- motivos por género ----
const M={
  rock(r){ // relámpagos / forma de onda dentada
    let out=''; for(let k=0;k<4;k++){ const y0=200+k*260, pts=[]; let x=-50; while(x<W+50){ pts.push(`${x},${y0+(r()-.5)*220}`); x+=40+r()*60; } out+=`<polyline points="${pts.join(' ')}" fill="none" stroke="${k%2?L:P2}" stroke-width="${k%2?14:34}" stroke-linejoin="round" opacity="${k%2?1:.9}"/>`; } return out; },
  pop(r){ let out=''; for(let k=0;k<14;k++){ const cx=r()*W, cy=r()*H, rad=60+r()*200; out+=`<circle cx="${cx}" cy="${cy}" r="${rad}" fill="${pick(r,[P,P2,L,I])}" opacity="${.15+r()*.5}"/>`; } return out; },
  urbano(r){ let out=''; for(let k=0;k<9;k++){ const x=-200+k*150; out+=`<polygon points="${x},${H} ${x+110},${H} ${x+510},0 ${x+400},0" fill="${k%3===1?L:k%3===2?P:BG2}" opacity="${k%3===0?1:.95}"/>`; } for(let k=0;k<30;k++) out+=`<rect x="${r()*W}" y="${r()*H}" width="${14+r()*30}" height="${14+r()*30}" fill="${I}" opacity="${.2+r()*.5}" transform="rotate(45 ${W/2} ${H/2})"/>`; return out; },
  electronica(r){ let out=''; const s=72; for(let y=s/2;y<H;y+=s) for(let x=s/2;x<W;x+=s){ const d=Math.hypot(x-W/2,y-H/2)/700; const rad=Math.max(2,28*(1-d)+r()*6); out+=`<circle cx="${x}" cy="${y}" r="${rad}" fill="${d<.35?L:d<.7?P2:I}" opacity="${.25+(1-d)*.7}"/>`; } return out; },
  cumbia(r){ let out=''; for(let k=0;k<7;k++){ const y0=100+k*160; let d=`M-50 ${y0}`; for(let x=0;x<=W+50;x+=75) d+=` Q${x+37} ${y0+(k%2?-1:1)*(60+r()*40)} ${x+75} ${y0}`; out+=`<path d="${d}" fill="none" stroke="${pick(r,[L,P,P2,I])}" stroke-width="${18+r()*26}" stroke-linecap="round" opacity=".85"/>`; } return out; },
  folklore(r){ let out=''; const s=120; for(let y=0;y<H+s;y+=s) for(let x=0;x<W+s;x+=s){ const c=((x/s+y/s)%3); out+=`<polygon points="${x},${y-s/2} ${x+s/2},${y} ${x},${y+s/2} ${x-s/2},${y}" fill="${c===0?P:c===1?BG2:L}" opacity="${c===2?.9:1}"/>`; if(c===0) out+=`<polygon points="${x},${y-30} ${x+30},${y} ${x},${y+30} ${x-30},${y}" fill="${I}" opacity=".5"/>`; } return out; },
  tango(r){ let out=''; for(let k=0;k<16;k++){ const x=k*70-200; out+=`<polygon points="${x},0 ${x+34},0 ${x+434},${H} ${x+400},${H}" fill="${k%4===0?L:k%2?P:BG2}"/>`; } let z=`M100 ${H*.62}`; for(let i=0;i<=8;i++) z+=` L${100+i*87} ${H*.62+(i%2?90:-90)}`; out+=`<path d="${z}" fill="none" stroke="${I}" stroke-width="22" stroke-linejoin="round"/>`; return out; },
  latino(r){ let out=`<circle cx="${W/2}" cy="${H*.72}" r="300" fill="${L}"/>`; for(let k=0;k<24;k++){ const a=k*15*Math.PI/180; out+=`<line x1="${W/2+320*Math.cos(a)}" y1="${H*.72+320*Math.sin(a)}" x2="${W/2+620*Math.cos(a)}" y2="${H*.72+620*Math.sin(a)}" stroke="${k%2?P:I}" stroke-width="26" stroke-linecap="round" opacity="${k%2?1:.8}"/>`; } out+=`<rect x="0" y="${H*.72}" width="${W}" height="${H*.28}" fill="${BG}" opacity=".85"/>`; return out; },
  'jazz-blues'(r){ let out=''; for(let k=0;k<9;k++){ const x0=r()*W; out+=`<path d="M${x0} ${H+50} C${x0-300+r()*600} ${H*.7} ${x0+300-r()*600} ${H*.3} ${r()*W} -50" fill="none" stroke="${pick(r,[P2,L,I,P])}" stroke-width="${6+r()*40}" stroke-linecap="round" opacity="${.3+r()*.5}"/>`; } return out; },
  metal(r){ let out=''; for(let k=0;k<11;k++){ const x=k*95-40; const h=300+r()*700; out+=`<polygon points="${x},${H} ${x+47},${H-h} ${x+95},${H}" fill="${k%3===0?L:k%2?P:I}" opacity="${k%2?1:.9}"/>`; } for(let k=0;k<7;k++){ const x=k*150; const h=200+r()*400; out+=`<polygon points="${x},0 ${x+75},${h} ${x+150},0" fill="${BG2}"/>`; } return out; },
  punk(r){ let out=''; for(let k=0;k<7;k++){ const y=r()*H; out+=`<polygon points="0,${y} ${W},${y+(r()-.5)*200} ${W},${y+(r()-.5)*200+80} 0,${y+60}" fill="${pick(r,[L,P,I])}" opacity=".9"/>`; } for(let k=0;k<6;k++){ const x=r()*W,y=r()*H,s=60+r()*80; out+=`<path d="M${x-s} ${y-s}L${x+s} ${y+s}M${x+s} ${y-s}L${x-s} ${y+s}" stroke="${I}" stroke-width="22" stroke-linecap="round"/>`; } return out; },
  'hip-hop'(r){ let out=''; const s=90; for(let y=0;y<H;y+=s) for(let x=0;x<W;x+=s){ if(r()<.45) out+=`<rect x="${x+6}" y="${y+6}" width="${s-12}" height="${s-12}" rx="10" fill="${pick(r,[P,P2,L,BG2,BG2])}"/>`; } return out; },
  'reggae-ska'(r){ let out=''; const bands=[P,L,I,P2,L,P]; const h=H/bands.length; bands.forEach((c,i)=>{ out+=`<rect x="0" y="${i*h}" width="${W}" height="${h+1}" fill="${c}" opacity="${c===I?.85:1}"/>`; }); for(let k=0;k<5;k++) out+=`<rect x="${k*200-50}" y="0" width="60" height="${H}" fill="${BG}" opacity=".55" transform="skewX(-18)"/>`; return out; },
  indie(r){ let out=''; for(let k=0;k<80;k++){ const x=r()*W,y=r()*H,s=12+r()*50; out+=k%3?`<circle cx="${x}" cy="${y}" r="${s/2}" fill="none" stroke="${pick(r,[L,I,P2])}" stroke-width="5" opacity=".8"/>`:`<path d="M${x} ${y-s}L${x+s*.3} ${y-s*.3}L${x+s} ${y}L${x+s*.3} ${y+s*.3}L${x} ${y+s}L${x-s*.3} ${y+s*.3}L${x-s} ${y}L${x-s*.3} ${y-s*.3}Z" fill="${L}"/>`; } return out; },
  clasica(r){ let out=''; for(let k=0;k<5;k++){ const y=200+k*180; out+=`<path d="M-50 ${y} Q${W/2} ${y-140+k*60} ${W+50} ${y}" fill="none" stroke="${I}" stroke-width="3" opacity=".7"/>`; } for(let k=0;k<6;k++){ out+=`<ellipse cx="${150+r()*600}" cy="${220+r()*800}" rx="34" ry="24" fill="${k%2?L:P2}" transform="rotate(-25 ${W/2} ${H/2})"/>`; } out+=`<circle cx="${W*.7}" cy="${H*.3}" r="220" fill="none" stroke="${P}" stroke-width="40" opacity=".9"/>`; return out; },
  'soul-funk'(r){ let out=''; for(let k=0;k<9;k++){ const cx=r()*W, cy=r()*H, rx=120+r()*220, ry=90+r()*200; out+=`<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${pick(r,[P,P2,L])}" opacity="${.5+r()*.4}" transform="rotate(${r()*90} ${cx} ${cy})"/>`; } return out; },
  'country-folk'(r){ let out=''; for(let k=0;k<6;k++){ const y=H*.45+k*110; out+=`<path d="M-50 ${y} Q${W*.3} ${y-60} ${W*.6} ${y} T${W+50} ${y}" fill="${k%2?P:BG2}" opacity="${1-k*.1}"/>`; } out+=`<circle cx="${W*.65}" cy="${H*.3}" r="150" fill="${L}"/>`; for(let k=0;k<9;k++) out+=`<rect x="${k*110}" y="${H*.78}" width="18" height="160" fill="${I}" opacity=".7"/>`; out+=`<rect x="0" y="${H*.82}" width="${W}" height="14" fill="${I}" opacity=".7"/>`; return out; },
  infantil(r){ let out=''; const shapes=['circle','star','heart','tri']; for(let k=0;k<22;k++){ const x=r()*W,y=r()*H,s=30+r()*70,c=pick(r,[L,P2,I,P]); const sh=pick(r,shapes); if(sh==='circle') out+=`<circle cx="${x}" cy="${y}" r="${s}" fill="${c}"/>`; else if(sh==='tri') out+=`<polygon points="${x},${y-s} ${x+s},${y+s} ${x-s},${y+s}" fill="${c}" transform="rotate(${r()*360} ${x} ${y})"/>`; else if(sh==='heart') out+=`<path d="M${x} ${y+s*.9} L${x-s} ${y-s*.1} A${s*.5} ${s*.5} 0 0 1 ${x} ${y-s*.3} A${s*.5} ${s*.5} 0 0 1 ${x+s} ${y-s*.1} Z" fill="${c}"/>`; else out+=`<path d="M${x} ${y-s}L${x+s*.3} ${y-s*.3}L${x+s} ${y-s*.3}L${x+s*.45} ${y+s*.15}L${x+s*.6} ${y+s}L${x} ${y+s*.55}L${x-s*.6} ${y+s}L${x-s*.45} ${y+s*.15}L${x-s} ${y-s*.3}L${x-s*.3} ${y-s*.3}Z" fill="${c}"/>`; } return out; },
  ambient(r){ let out=`<defs><filter id="bl"><feGaussianBlur stdDeviation="60"/></filter></defs>`; for(let k=0;k<6;k++) out+=`<circle cx="${r()*W}" cy="${r()*H}" r="${200+r()*260}" fill="${pick(r,[P,P2,L])}" opacity=".55" filter="url(#bl)"/>`; return out; },
  local(r){ let out=''; for(let k=0;k<4;k++){ const y=H*.55+k*120; out+=`<path d="M-50 ${y} Q${W*.4} ${y-40} ${W*.7} ${y} T${W+50} ${y}" fill="${k%2?BG2:P}" opacity="${1-k*.12}"/>`; } out+=`<circle cx="${W*.5}" cy="${H*.42}" r="170" fill="${L}"/><path d="M${W*.5} ${H*.62} L${W*.5-120} ${H*.42} A120 120 0 1 1 ${W*.5+120} ${H*.42} Z" fill="${I}"/><circle cx="${W*.5}" cy="${H*.42}" r="52" fill="${P}"/>`; return out; },
  sets(r){ let out=''; const n=14, w=W/n; for(let k=0;k<n;k++){ const h=200+r()*800; out+=`<rect x="${k*w+8}" y="${H-h}" width="${w-16}" height="${h}" rx="14" fill="${k%4===1?L:k%2?P:P2}" opacity="${.85+r()*.15}"/>`; } return out; },
};
const fallback=M.pop;
function cover(ch, seed){
  const r=rng(seed); let motif=(M[ch.genero]||fallback)(r);
  const isSub=ch.genero!==ch.slug; const v=isSub?Math.floor(r()*4):0;
  if(isSub){ if(v%2===1) motif=motif.split(L).join('__L__').split(P).join(L).split('__L__').join(P); const tf=v<2?'':v===2?`translate(${W},0) scale(-1,1)`:`translate(0,${H}) scale(1,-1)`; if(tf) motif=`<g transform="${tf}">${motif}</g>`; }
  const letter=(ch.nombre||'?').trim()[0].toUpperCase();
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">
<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${BG}" stop-opacity="0"/><stop offset="1" stop-color="${BG}" stop-opacity=".75"/></linearGradient><filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".9" numOctaves="2" stitchTiles="stitch"/><feColorMatrix values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 .07 0"/></filter></defs>
<rect width="${W}" height="${H}" fill="${BG}"/>
<g opacity=".96">${motif}</g>
<rect width="${W}" height="${H}" fill="url(#g)"/>
<text x="${W-60}" y="${H-70}" text-anchor="end" font-family="Helvetica, Arial, sans-serif" font-weight="800" font-size="420" fill="${I}" opacity=".08" letter-spacing="-20">${letter}</text>
<g transform="translate(60,${H-150}) scale(.32)"><path d="M66 250H50A44 44 0 0 1 6 206V50A44 44 0 0 1 50 6H206A44 44 0 0 1 250 50V206A44 44 0 0 1 206 250H190" fill="none" stroke="${L}" stroke-width="12" stroke-linecap="round"/>${[19,34,24,31,17,27,22].map((h,i)=>`<rect x="${75.5+i*16}" y="${250-h}" width="9" height="${h}" rx="3" fill="${L}"/>`).join('')}</g>
<rect width="${W}" height="${H}" filter="url(#n)" opacity=".5"/>
</svg>`;
}
let n=0;
for(const ch of chans){ fs.writeFileSync(path.join(outDir, ch.slug+'.svg'), cover(ch, ch.slug)); n++; }
console.log('ok', n);
