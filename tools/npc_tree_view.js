function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
function walkSteps(steps, fn) {
  for (const step of steps) {
    fn(step);
    if (step.kind === 'fork') for (const option of step.options) walkSteps(option.steps, fn);
  }
}
function renderSteps(steps) {
  return steps.map(step => {
    if (step.kind === 'fork') return `<div class="section-label">Choose one response · continuation resumes afterward</div>` + step.options.map((option, i) => `<details style="margin:8px 0 8px 16px;border-left:2px solid var(--fork-color);padding-left:12px"><summary>${i+1}. ${escapeHtml(option.label)}</summary>${renderSteps(option.steps)}</details>`).join('');
    if (step.kind === 'evidence') return `<div class="ev-label">Record evidence: <code>${escapeHtml(step.id)}</code></div>`;
    if (step.kind === 'notebook') return `<p><strong>NOTEBOOK ${escapeHtml(step.id || '(text-derived ID)')}</strong><br>${escapeHtml(step.text).replace(/\n/g,'<br>')}</p>`;
    if (step.kind === 'beat') return `<p><em>[${escapeHtml(step.text)}]</em></p>`;
    return `<p><strong>${escapeHtml(step.speaker)}</strong><br>${escapeHtml(step.text).replace(/\n/g,'<br>')}</p>`;
  }).join('');
}
function showNpc(id) {
  activeNpc = id;
  buildNav(document.getElementById('search').value);
  const npc = NPCS[id], topics = npc.topics;
  const evidence = new Set(); let forks = 0;
  topics.forEach(t => walkSteps(t.steps, s => { if(s.kind==='evidence') evidence.add(s.id); if(s.kind==='fork') forks++; }));
  const detail = document.getElementById('npc-detail');
  detail.innerHTML = `<div class="npc-header"><div class="npc-color-bar" style="background:${npc.color}"></div><div><div class="npc-title">${escapeHtml(npc.label)}</div><div class="npc-meta">Authored location: ${escapeHtml(npc.location)}</div><div class="npc-id">NPC: ${escapeHtml(id)} · Source: ${escapeHtml(npc.source)}</div></div></div>
    <p style="font-size:.8rem;color:var(--text-muted)">Schedule: ${escapeHtml(Object.entries(npc.schedule).map(([k,v])=>k+'='+v).join(', ') || 'No authored schedule; consult story staging.')}</p>
    <p style="font-size:.8rem;color:var(--text-muted)">Exact source order. The first eligible nonempty default wins. Gates below control topics; world access and actor staging are additional checks. Catalog residents disappear at night; core actors have separate staging.</p>
    <div class="stats-bar"><div class="stat"><span class="stat-n">${topics.length}</span>authored blocks</div><div class="stat"><span class="stat-n">${topics.filter(t=>t.steps.length).length}</span>nonempty blocks</div><div class="stat"><span class="stat-n">${forks}</span>forks</div><div class="stat"><span class="stat-n">${evidence.size}</span>distinct authored evidence IDs, including disabled content</div></div>
    <p style="font-size:.8rem;color:var(--text-muted)">Branch evidence belongs only to its chosen path. Completion does not automatically hide a topic; revisits follow its exact gate. This is a source snapshot, not a live availability simulator.</p>
    <div class="topic-tree">${topics.map((t,i)=>{
      const disabled=t.gate_src.trim().toLowerCase()==='never', stub=!t.steps.length;
      return `<div class="topic-node${disabled||stub?' never':''}"><div class="topic-head" onclick="toggleTopic(this)"><span class="toggle-arrow">▶</span><span class="topic-name">${i+1}. ${escapeHtml(t.label || t.id)}</span><span class="pill ${disabled||stub?'pill-never':'pill-gate'}">${stub?'EMPTY / unavailable':disabled?'NEVER / unavailable':t.id==='default'?'automatic default':'menu topic'}</span></div><div class="topic-body"><p><strong>Exact GATE:</strong> <code>${escapeHtml(t.gate_src)}</code></p><p>ID: <code>${escapeHtml(t.id)}</code> · TAG: <code>${escapeHtml(t.tag || '(none)')}</code> · TIME: ${escapeHtml(t.timing || '(default 3 minutes)')}</p>${renderSteps(t.steps)}</div></div>`;
    }).join('')}</div>`;
  document.getElementById('placeholder').style.display='none';
  detail.style.display='block';
}
