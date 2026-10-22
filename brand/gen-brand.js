// Genera el kit de marca SYNC: marco lima abierto abajo + SY/NC apilado + 7 barras (opción 3)
const fs=require('fs'), path=require('path');
const OUT=process.argv[2]||'/home/claude/repo/brand';
const I='#F5F1E8', P='#542C5F', L='#C7E84B', BG='#0e0d10';
function glyphs(T,R){ const t=T-R, i=R/2, x0=12+i, x1=88-i, y0=10+i, y1=90-i;
  return {
    S:`M${x0} ${y0}H${x1}V${y0+t}H${x0+t}V${50-t/2}H${x1}V${y1}H${x0}V${y1-t}H${x1-t}V${50+t/2}H${x0}Z`,
    Y:`M${8+i} ${y0}H${8+i+t+6}L50 ${y0+t+2}L${92-i-t-6} ${y0}H${92-i}L${50+t/2} 58V${y1}H${50-t/2}V58Z`,
    N:`M${x0} ${y1}V${y0}H${x0+t+2}L${x1-t-2} 50V${y0}H${x1}V${y1}H${x1-t-2}L${x0+t+2} 50V${y1}Z`,
    C:`M${x1} ${y0}V${y0+t}H${x0+t}V${y1-t}H${x1}V${y1}H${x0}V${y0}Z`
  };
}
const G=glyphs(22,6);
const SIZE=256, PAD=24, STEP=108, X=6, S=SIZE-12, R=44, SC=.78;
const arc=(a,b)=>`A${R} ${R} 0 0 1 ${a} ${b}`;
const letter=(k,ink)=>`<path d="${G[k]}" fill="${ink}" stroke="${ink}" stroke-width="6" stroke-linejoin="round"/>`;
function letters(ink,acc){
  const pos={S:[0,0],Y:[STEP,0],N:[0,STEP],C:[STEP,STEP]}; const tx=(SIZE-SIZE*SC)/2;
  return `<g transform="translate(${tx},${tx}) scale(${SC})">`+Object.entries(pos).map(([k,[x,y]])=>`<g transform="translate(${PAD+x},${PAD+y})">${letter(k,ink)}${k==='Y'?`<rect x="39" y="68" width="22" height="22" rx="3" fill="${acc}"/>`:''}</g>`).join('')+`</g>`;
}
const GAP=124, c=SIZE/2;
const framePath=`M${c-GAP/2} ${X+S}H${X+R}${arc(X,X+S-R)}V${X+R}${arc(X+R,X)}H${X+S-R}${arc(X+S,X+R)}V${X+S-R}${arc(X+S-R,X+S)}H${c+GAP/2}`;
const frame=(acc)=>`<path class="frame" d="${framePath}" fill="none" stroke="${acc}" stroke-width="6" stroke-linecap="round"/>`;
// 7 barras: w 9, gap 7, altura máx 34, alturas congeladas
const HS=[.55,1,.7,.9,.5,.8,.65].map(h=>Math.round(34*h));
function bars(acc,{cls='bars'}={}){ const n=7,w=9,g=7,total=n*w+(n-1)*g,x0=c-total/2,base=SIZE-X;
  return `<g class="${cls}">`+HS.map((h,i)=>`<rect class="bar" x="${x0+i*(w+g)}" y="${base-h}" width="${w}" height="${h}" rx="3" fill="${acc}"/>`).join('')+`</g>`;
}
const svgOpen=(w,h,vb)=>`<svg xmlns="http://www.w3.org/2000/svg" viewBox="${vb}" width="${w}" height="${h}">`;
function mark(ink,acc,{bg=null,rx=0}={}){ return svgOpen(256,256,`0 0 ${SIZE} ${SIZE}`)+(bg?`<rect width="${SIZE}" height="${SIZE}" rx="${rx}" fill="${bg}"/>`:'')+frame(acc)+bars(acc)+letters(ink,acc)+`</svg>`; }
// ícono con fondo: marca escalada al 80% dentro de caja ciruela
function icon(size){ const k=.8, t=(SIZE-SIZE*k)/2; return svgOpen(size,size,`0 0 ${SIZE} ${SIZE}`)+`<rect width="${SIZE}" height="${SIZE}" rx="${SIZE*.22}" fill="${P}"/><g transform="translate(${t},${t}) scale(${k})">${frame(L)}${bars(L)}${letters(I,L)}</g></svg>`; }
function wordmark(ink,acc){ let x=0,out=[]; for(const k of "SYNC"){ out.push(`<g transform="translate(${x},0)">${letter(k,ink)}${k==='Y'?`<rect x="39" y="68" width="22" height="22" rx="3" fill="${acc}"/>`:''}</g>`); x+=108; } return svgOpen(x+8,92,`-6 4 ${x+6} 92`)+out.join('')+`</svg>`; }
function lockup(ink,acc,bg=null){ const W=256+40+424+10; return svgOpen(W,256,`0 0 ${W} 256`)+(bg?`<rect width="${W}" height="256" fill="${bg}"/>`:'')+frame(acc)+bars(acc)+letters(ink,acc)+`<g transform="translate(296,82) scale(1)">`+wordmark(ink,acc).replace(/<svg[^>]*>|<\/svg>/g,'').replace(/translate\((\d+),0\)/g,(m,x)=>`translate(${x},0)`)+`</g></svg>`; }
function og(){ const W=1200,H=630; return svgOpen(W,H,`0 0 ${W} ${H}`)+`<rect width="${W}" height="${H}" fill="${BG}"/><g transform="translate(120,187) scale(1)">${frame(L)}${bars(L)}${letters(I,L)}</g><g transform="translate(440,230) scale(0.9)">`+wordmark(I,L).replace(/<svg[^>]*>|<\/svg>/g,'')+`</g><text x="442" y="392" font-family="Space Grotesk, Helvetica, Arial, sans-serif" font-size="30" fill="rgba(245,241,232,.66)">La radio que arma la gente.</text><text x="442" y="432" font-family="Space Grotesk, Helvetica, Arial, sans-serif" font-size="30" fill="rgba(245,241,232,.66)">Votá el próximo tema y escuchá en vivo.</text></svg>`; }
fs.mkdirSync(OUT,{recursive:true});
const files={
  'sync-mark.svg':mark(I,L), 'sync-mark-plum.svg':mark(P,P), 'sync-mark-mono.svg':mark(I,I), 'sync-mark-on-plum.svg':mark(I,L,{bg:P,rx:56}),
  'sync-wordmark.svg':wordmark(I,L), 'sync-wordmark-plum.svg':wordmark(P,L), 'sync-wordmark-mono.svg':wordmark(I,I),
  'sync-lockup.svg':lockup(I,L), 'sync-lockup-plum.svg':lockup(P,L),
  'icon.svg':icon(512), 'favicon.svg':icon(64), 'og.svg':og(),
};
for(const [n,s] of Object.entries(files)) fs.writeFileSync(path.join(OUT,n),s);
// también exporto piezas para incrustar en la app
fs.writeFileSync(path.join(OUT,'_inline.json'),JSON.stringify({framePath,bars:HS,letters:letters('currentColor','var(--acc)'),wordmark:wordmark('currentColor','var(--acc)').replace(/<svg[^>]*>|<\/svg>/g,''),G},null,1));
console.log('ok',Object.keys(files).join(' '));
