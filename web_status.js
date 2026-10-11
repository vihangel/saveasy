(() => {
  let initialVersion;
  const banner = document.getElementById('update');
  document.getElementById('reload').onclick = () => location.reload();
  document.getElementById('dismiss-update').onclick = () => { banner.hidden = true; };
  async function checkVersion() {
    if (document.hidden) return;
    try {
      const url = new URL('version.json', document.baseURI);
      url.searchParams.set('check', Date.now());
      const response = await fetch(url, { cache: 'no-store' });
      if (!response.ok) return;
      const version = await response.json();
      const current = `${version.version}:${version.build_number}`;
      if (initialVersion && initialVersion !== current) banner.hidden = false;
      initialVersion ??= current;
    } catch (_) { /* An offline session remains usable. */ }
  }
  checkVersion();
  setInterval(checkVersion, 5 * 60 * 1000);
})();
