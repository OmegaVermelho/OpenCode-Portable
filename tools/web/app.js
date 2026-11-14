(function () {
  function renderStatus(data) {
    const strip = document.querySelector('.status-strip');
    if (!strip) return;

    const badges = strip.querySelectorAll('.badge');
    if (badges.length >= 3) {
      badges[0].textContent = ' MCP: HexStrike ON';
      badges[0].prepend(Object.assign(document.createElement('span'), { className: 'dot' }));
      badges[1].textContent = ' CyberStrike ON';
      badges[1].prepend(Object.assign(document.createElement('span'), { className: 'dot' }));
      badges[2].textContent = ' Model: Fable 5';
      badges[2].prepend(Object.assign(document.createElement('span'), { className: 'dot' }));
    }
  }

  fetch('/api/health', {
    headers: {
      Authorization: 'Bearer ' + (window.__MEGA_TOKEN__ || '')
    }
  })
    .then(async (res) => {
      if (!res.ok) throw new Error('unauthorized');
      const data = await res.json();
      renderStatus(data);
    })
    .catch(() => {
      const strip = document.querySelector('.status-strip');
      if (!strip) return;
      strip.innerHTML = '<span class="badge neutral"><span class="dot"></span> Status: Offline</span>';
    });
})();
