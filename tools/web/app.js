:root {
  --bg: #07131f;
  --bg-strong: #0d1c2c;
  --panel: rgba(13, 28, 44, 0.9);
  --panel-border: rgba(80, 220, 255, 0.3);
  --cyan: #69f0ff;
  --teal: #3fe4c2;
  --green: #81f8a9;
  --orange: #ffb454;
  --red: #ff5c6a;
  --text: #edf6ff;
  --muted: #a9bfd6;
  --shadow: 0 12px 35px rgba(8, 25, 38, 0.5);
}

* { box-sizing: border-box; }

html, body {
  margin: 0;
  min-height: 100%;
  font-family: Inter, "Segoe UI", sans-serif;
  background: radial-gradient(circle at top, rgba(64, 199, 255, 0.18), transparent 30%), linear-gradient(135deg, #061018 0%, #0a1728 100%);
  color: var(--text);
}

body {
  display: flex;
  flex-direction: column;
}

.mega-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.1rem 2rem;
  background: rgba(8, 18, 28, 0.92);
  border-bottom: 1px solid var(--panel-border);
  box-shadow: var(--shadow);
  position: sticky;
  top: 0;
  z-index: 10;
  backdrop-filter: blur(8px);
}

.brand {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.brand-mark {
  width: 52px;
  height: 52px;
  display: grid;
  place-items: center;
  border-radius: 14px;
  background: linear-gradient(135deg, #0b2334, #132f43);
  color: var(--cyan);
  font-weight: 800;
  border: 1px solid rgba(105, 240, 255, 0.45);
  box-shadow: 0 0 20px rgba(105, 240, 255, 0.15);
  font-size: 1.2rem;
}

.brand-name {
  font-size: clamp(1.2rem, 2vw, 2rem);
  letter-spacing: 0.08em;
  font-weight: 800;
  background: linear-gradient(90deg, var(--cyan), #89ffc7);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
  text-transform: uppercase;
}

.brand-subtitle {
  font-size: 0.75rem;
  color: var(--muted);
  letter-spacing: 0.12em;
  text-transform: uppercase;
}

.status-strip {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  justify-content: flex-end;
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.55rem;
  padding: 0.55rem 0.9rem;
  border-radius: 999px;
  border: 1px solid rgba(255,255,255,0.08);
  font-size: 0.8rem;
  letter-spacing: 0.04em;
  background: rgba(255,255,255,0.03);
  color: var(--text);
  box-shadow: inset 0 0 0 1px rgba(255,255,255,0.02);
}

.badge.online {
  background: rgba(44, 209, 102, 0.08);
  border-color: rgba(129, 248, 169, 0.25);
  color: var(--green);
}

.badge.neutral {
  background: rgba(105, 240, 255, 0.08);
  border-color: rgba(105, 240, 255, 0.25);
  color: var(--cyan);
}

.dot {
  width: 9px;
  height: 9px;
  display: inline-block;
  border-radius: 50%;
  background: currentColor;
  box-shadow: 0 0 12px currentColor;
}

.content {
  padding: 2rem;
}

.panel {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
  background: var(--panel);
  border: 1px solid var(--panel-border);
  border-radius: 18px;
  box-shadow: var(--shadow);
}

.panel h1 {
  margin-top: 0;
  color: var(--cyan);
}

.panel p {
  color: var(--muted);
  line-height: 1.6;
}

@media (max-width: 760px) {
  .mega-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .status-strip {
    justify-content: flex-start;
  }
}
