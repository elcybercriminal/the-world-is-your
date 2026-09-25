export function cleanUsername(v) { return v.trim().toLowerCase().replace(/^@/, ''); }
export function validUsername(v) { return /^[a-z0-9_\.]{3,24}$/.test(v); }
export function safeUrl(raw) { try { const u=new URL(raw); return u.protocol==='https:' ? u.href : ''; } catch { return ''; } }
// Never execute pasted HTML. Extract a URL then map only known players.
export function parseEmbed(raw) {
 const text=raw.trim(); const match=text.match(/(?:src\s*=\s*["'])(https:\/\/[^"']+)/i)||text.match(/\[url(?:=([^\]]+))?\]([^[]*)/i)||text.match(/\[(?:video|img)\](https:\/\/[^[]+)/i);
 const value=match ? (match[1]||match[2]) : text;
 const href=safeUrl(value?.replace(/&amp;/g,'&')||''); if(!href) throw new Error('Colle une URL HTTPS ou un code iframe contenant une URL HTTPS.');
 const u=new URL(href),host=u.hostname.toLowerCase();
 if(/\.(mp4|webm|m4v)$/i.test(u.pathname)) return {type:'video',url:href};
 if(/\.(jpe?g|png|webp|gif)$/i.test(u.pathname)) return {type:'image',url:href};
 if(['youtube.com','www.youtube.com','m.youtube.com','youtu.be','www.youtube-nocookie.com'].includes(host)) {
 const id=host==='youtu.be'?u.pathname.slice(1):u.searchParams.get('v')||u.pathname.split('/').filter(Boolean).pop();
 if(!/^[\w-]{11}$/.test(id||''))throw new Error('Ce lien YouTube ne contient pas de vidéo valide.');
 return {type:'embed',url:'https://www.youtube-nocookie.com/embed/'+id,poster:'https://i.ytimg.com/vi/'+id+'/hqdefault.jpg'};
 }
 if(['vimeo.com','www.vimeo.com','player.vimeo.com'].includes(host)) { const id=u.pathname.split('/').filter(Boolean).pop(); if(!/^\d+$/.test(id||''))throw new Error('Lien Vimeo invalide.'); return {type:'embed',url:'https://player.vimeo.com/video/'+id}; }
 if(host==='www.dailymotion.com'||host==='dailymotion.com'||host==='dai.ly') { const id=u.pathname.split('/').filter(Boolean).pop()?.split('_')[0];if(!/^[a-zA-Z0-9]+$/.test(id||''))throw new Error('Lien Dailymotion invalide.');return {type:'embed',url:'https://www.dailymotion.com/embed/video/'+id}; }
 throw new Error('Intégration non prise en charge. Utilise YouTube, Vimeo, Dailymotion, ou un lien direct vers une image/vidéo.');
}
export function gestureAxis(dx,dy) { if(Math.max(Math.abs(dx),Math.abs(dy))<10)return null; return Math.abs(dx)>Math.abs(dy)*1.15?'horizontal':'vertical'; }
export function sortPosts(posts,mode) { return [...posts].sort((a,b)=>mode==='popular'? (b.likes.length*2+b.comments.length*3)-(a.likes.length*2+a.comments.length*3)||Date.parse(b.created_at)-Date.parse(a.created_at):Date.parse(b.created_at)-Date.parse(a.created_at)); }
