function getCookie(name){
  const v = document.cookie.match('(^|;)\\s*'+name+'\\s*=\\s*([^;]+)');
  return v ? v.pop() : '';
}

// small helper to render pretty timestamps
function ts(ts){
  try { return new Date(ts).toLocaleString(); } catch(e){ return ts }
}

// fallback simple fetch helpers
async function api(path){
  const r = await fetch(path);
  if (!r.ok) throw new Error('Fetch failed');
  return await r.json();
}

// Expose for console debugging in lab
window.api = api;