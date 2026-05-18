/* Eleutheria Editor — Vanilla JS, no framework.
   Loaded from serve.py at http://localhost:8765/.

   State of truth in memory:
     state.questions, state.philosophers
     state.dirtyQuestions, state.dirtyPhilosophers
     state.activeView ∈ { 'questions', 'philosophers' }
*/

(() => {
  'use strict';

  // ─── Constants ────────────────────────────────────────────────────────────

  const CATEGORIES = {
    quoteToPhilosopher: 'Zitat → Philosoph',
    workToAuthor:       'Werk → Autor',
    philosopherToEra:   'Philosoph → Epoche',
    conceptToSchool:    'Begriff → Schule',
    completeQuote:      'Zitat vervollständigen',
    whoCriticizedWhom:  'Kritik & Streit',
  };

  const ID_PREFIX = {
    quoteToPhilosopher: 'q_quote_',
    workToAuthor:       'q_work_',
    philosopherToEra:   'q_era_',
    conceptToSchool:    'q_concept_',
    completeQuote:      'q_complete_',
    whoCriticizedWhom:  'q_critique_',
  };

  const ERAS = {
    antike:             'Antike',
    mittelalter:        'Mittelalter',
    renaissance:        'Renaissance',
    aufklaerung:        'Aufklärung',
    neunzehntes:        '19. Jahrhundert',
    modernePostmoderne: 'Moderne / Postmoderne',
    zeitgenoessisch:    'Zeitgenössisch',
  };

  const initialQuestions    = (window.ELEUTHERIA_QUESTIONS || { questions: [] }).questions || [];
  const initialPhilosophers = window.ELEUTHERIA_PHILOSOPHERS || [];

  const state = {
    questions:        structuredClone(initialQuestions),
    philosophers:     structuredClone(initialPhilosophers),
    dirtyQuestions:   false,
    dirtyPhilosophers: false,
    activeView:       'questions',
    editingQId:       null,
    editingPId:       null,
    filters: {
      q: {
        search: '',
        category: '',
        difficulties: new Set([1, 2, 3, 4, 5]),
        philosopher: '',
      },
      p: {
        search: '',
        era: '',
      },
    },
  };

  function philById() {
    return Object.fromEntries(state.philosophers.map(p => [p.id, p]));
  }

  function questionsByPhilosopher() {
    const out = Object.create(null);
    for (const q of state.questions) {
      if (!q.philosopherId) continue;
      out[q.philosopherId] = (out[q.philosopherId] || 0) + 1;
    }
    return out;
  }

  // ─── DOM helpers ──────────────────────────────────────────────────────────

  const $  = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#039;');
  }

  function showToast(msg, kind) {
    const t = $('#toast');
    t.textContent = msg;
    t.className = 'toast ' + (kind || '');
    t.classList.remove('hidden');
    clearTimeout(showToast._t);
    showToast._t = setTimeout(() => t.classList.add('hidden'), 3000);
  }

  function refreshDirty() {
    const dirty = state.dirtyQuestions || state.dirtyPhilosophers;
    $('#dirty-pill').classList.toggle('hidden', !dirty);
  }

  function refreshCount() {
    const n = state.activeView === 'questions'
      ? state.questions.length
      : state.philosophers.length;
    const label = state.activeView === 'questions' ? 'Fragen' : 'Philosophen';
    $('#count-pill').textContent = `${n} ${label}`;
  }

  // ─── Combobox component ───────────────────────────────────────────────────

  class Combobox {
    constructor(container, { options, placeholder, onChange, allowEmpty = true }) {
      this.container = container;
      this.options = options.slice();
      this.placeholder = placeholder || 'Wählen …';
      this.onChange = onChange || (() => {});
      this.allowEmpty = allowEmpty;
      this.value = null;
      this.focusedIndex = -1;
      this._build();
    }

    _build() {
      this.container.classList.add('combobox');
      this.container.innerHTML = `
        <input type="text" class="cb-input" placeholder="${escapeHtml(this.placeholder)}" autocomplete="off">
        <button class="cb-clear" type="button" tabindex="-1" title="Auswahl löschen">×</button>
        <div class="cb-dropdown" role="listbox"></div>
      `;
      this.input    = this.container.querySelector('.cb-input');
      this.dropdown = this.container.querySelector('.cb-dropdown');
      this.clearBtn = this.container.querySelector('.cb-clear');

      this.input.addEventListener('focus', () => this._open());
      this.input.addEventListener('input', () => this._filter());
      this.input.addEventListener('keydown', (e) => this._onKey(e));
      this.clearBtn.addEventListener('click', () => this._clear());

      // Hide on outside click
      document.addEventListener('mousedown', (e) => {
        if (!this.container.contains(e.target)) this._close();
      });
    }

    setOptions(opts) {
      this.options = opts.slice();
      this._renderList(this.options);
    }

    setValue(id) {
      if (!id) {
        this.value = null;
        this.input.value = '';
        this.container.classList.remove('has-value');
        return;
      }
      const opt = this.options.find(o => o.value === id);
      if (!opt) {
        this.value = id;
        this.input.value = id;
      } else {
        this.value = id;
        this.input.value = opt.label;
      }
      this.container.classList.add('has-value');
    }

    getValue() { return this.value; }

    _open() {
      this.container.classList.add('open');
      this._filter();
    }

    _close() {
      this.container.classList.remove('open');
      // Restore visible text to selected option's label (input may show stale filter).
      if (this.value) {
        const opt = this.options.find(o => o.value === this.value);
        this.input.value = opt ? opt.label : this.value;
      } else {
        this.input.value = '';
      }
      this.focusedIndex = -1;
    }

    _clear() {
      this.setValue(null);
      this.onChange(null);
      this._close();
    }

    _filter() {
      const q = this.input.value.trim().toLowerCase();
      const filtered = q
        ? this.options.filter(o =>
            o.label.toLowerCase().includes(q) ||
            (o.sub || '').toLowerCase().includes(q) ||
            o.value.toLowerCase().includes(q),
          )
        : this.options;
      this._renderList(filtered);
      this.focusedIndex = filtered.length ? 0 : -1;
      this._highlight();
    }

    _renderList(opts) {
      if (!opts.length) {
        this.dropdown.innerHTML = `<div class="cb-empty">keine Treffer</div>`;
        return;
      }
      this.dropdown.innerHTML = opts.map((o, i) => `
        <div class="cb-option" data-i="${i}" data-value="${escapeHtml(o.value)}">
          ${escapeHtml(o.label)}
          ${o.sub ? `<span class="cb-sub">${escapeHtml(o.sub)}</span>` : ''}
        </div>
      `).join('');
      // Bind click
      this.dropdown.querySelectorAll('.cb-option').forEach(el => {
        el.addEventListener('mousedown', (e) => {
          e.preventDefault();
          this._pick(el.dataset.value);
        });
      });
      this._currentFiltered = opts;
    }

    _highlight() {
      const items = this.dropdown.querySelectorAll('.cb-option');
      items.forEach((el, i) => {
        el.classList.toggle('focused', i === this.focusedIndex);
      });
      const target = items[this.focusedIndex];
      if (target) target.scrollIntoView({ block: 'nearest' });
    }

    _onKey(e) {
      if (!this.container.classList.contains('open')) {
        if (['ArrowDown', 'ArrowUp', 'Enter'].includes(e.key)) {
          this._open();
          e.preventDefault();
        }
        return;
      }
      if (e.key === 'ArrowDown') {
        this.focusedIndex = Math.min(this.focusedIndex + 1, (this._currentFiltered || []).length - 1);
        this._highlight();
        e.preventDefault();
      } else if (e.key === 'ArrowUp') {
        this.focusedIndex = Math.max(this.focusedIndex - 1, 0);
        this._highlight();
        e.preventDefault();
      } else if (e.key === 'Enter') {
        const opt = (this._currentFiltered || [])[this.focusedIndex];
        if (opt) this._pick(opt.value);
        e.preventDefault();
      } else if (e.key === 'Escape') {
        this._close();
        e.preventDefault();
      }
    }

    _pick(value) {
      this.setValue(value);
      this.onChange(value);
      this._close();
    }
  }

  // Lazily-attached combobox instances.
  const comboboxes = {};

  function buildPhilosopherCombobox(container, onChange, { withEmpty = true } = {}) {
    const opts = [
      ...(withEmpty ? [{ value: '', label: '— keiner —' }] : []),
      ...state.philosophers
        .slice()
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(p => ({
          value: p.id,
          label: p.name,
          sub: [p.years, ERAS[p.era] || p.era].filter(Boolean).join(' · '),
        })),
    ];
    return new Combobox(container, {
      options: opts,
      placeholder: 'Philosoph suchen …',
      onChange,
    });
  }

  // ─── Tab switching ────────────────────────────────────────────────────────

  function switchView(view) {
    state.activeView = view;
    $$('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === view));
    $('#view-questions').classList.toggle('hidden', view !== 'questions');
    $('#view-philosophers').classList.toggle('hidden', view !== 'philosophers');
    refreshCount();
    if (view === 'questions') renderQuestionTable();
    else                       renderPhilosopherTable();
  }

  // ─── Questions: filter + render ───────────────────────────────────────────

  function applyQuestionFilters() {
    const { search, category, difficulties, philosopher } = state.filters.q;
    const needle = search.trim().toLowerCase();
    return state.questions.filter(q => {
      if (category && q.category !== category) return false;
      if (!difficulties.has(q.difficulty)) return false;
      if (philosopher && q.philosopherId !== philosopher) return false;
      if (needle) {
        const haystack = (
          q.id + ' ' + (q.prompt || '') + ' ' +
          (q.options || []).join(' ') + ' ' +
          (q.attribution || '') + ' ' +
          (q.explanation || '')
        ).toLowerCase();
        if (!haystack.includes(needle)) return false;
      }
      return true;
    });
  }

  function renderQuestionTable() {
    const rows = applyQuestionFilters();
    const body = $('#qtbody');
    const lookup = philById();
    body.innerHTML = rows.map(q => {
      const phil = q.philosopherId ? (lookup[q.philosopherId]?.name || q.philosopherId) : '—';
      return `
        <tr data-id="${escapeHtml(q.id)}">
          <td class="mono">${escapeHtml(q.id)}</td>
          <td><span class="cat-chip">${escapeHtml(CATEGORIES[q.category] || q.category)}</span></td>
          <td><div class="truncate">${escapeHtml(q.prompt || '')}</div></td>
          <td>${escapeHtml((q.options || [])[q.correctIndex] || '')}</td>
          <td class="num">${q.difficulty}</td>
          <td>${escapeHtml(phil)}</td>
        </tr>`;
    }).join('');
    body.querySelectorAll('tr').forEach(tr => {
      tr.addEventListener('click', () => openQuestionDrawer(tr.dataset.id));
    });
    $('#stats').textContent = `${rows.length} sichtbar von ${state.questions.length}`;
  }

  // ─── Questions: drawer ────────────────────────────────────────────────────

  function nextQuestionId(category) {
    const prefix = ID_PREFIX[category] || 'q_';
    let max = 0;
    for (const q of state.questions) {
      if (typeof q.id !== 'string' || !q.id.startsWith(prefix)) continue;
      const n = parseInt(q.id.slice(prefix.length), 10);
      if (Number.isFinite(n) && n > max) max = n;
    }
    return prefix + String(max + 1).padStart(3, '0');
  }

  function openQuestionDrawer(id) {
    const drawer = $('#drawer');
    drawer.classList.remove('hidden');
    $('#form-issues').textContent = '';
    if (id === null) {
      state.editingQId = null;
      const cat = state.filters.q.category || 'quoteToPhilosopher';
      $('#drawer-title').textContent = 'Neue Frage';
      $('#f-id').value = nextQuestionId(cat);
      $('#f-category').value = cat;
      $('#f-prompt').value = '';
      for (let i = 0; i < 4; i++) $('#f-opt-' + i).value = '';
      document.querySelector('input[name="correct"][value="0"]').checked = true;
      $('#f-difficulty').value = '2';
      $('#f-attribution').value = '';
      $('#f-explanation').value = '';
      comboboxes.qDrawerPhil.setValue('');
      $('#f-topic-key').value = '';
      $('#delete-btn').classList.add('hidden');
      return;
    }
    const q = state.questions.find(x => x.id === id);
    if (!q) return;
    state.editingQId = id;
    $('#drawer-title').textContent = q.id;
    $('#f-id').value = q.id;
    $('#f-category').value = q.category;
    $('#f-prompt').value = q.prompt || '';
    for (let i = 0; i < 4; i++) $('#f-opt-' + i).value = (q.options || [])[i] || '';
    const r = document.querySelector(`input[name="correct"][value="${q.correctIndex || 0}"]`);
    if (r) r.checked = true;
    $('#f-difficulty').value = String(q.difficulty || 2);
    $('#f-attribution').value = q.attribution || '';
    $('#f-explanation').value = q.explanation || '';
    comboboxes.qDrawerPhil.setValue(q.philosopherId || '');
    $('#f-topic-key').value = q.topicKey || '';
    $('#delete-btn').classList.remove('hidden');
  }

  function closeQuestionDrawer() {
    $('#drawer').classList.add('hidden');
    state.editingQId = null;
  }

  function gatherQuestionForm() {
    const r = document.querySelector('input[name="correct"]:checked');
    return {
      id:           $('#f-id').value.trim(),
      category:     $('#f-category').value,
      prompt:       $('#f-prompt').value.trim(),
      options: [
        $('#f-opt-0').value.trim(),
        $('#f-opt-1').value.trim(),
        $('#f-opt-2').value.trim(),
        $('#f-opt-3').value.trim(),
      ],
      correctIndex: r ? parseInt(r.value, 10) : 0,
      difficulty:   parseInt($('#f-difficulty').value, 10),
      attribution:  $('#f-attribution').value.trim() || null,
      explanation:  $('#f-explanation').value.trim() || null,
      philosopherId: comboboxes.qDrawerPhil.getValue() || null,
      topicKey:     $('#f-topic-key').value.trim() || null,
    };
  }

  function validateQuestion(q, { ignoreIdOf = null } = {}) {
    const issues = [];
    if (!q.id) issues.push('• ID darf nicht leer sein.');
    if (q.id && q.id !== ignoreIdOf && state.questions.some(x => x.id === q.id)) {
      issues.push('• ID ist schon vergeben.');
    }
    if (!CATEGORIES[q.category]) issues.push('• Kategorie ungültig.');
    if (!q.prompt) issues.push('• Prompt darf nicht leer sein.');
    if (!q.options || q.options.length !== 4 || q.options.some(o => !o)) {
      issues.push('• Es müssen genau 4 nicht-leere Antworten gesetzt sein.');
    }
    if (q.correctIndex < 0 || q.correctIndex > 3) {
      issues.push('• correctIndex muss 0..3 sein.');
    }
    if (q.difficulty < 1 || q.difficulty > 5) {
      issues.push('• Schwierigkeit muss 1..5 sein.');
    }
    if (q.philosopherId && !philById()[q.philosopherId]) {
      issues.push(`• Unbekannte philosopherId "${q.philosopherId}".`);
    }
    if (q.topicKey) {
      const sameKey = state.questions.filter(
        x => x.topicKey === q.topicKey && x.id !== (ignoreIdOf ?? q.id),
      );
      if (sameKey.length > 1) {
        issues.push(`• Topic-Key "${q.topicKey}" gibt es bereits ${sameKey.length}× — gewollt?`);
      }
    }
    return issues;
  }

  function applyQuestionDrawer() {
    const q = gatherQuestionForm();
    const issues = validateQuestion(q, { ignoreIdOf: state.editingQId });
    if (issues.length) { $('#form-issues').textContent = issues.join('\n'); return; }
    if (state.editingQId) {
      const i = state.questions.findIndex(x => x.id === state.editingQId);
      if (i >= 0) state.questions[i] = q;
    } else {
      state.questions.push(q);
    }
    state.dirtyQuestions = true;
    refreshDirty(); refreshCount(); renderQuestionTable(); closeQuestionDrawer();
    showToast('Übernommen — Speichern nicht vergessen.', 'ok');
  }

  function deleteCurrentQuestion() {
    if (!state.editingQId) return;
    if (!confirm(`Frage ${state.editingQId} wirklich löschen?`)) return;
    state.questions = state.questions.filter(q => q.id !== state.editingQId);
    state.dirtyQuestions = true;
    refreshDirty(); refreshCount(); renderQuestionTable(); closeQuestionDrawer();
    showToast('Gelöscht.', 'ok');
  }

  // ─── Philosophers: filter + render ────────────────────────────────────────

  function applyPhilosopherFilters() {
    const { search, era } = state.filters.p;
    const needle = search.trim().toLowerCase();
    return state.philosophers.filter(p => {
      if (era && p.era !== era) return false;
      if (needle) {
        const hay = (
          p.id + ' ' + (p.name || '') + ' ' + (p.school || '') + ' ' +
          (p.tagline || '') + ' ' + (p.years || '') + ' ' +
          (p.aliases || []).join(' ')
        ).toLowerCase();
        if (!hay.includes(needle)) return false;
      }
      return true;
    });
  }

  function renderPhilosopherTable() {
    const rows = applyPhilosopherFilters();
    const body = $('#ptbody');
    const counts = questionsByPhilosopher();
    body.innerHTML = rows.map(p => `
      <tr data-id="${escapeHtml(p.id)}">
        <td class="mono">${escapeHtml(p.id)}</td>
        <td>${escapeHtml(p.name)}</td>
        <td>${escapeHtml(p.years || '')}</td>
        <td>${escapeHtml(ERAS[p.era] || p.era || '')}</td>
        <td>${escapeHtml(p.school || '')}</td>
        <td class="num">${counts[p.id] || 0}</td>
      </tr>`).join('');
    body.querySelectorAll('tr').forEach(tr => {
      tr.addEventListener('click', () => openPhilosopherDrawer(tr.dataset.id));
    });
    $('#p-stats').textContent = `${rows.length} sichtbar von ${state.philosophers.length}`;
  }

  // ─── Philosophers: drawer ─────────────────────────────────────────────────

  function openPhilosopherDrawer(id) {
    const drawer = $('#p-drawer');
    drawer.classList.remove('hidden');
    $('#p-form-issues').textContent = '';
    if (id === null) {
      state.editingPId = null;
      $('#p-drawer-title').textContent = 'Neuer Philosoph';
      $('#pf-id').value = '';
      $('#pf-name').value = '';
      $('#pf-years').value = '';
      $('#pf-era').value = 'antike';
      $('#pf-school').value = '';
      $('#pf-tagline').value = '';
      $('#pf-image').value = '';
      $('#pf-aliases').value = '';
      $('#p-delete-btn').classList.add('hidden');
      return;
    }
    const p = state.philosophers.find(x => x.id === id);
    if (!p) return;
    state.editingPId = id;
    $('#p-drawer-title').textContent = p.name;
    $('#pf-id').value = p.id;
    $('#pf-name').value = p.name || '';
    $('#pf-years').value = p.years || '';
    $('#pf-era').value = p.era || 'antike';
    $('#pf-school').value = p.school || '';
    $('#pf-tagline').value = p.tagline || '';
    $('#pf-image').value = p.imageAsset || '';
    $('#pf-aliases').value = (p.aliases || []).join(', ');
    $('#p-delete-btn').classList.remove('hidden');
  }

  function closePhilosopherDrawer() {
    $('#p-drawer').classList.add('hidden');
    state.editingPId = null;
  }

  function gatherPhilosopherForm() {
    const aliases = $('#pf-aliases').value
      .split(',').map(s => s.trim()).filter(Boolean);
    const id = $('#pf-id').value.trim();
    return {
      id,
      name:       $('#pf-name').value.trim(),
      years:      $('#pf-years').value.trim(),
      era:        $('#pf-era').value,
      school:     $('#pf-school').value.trim(),
      tagline:    $('#pf-tagline').value.trim(),
      imageAsset: $('#pf-image').value.trim() || (id ? `assets/images/philosophers/${id}.webp` : ''),
      aliases,
    };
  }

  function validatePhilosopher(p, { ignoreIdOf = null } = {}) {
    const issues = [];
    if (!p.id) issues.push('• ID darf nicht leer sein.');
    if (p.id && !/^[a-z][a-z0-9_]*$/.test(p.id)) {
      issues.push('• ID muss kebab-/snake-case sein: [a-z][a-z0-9_]*.');
    }
    if (p.id && p.id !== ignoreIdOf && state.philosophers.some(x => x.id === p.id)) {
      issues.push('• ID ist schon vergeben.');
    }
    if (!p.name) issues.push('• Name darf nicht leer sein.');
    if (!Object.keys(ERAS).includes(p.era)) issues.push('• Epoche ungültig.');
    return issues;
  }

  function applyPhilosopherDrawer() {
    const p = gatherPhilosopherForm();
    const issues = validatePhilosopher(p, { ignoreIdOf: state.editingPId });
    if (issues.length) { $('#p-form-issues').textContent = issues.join('\n'); return; }
    if (state.editingPId) {
      const i = state.philosophers.findIndex(x => x.id === state.editingPId);
      if (i >= 0) state.philosophers[i] = p;
    } else {
      state.philosophers.push(p);
    }
    state.dirtyPhilosophers = true;
    refreshDirty(); refreshCount();
    renderPhilosopherTable();
    rebuildPhilosopherComboboxes();
    closePhilosopherDrawer();
    showToast('Übernommen — Speichern nicht vergessen.', 'ok');
  }

  function deleteCurrentPhilosopher() {
    if (!state.editingPId) return;
    const referenced = state.questions.filter(q => q.philosopherId === state.editingPId);
    let msg = `Philosoph ${state.editingPId} wirklich löschen?`;
    if (referenced.length) {
      msg += `\nAchtung: ${referenced.length} Frage(n) referenzieren diese ID. ` +
             `Sie behalten die ID aber zeigen "Unbekannt" bis du sie korrigierst.`;
    }
    if (!confirm(msg)) return;
    state.philosophers = state.philosophers.filter(p => p.id !== state.editingPId);
    state.dirtyPhilosophers = true;
    refreshDirty(); refreshCount();
    renderPhilosopherTable();
    rebuildPhilosopherComboboxes();
    closePhilosopherDrawer();
    showToast('Gelöscht.', 'ok');
  }

  function rebuildPhilosopherComboboxes() {
    // Re-build options in every philosopher-combobox while keeping current value.
    for (const key of ['qFilterPhil', 'qDrawerPhil']) {
      const cb = comboboxes[key];
      if (!cb) continue;
      const prev = cb.getValue();
      const sorted = state.philosophers
        .slice()
        .sort((a, b) => a.name.localeCompare(b.name));
      cb.setOptions([
        { value: '', label: '— keiner —' },
        ...sorted.map(p => ({
          value: p.id,
          label: p.name,
          sub: [p.years, ERAS[p.era] || p.era].filter(Boolean).join(' · '),
        })),
      ]);
      cb.setValue(prev || '');
    }
  }

  // ─── Save / Reload ────────────────────────────────────────────────────────

  async function saveAll() {
    $('#save-btn').disabled = true;
    showToast('Speichere …');
    try {
      if (state.dirtyPhilosophers) {
        const r = await fetch('/save-philosophers', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ philosophers: state.philosophers }),
        });
        const data = await r.json();
        if (!r.ok || !data.ok) throw new Error('Philosophen: ' + (data.error || `HTTP ${r.status}`));
      }
      if (state.dirtyQuestions) {
        const r = await fetch('/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ version: 1, questions: state.questions }),
        });
        const data = await r.json();
        if (!r.ok || !data.ok) throw new Error('Fragen: ' + (data.error || `HTTP ${r.status}`));
      }
      state.dirtyQuestions = false;
      state.dirtyPhilosophers = false;
      refreshDirty();
      showToast('Gespeichert.', 'ok');
    } catch (e) {
      console.error(e);
      showToast(`Fehler: ${e.message}`, 'err');
    } finally {
      $('#save-btn').disabled = false;
    }
  }

  async function reloadFromSeed() {
    if ((state.dirtyQuestions || state.dirtyPhilosophers) &&
        !confirm('Ungespeicherte Änderungen werden verworfen. Trotzdem neu laden?')) {
      return;
    }
    try {
      await fetch('/reload', { method: 'POST' });
      const [q, p] = await Promise.all([
        fetch('/data/questions.json',    { cache: 'no-store' }).then(r => r.json()),
        fetch('/data/philosophers.json', { cache: 'no-store' }).then(r => r.json()),
      ]);
      state.questions = q.questions || [];
      state.philosophers = p || [];
      state.dirtyQuestions = false;
      state.dirtyPhilosophers = false;
      refreshDirty(); refreshCount();
      rebuildPhilosopherComboboxes();
      renderQuestionTable();
      renderPhilosopherTable();
      showToast('Neu geladen.', 'ok');
    } catch (e) {
      showToast(`Reload fehlgeschlagen: ${e.message}`, 'err');
    }
  }

  // ─── Bulk Import (questions only) ─────────────────────────────────────────

  function openBulk() {
    $('#bulk-text').value = '';
    $('#bulk-report').textContent = '';
    $('#bulk-report').className = 'bulk-report';
    $('#bulk-apply').disabled = true;
    $('#bulk-dialog').classList.remove('hidden');
    $('#bulk-text').focus();
  }
  function closeBulk() { $('#bulk-dialog').classList.add('hidden'); }

  function parseBulk(text) {
    const blocks = text.split('Question(').slice(1);
    const out = [];
    for (const raw of blocks) {
      const q = parseQuestionBlock(raw);
      if (q) out.push(q);
    }
    return out;
  }

  function unescapeDart(s) {
    return s.replace(/\\'/g, "'").replace(/\\"/g, '"')
            .replace(/\\n/g, '\n').replace(/\\\\/g, '\\');
  }

  function findString(block, name) {
    const m1 = new RegExp(`${name}:\\s*'((?:[^'\\\\]|\\\\.)*)'`).exec(block);
    if (m1) return unescapeDart(m1[1]);
    const m2 = new RegExp(`${name}:\\s*"((?:[^"\\\\]|\\\\.)*)"`).exec(block);
    if (m2) return unescapeDart(m2[1]);
    return null;
  }

  function findInt(block, name) {
    const m = new RegExp(`${name}:\\s*(\\d+)`).exec(block);
    return m ? parseInt(m[1], 10) : null;
  }

  function findEnum(block, name, prefix) {
    const m = new RegExp(`${name}:\\s*${prefix}\\.(\\w+)`).exec(block);
    return m ? m[1] : null;
  }

  function findOptions(block) {
    const m = /options:\s*\[([\s\S]+?)\]/.exec(block);
    if (!m) return [];
    const raw = m[1];
    const out = [];
    const rx = /'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)"/g;
    let g;
    while ((g = rx.exec(raw)) !== null) {
      out.push(unescapeDart(g[1] !== undefined ? g[1] : g[2]));
    }
    return out;
  }

  function parseQuestionBlock(raw) {
    const q = {
      id:            findString(raw, 'id'),
      category:      findEnum(raw, 'category', 'QuestionCategory'),
      prompt:        findString(raw, 'prompt'),
      options:       findOptions(raw),
      correctIndex:  findInt(raw, 'correctIndex'),
      difficulty:    findInt(raw, 'difficulty'),
      attribution:   findString(raw, 'attribution'),
      explanation:   findString(raw, 'explanation'),
      philosopherId: findString(raw, 'philosopherId'),
      topicKey:      findString(raw, 'topicKey'),
    };
    if (!q.id || !q.category) return null;
    return q;
  }

  let bulkAccepted = [];
  function validateBulk() {
    const text = $('#bulk-text').value;
    const parsed = parseBulk(text);
    const accepted = [];
    const rejected = [];
    for (const q of parsed) {
      const issues = validateQuestion(q);
      if (issues.length) rejected.push({ q, issues });
      else accepted.push(q);
    }
    const lines = [`Geparsed: ${parsed.length}`, `Akzeptiert: ${accepted.length}`];
    if (rejected.length) {
      lines.push(`Abgelehnt: ${rejected.length}`);
      for (const { q, issues } of rejected) {
        lines.push(`  ${q.id || '<?>'} – ${issues.join(' | ')}`);
      }
    }
    const report = $('#bulk-report');
    report.textContent = lines.join('\n');
    report.className = 'bulk-report ' + (rejected.length ? 'bad' : 'good');
    $('#bulk-apply').disabled = accepted.length === 0;
    bulkAccepted = accepted;
  }

  function applyBulk() {
    if (!bulkAccepted.length) return;
    state.questions.push(...bulkAccepted);
    state.dirtyQuestions = true;
    refreshDirty(); refreshCount(); renderQuestionTable();
    closeBulk();
    showToast(`Importiert: ${bulkAccepted.length} Fragen.`, 'ok');
    bulkAccepted = [];
  }

  // ─── Init UI ──────────────────────────────────────────────────────────────

  function initQuestionFilters() {
    const catSel = $('#filter-category');
    for (const [k, v] of Object.entries(CATEGORIES)) {
      const opt = document.createElement('option');
      opt.value = k; opt.textContent = v;
      catSel.appendChild(opt);
    }
    catSel.addEventListener('change', () => {
      state.filters.q.category = catSel.value;
      renderQuestionTable();
    });

    $('#filter-search').addEventListener('input', (e) => {
      state.filters.q.search = e.target.value;
      renderQuestionTable();
    });

    $$('.diff-row input[type="checkbox"]').forEach(cb => {
      cb.addEventListener('change', () => {
        const n = parseInt(cb.dataset.diff, 10);
        cb.checked ? state.filters.q.difficulties.add(n) : state.filters.q.difficulties.delete(n);
        renderQuestionTable();
      });
    });

    comboboxes.qFilterPhil = buildPhilosopherCombobox(
      $('#filter-philosopher-cb'),
      (val) => { state.filters.q.philosopher = val || ''; renderQuestionTable(); },
    );
  }

  function initPhilosopherFilters() {
    $('#p-filter-search').addEventListener('input', (e) => {
      state.filters.p.search = e.target.value;
      renderPhilosopherTable();
    });
    $('#p-filter-era').addEventListener('change', (e) => {
      state.filters.p.era = e.target.value;
      renderPhilosopherTable();
    });
  }

  function initDrawerForms() {
    // Questions drawer
    const catSel = $('#f-category');
    for (const [k, v] of Object.entries(CATEGORIES)) {
      const opt = document.createElement('option');
      opt.value = k; opt.textContent = v;
      catSel.appendChild(opt);
    }
    comboboxes.qDrawerPhil = buildPhilosopherCombobox(
      $('#f-philosopher-cb'),
      () => {},
    );
    $('#apply-btn').addEventListener('click', applyQuestionDrawer);
    $('#delete-btn').addEventListener('click', deleteCurrentQuestion);
    $('#drawer-close').addEventListener('click', closeQuestionDrawer);

    // Philosophers drawer
    $('#p-apply-btn').addEventListener('click', applyPhilosopherDrawer);
    $('#p-delete-btn').addEventListener('click', deleteCurrentPhilosopher);
    $('#p-drawer-close').addEventListener('click', closePhilosopherDrawer);
  }

  function bindButtons() {
    $$('.tab').forEach(t => t.addEventListener('click', () => switchView(t.dataset.tab)));
    $('#new-btn').addEventListener('click', () => openQuestionDrawer(null));
    $('#p-new-btn').addEventListener('click', () => openPhilosopherDrawer(null));
    $('#save-btn').addEventListener('click', saveAll);
    $('#reload-btn').addEventListener('click', reloadFromSeed);
    $('#bulk-btn').addEventListener('click', openBulk);
    $('#bulk-close').addEventListener('click', closeBulk);
    $('#bulk-validate').addEventListener('click', validateBulk);
    $('#bulk-apply').addEventListener('click', applyBulk);

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        closeQuestionDrawer();
        closePhilosopherDrawer();
        closeBulk();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault();
        saveAll();
      }
    });

    window.addEventListener('beforeunload', (e) => {
      if (state.dirtyQuestions || state.dirtyPhilosophers) {
        e.preventDefault();
        e.returnValue = '';
      }
    });
  }

  function boot() {
    initQuestionFilters();
    initPhilosopherFilters();
    initDrawerForms();
    bindButtons();
    refreshCount();
    renderQuestionTable();
    renderPhilosopherTable();
  }
  document.addEventListener('DOMContentLoaded', boot);
})();
