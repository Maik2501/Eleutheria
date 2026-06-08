// Griphos Kreuzworträtsel-Werkstatt — application logic.
// Single-file vanilla JS. Persists nothing on its own; user exports JSON.

(() => {
  // ─────────────── State ───────────────
  const STORAGE_KEY = 'sophia_crossword_state_v1';
  const MANUAL_STORAGE_KEY = 'sophia_crossword_manual_save_v1';
  const SAVE_VERSION = 2;

  const state = {
    rows: 15,
    cols: 15,
    cells: [], // 2D: { letter:'', block:false, num:null }
    selected: { r: 7, c: 7 },
    direction: 'across', // 'across' | 'down'
    symmetry: false,
    words: [],            // unified bank: { word, displayWord, category, clue, source: 'app'|'custom', placed?: {r,c,dir} }
    selectedWordIndex: -1,
    categoryFilters: new Set(),
    suggestionMode: false,
    customCounter: 0,
  };

  const dragState = {
    wordIndex: -1,
    offset: 0,
    hover: null,
    target: null,
    ok: false,
    msg: '',
    rightButtonDown: false,
  };

  let appWordBank = [];

  // ─────────────── Helpers ───────────────
  const $ = (sel, el = document) => el.querySelector(sel);
  const $$ = (sel, el = document) => Array.from(el.querySelectorAll(sel));

  function cleanLetters(w) {
    return (w || '').toUpperCase().replace(/[^A-ZÄÖÜß]/g, '');
  }

  function cloneWord(word) {
    return {
      word: word.word,
      displayWord: word.displayWord || word.word,
      category: word.category || 'Eigene',
      clue: word.clue || '',
      source: word.source || 'custom',
      placed: word.placed ? { ...word.placed } : null,
    };
  }

  function appWordKey(word) {
    return `${word.word}|${word.displayWord || word.word}`;
  }

  function customWordKey(word) {
    const placed = word.placed ? `${word.placed.r},${word.placed.c},${word.placed.dir}` : '';
    return `${word.word}|${word.displayWord || word.word}|${word.category || ''}|${word.clue || ''}|${placed}`;
  }

  function wordCategories(word) {
    return String(word.category || '')
      .split(',')
      .map(c => c.trim())
      .filter(Boolean);
  }

  function makeEmptyGrid(rows, cols) {
    return Array.from({ length: rows }, () =>
      Array.from({ length: cols }, () => ({ letter: '', block: false, num: null }))
    );
  }

  function inBounds(r, c) {
    return r >= 0 && r < state.rows && c >= 0 && c < state.cols;
  }

  function mirror(r, c) {
    return { r: state.rows - 1 - r, c: state.cols - 1 - c };
  }

  function placedAt(r, c, dir) {
    return state.words.find(w => w.placed && w.placed.r === r && w.placed.c === c && w.placed.dir === dir);
  }

  function placementCovers(word, r, c) {
    if (!word.placed) return false;
    const { r: startR, c: startC, dir } = word.placed;
    if (dir === 'across') {
      return r === startR && c >= startC && c < startC + word.word.length;
    }
    return c === startC && r >= startR && r < startR + word.word.length;
  }

  function isOnlyCoveredByWord(wordIdx, r, c) {
    const word = state.words[wordIdx];
    if (!word || !placementCovers(word, r, c)) return false;
    return !state.words.some((other, idx) => idx !== wordIdx && placementCovers(other, r, c));
  }

  function effectiveLetter(r, c, ignoredWordIndex = -1) {
    if (!inBounds(r, c)) return '';
    const cell = state.cells[r][c];
    if (!cell || cell.block) return '';
    if (ignoredWordIndex >= 0 && isOnlyCoveredByWord(ignoredWordIndex, r, c)) return '';
    return cell.letter || '';
  }

  function clearExistingPlacement(wordIdx) {
    const word = state.words[wordIdx];
    if (!word?.placed) return;
    const { r, c, dir } = word.placed;
    for (let i = 0; i < word.word.length; i++) {
      const rr = dir === 'down' ? r + i : r;
      const cc = dir === 'across' ? c + i : c;
      if (!inBounds(rr, cc)) continue;
      if (!isOnlyCoveredByWord(wordIdx, rr, cc)) continue;
      if (!state.cells[rr][cc].block) state.cells[rr][cc].letter = '';
    }
    word.placed = null;
  }

  function toggleDirection() {
    state.direction = state.direction === 'across' ? 'down' : 'across';
    updateDirButtons();
    updatePlacementHint();
    if (dragState.wordIndex >= 0 && dragState.target) {
      updateDragPreview(dragState.wordIndex, dragState.hover.r, dragState.hover.c);
    } else {
      renderGrid();
    }
    refreshSuggestions();
  }

  function clearDragPreview(render = true) {
    const hadPreview = dragState.wordIndex >= 0 || dragState.target;
    dragState.wordIndex = -1;
    dragState.offset = 0;
    dragState.hover = null;
    dragState.target = null;
    dragState.ok = false;
    dragState.msg = '';
    dragState.rightButtonDown = false;
    if (render && hadPreview) renderGrid();
  }

  function dragPreviewCovers(r, c) {
    const word = state.words[dragState.wordIndex];
    if (!word || !dragState.target) return false;
    const { r: startR, c: startC } = dragState.target;
    if (state.direction === 'across') {
      return r === startR && c >= startC && c < startC + word.word.length;
    }
    return c === startC && r >= startR && r < startR + word.word.length;
  }

  function placedWordAtCell(r, c) {
    const matches = state.words
      .map((word, index) => {
        if (!word.placed || !placementCovers(word, r, c)) return null;
        const offset = word.placed.dir === 'across' ? c - word.placed.c : r - word.placed.r;
        return { index, word, dir: word.placed.dir, offset };
      })
      .filter(Boolean);
    return matches.find(match => match.dir === state.direction) || matches[0] || null;
  }

  function dragStartForHover(r, c) {
    return {
      r: state.direction === 'down' ? r - dragState.offset : r,
      c: state.direction === 'across' ? c - dragState.offset : c,
    };
  }

  function updateDragPreview(wordIdx, hoverR, hoverC, render = true) {
    const target = dragStartForHover(hoverR, hoverC);
    const result = validateWordPlacement(wordIdx, target.r, target.c, state.direction);
    const changed =
      dragState.wordIndex !== wordIdx ||
      !dragState.hover ||
      dragState.hover.r !== hoverR ||
      dragState.hover.c !== hoverC ||
      !dragState.target ||
      dragState.target.r !== target.r ||
      dragState.target.c !== target.c ||
      dragState.ok !== result.ok ||
      dragState.msg !== (result.msg || '');

    dragState.wordIndex = wordIdx;
    dragState.hover = { r: hoverR, c: hoverC };
    dragState.target = target;
    dragState.ok = result.ok;
    dragState.msg = result.msg || '';

    if (changed && render) renderGrid();
    return result;
  }

  // ─────────────── Word bank ───────────────
  function loadAppWords() {
    const seed = window.SOPHIA_ANSWERS || [];
    const appWords = seed.map((entry) => {
      const cats = Array.from(new Set(entry.prompts.map(p => p.category))).join(', ') || entry.category || '';
      const firstClue = entry.prompts[0]?.prompt || '';
      const display = entry.word;
      return {
        word: cleanLetters(display),
        displayWord: display,
        category: cats || 'App',
        clue: firstClue,
        source: 'app',
        placed: null,
      };
    }).filter(w => w.word.length >= 3); // crosswords need >= 3 letters

    const curatedWords = (window.SOPHIA_CROSSWORD_TERMS || []).map((entry) => {
      const display = typeof entry === 'string' ? entry : entry.word;
      return {
        word: cleanLetters(display),
        displayWord: display,
        category: entry.category || 'Kreuzwort-Begriffe',
        clue: entry.clue || '',
        source: 'curated',
        placed: null,
      };
    }).filter(w => w.word.length >= 3 && w.word.length <= 15);

    appWordBank = [...appWords, ...curatedWords];
    state.words = appWordBank.map(cloneWord);
  }

  function mergeLoadedWords(savedWords) {
    const merged = appWordBank.map(cloneWord);
    const appIndex = new Map();
    merged.forEach((word, index) => appIndex.set(appWordKey(word), index));

    const customKeys = new Set();
    savedWords.forEach((savedWord) => {
      if (!savedWord?.word) return;
      const word = cloneWord(savedWord);
      if (word.source === 'app' || word.source === 'curated') {
        const index = appIndex.get(appWordKey(word));
        if (index !== undefined) {
          merged[index] = {
            ...merged[index],
            clue: word.clue || merged[index].clue,
            placed: word.placed,
          };
          return;
        }
      }

      const key = customWordKey(word);
      if (customKeys.has(key)) return;
      customKeys.add(key);
      merged.push(word);
    });

    return merged;
  }

  function categories() {
    const set = new Set();
    state.words.forEach(w => wordCategories(w).forEach(c => set.add(c)));
    return Array.from(set).sort();
  }

  // ─────────────── Rendering ───────────────
  function renderGrid() {
    const host = $('#gridHost');
    host.style.gridTemplateColumns = `repeat(${state.cols}, 38px)`;
    host.innerHTML = '';
    for (let r = 0; r < state.rows; r++) {
      for (let c = 0; c < state.cols; c++) {
        const cell = state.cells[r][c];
        const el = document.createElement('div');
        el.className = 'cell';
        el.dataset.r = r;
        el.dataset.c = c;
        const placedWord = placedWordAtCell(r, c);
        if (placedWord) {
          el.draggable = true;
          el.classList.add('placed-word-cell');
          el.title = 'Platziertes Wort ziehen. Rechtsklick beim Ziehen wechselt die Richtung.';
        }
        if (cell.block) el.classList.add('block');
        if (state.selected.r === r && state.selected.c === c) el.classList.add('selected');
        else if (isInActiveWord(r, c)) el.classList.add('active-word');
        if (dragPreviewCovers(r, c)) {
          el.classList.add(dragState.ok ? 'drop-preview' : 'drop-preview-invalid');
        }

        if (cell.num) {
          const n = document.createElement('span');
          n.className = 'num';
          n.textContent = cell.num;
          el.appendChild(n);
        }
        if (cell.letter) {
          const l = document.createElement('span');
          l.className = 'letter';
          l.textContent = cell.letter;
          el.appendChild(l);
        }
        host.appendChild(el);
      }
    }
  }

  function isInActiveWord(r, c) {
    const sel = state.selected;
    if (!sel) return false;
    if (state.cells[sel.r][sel.c].block) return false;
    if (state.direction === 'across' && r === sel.r) {
      // walk left/right from sel until we hit a block/edge
      let l = sel.c, R = sel.c;
      while (l > 0 && !state.cells[sel.r][l - 1].block) l--;
      while (R < state.cols - 1 && !state.cells[sel.r][R + 1].block) R++;
      return c >= l && c <= R;
    }
    if (state.direction === 'down' && c === sel.c) {
      let t = sel.r, B = sel.r;
      while (t > 0 && !state.cells[t - 1][sel.c].block) t--;
      while (B < state.rows - 1 && !state.cells[B + 1][sel.c].block) B++;
      return r >= t && r <= B;
    }
    return false;
  }

  function renderWordList() {
    const ul = $('#wordList');
    const search = $('#wordSearch').value.trim().toLowerCase();
    const activeCategories = state.categoryFilters;
    const sortMode = $('#sortMode').value;
    const suggestion = suggestionContext();

    let list = state.words
      .map((w, i) => ({ ...w, _i: i }))
      .filter(w =>
        (!search || w.displayWord.toLowerCase().includes(search) || w.word.toLowerCase().includes(search)) &&
        (!activeCategories.size || wordCategories(w).some(cat => activeCategories.has(cat))) &&
        (!suggestion || validateWordPlacement(w._i, suggestion.r, suggestion.c, suggestion.dir).ok)
      );

    list.sort((a, b) => {
      if (sortMode === 'length-desc') return b.word.length - a.word.length;
      if (sortMode === 'length-asc') return a.word.length - b.word.length;
      if (sortMode === 'category') return a.category.localeCompare(b.category, 'de');
      return a.word.localeCompare(b.word, 'de');
    });

    ul.innerHTML = '';
    renderSuggestionSummary(list.length, suggestion);
    list.forEach((w) => {
      const li = document.createElement('li');
      if (w.placed) li.classList.add('placed');
      if (w._i === state.selectedWordIndex) li.classList.add('selected');
      if (w._i === dragState.wordIndex) li.classList.add('dragging');
      li.dataset.idx = w._i;
      li.draggable = true;
      li.title = 'Ziehen ins Gitter. Rechtsklick wechselt die Richtung.';
      li.innerHTML = `
        <div>
          <div class="w-text">${escapeHtml(w.word)}</div>
          <div class="w-cat">${escapeHtml(w.category)}${w.source === 'custom' ? ' · eigen' : ''}</div>
        </div>
        <div class="w-meta">${w.word.length}</div>
      `;
      li.addEventListener('click', () => {
        state.selectedWordIndex = (state.selectedWordIndex === w._i) ? -1 : w._i;
        renderWordList();
        updatePlacementHint();
      });
      li.addEventListener('contextmenu', (ev) => {
        ev.preventDefault();
        state.selectedWordIndex = w._i;
        toggleDirection();
        renderWordList();
      });
      li.addEventListener('dragstart', (ev) => {
        dragState.wordIndex = w._i;
        dragState.offset = 0;
        state.selectedWordIndex = w._i;
        li.classList.add('selected', 'dragging');
        updatePlacementHint();
        setDragData(ev, w._i);
      });
      li.addEventListener('dragend', () => {
        clearDragPreview();
        renderWordList();
      });
      ul.appendChild(li);
    });
  }

  function renderCategoryFilter() {
    const host = $('#categoryFilter');
    const availableCategories = categories();
    state.categoryFilters = new Set([...state.categoryFilters].filter(cat => availableCategories.includes(cat)));
    const active = new Set(state.categoryFilters);
    host.innerHTML = '';

    const allButton = document.createElement('button');
    allButton.type = 'button';
    allButton.className = `category-chip${active.size ? '' : ' active'}`;
    allButton.textContent = 'Alle';
    allButton.addEventListener('click', () => {
      state.categoryFilters.clear();
      renderCategoryFilter();
      renderWordList();
    });
    host.appendChild(allButton);

    availableCategories.forEach(cat => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `category-chip${active.has(cat) ? ' active' : ''}`;
      button.textContent = cat;
      button.addEventListener('click', () => {
        if (state.categoryFilters.has(cat)) state.categoryFilters.delete(cat);
        else state.categoryFilters.add(cat);
        renderCategoryFilter();
        renderWordList();
      });
      host.appendChild(button);
    });

    const customSel = $('#customCategoryInput');
    const customCurrent = customSel.value;
    customSel.innerHTML = '<option value="Eigene">Eigene</option>';
    categories().filter(c => c !== 'Eigene').forEach(cat => {
      const o = document.createElement('option');
      o.value = cat;
      o.textContent = cat;
      customSel.appendChild(o);
    });
    customSel.value = customCurrent || 'Eigene';
  }

  function suggestionContext() {
    if (!state.suggestionMode || !state.selected) return null;
    const { r, c } = state.selected;
    if (!inBounds(r, c) || state.cells[r][c].block) return null;
    return { r, c, dir: state.direction };
  }

  function renderSuggestionSummary(count, suggestion) {
    const host = $('#suggestionSummary');
    if (!host) return;
    if (!state.suggestionMode) {
      host.textContent = '';
      return;
    }
    if (!suggestion) {
      host.textContent = 'Wähle ein weißes Startfeld im Gitter.';
      return;
    }
    const dir = suggestion.dir === 'across' ? 'waagerecht' : 'senkrecht';
    host.textContent = `${count} passende Wörter für ${suggestion.r + 1}/${suggestion.c + 1} ${dir}.`;
  }

  function updateSuggestionModeControls() {
    const button = $('#suggestionModeBtn');
    if (!button) return;
    button.classList.toggle('active', state.suggestionMode);
    button.textContent = state.suggestionMode ? 'Vorschläge: an' : 'Vorschläge';
  }

  function refreshSuggestions() {
    updateSuggestionModeControls();
    if (state.suggestionMode) renderWordList();
    else renderSuggestionSummary(0, null);
  }

  function renderClues() {
    // Build clue entries from placed words and manually typed letter runs.
    const across = [], down = [];
    for (let r = 0; r < state.rows; r++) {
      for (let c = 0; c < state.cols; c++) {
        const cell = state.cells[r][c];
        if (cell.block || !cell.num) continue;
        if (startsAcross(r, c)) {
          across.push({ num: cell.num, r, c, dir: 'across', word: readWord(r, c, 'across') });
        }
        if (startsDown(r, c)) {
          down.push({ num: cell.num, r, c, dir: 'down', word: readWord(r, c, 'down') });
        }
      }
    }

    const renderList = (host, entries) => {
      host.innerHTML = '';
      entries.forEach((e) => {
        const li = document.createElement('li');
        const placed = placedAt(e.r, e.c, e.dir);
        const clueValue = placed ? placed.clue : '';
        li.innerHTML = `
          <span class="num-col">${e.num}.</span>
          <div>
            <div class="word-row">${escapeHtml(e.word.text)} <span style="color: var(--ink-faint); font-weight: 400;">(${e.word.text.length})</span></div>
            <input type="text" class="clue-input" placeholder="Hinweis…" value="${escapeAttr(clueValue)}" data-r="${e.r}" data-c="${e.c}" data-dir="${e.dir}">
          </div>
        `;
        host.appendChild(li);
      });
    };

    renderList($('#acrossList'), across);
    renderList($('#downList'), down);

    // Wire up clue input
    $$('.clue-input').forEach(inp => {
      inp.addEventListener('input', (ev) => {
        const r = +ev.target.dataset.r;
        const c = +ev.target.dataset.c;
        const dir = ev.target.dataset.dir;
        const placed = placedAt(r, c, dir);
        if (placed) {
          placed.clue = ev.target.value;
          saveState();
        }
      });
    });
  }

  function startsAcross(r, c) {
    const cell = state.cells[r][c];
    if (cell.block) return false;
    if (placedAt(r, c, 'across')) return true;
    if (!cell.letter) return false;
    const leftLetter = c > 0 && !state.cells[r][c - 1].block && state.cells[r][c - 1].letter;
    const rightLetter = c < state.cols - 1 && !state.cells[r][c + 1].block && state.cells[r][c + 1].letter;
    return !leftLetter && !!rightLetter;
  }
  function startsDown(r, c) {
    const cell = state.cells[r][c];
    if (cell.block) return false;
    if (placedAt(r, c, 'down')) return true;
    if (!cell.letter) return false;
    const aboveLetter = r > 0 && !state.cells[r - 1][c].block && state.cells[r - 1][c].letter;
    const belowLetter = r < state.rows - 1 && !state.cells[r + 1][c].block && state.cells[r + 1][c].letter;
    return !aboveLetter && !!belowLetter;
  }

  function readWord(r, c, dir) {
    const placed = placedAt(r, c, dir);
    if (placed) return readExactWord(r, c, dir, placed.word.length) || { text: '' };

    let text = '';
    if (dir === 'across') {
      let cc = c;
      while (cc < state.cols && !state.cells[r][cc].block && state.cells[r][cc].letter) {
        text += state.cells[r][cc].letter;
        cc++;
      }
    } else {
      let rr = r;
      while (rr < state.rows && !state.cells[rr][c].block && state.cells[rr][c].letter) {
        text += state.cells[rr][c].letter;
        rr++;
      }
    }
    return { text };
  }

  function readExactWord(r, c, dir, length) {
    let text = '';
    for (let i = 0; i < length; i++) {
      const rr = dir === 'down' ? r + i : r;
      const cc = dir === 'across' ? c + i : c;
      if (!inBounds(rr, cc) || state.cells[rr][cc].block) return null;
      text += state.cells[rr][cc].letter || '·';
    }
    return { text };
  }

  // ─────────────── Numbering ───────────────
  function renumber() {
    let n = 1;
    for (let r = 0; r < state.rows; r++) {
      for (let c = 0; c < state.cols; c++) {
        state.cells[r][c].num = null;
        if (state.cells[r][c].block) continue;
        if (startsAcross(r, c) || startsDown(r, c)) {
          state.cells[r][c].num = n++;
        }
      }
    }
  }

  // ─────────────── Mutations ───────────────
  function setLetter(r, c, letter) {
    if (!inBounds(r, c)) return false;
    const cell = state.cells[r][c];
    if (cell.block) return false;
    cell.letter = letter ? letter.toUpperCase() : '';
    return true;
  }

  function toggleBlock(r, c) {
    if (!inBounds(r, c)) return;
    const cell = state.cells[r][c];
    cell.block = !cell.block;
    if (cell.block) cell.letter = '';
    if (state.symmetry) {
      const m = mirror(r, c);
      if (!(m.r === r && m.c === c)) {
        const mc = state.cells[m.r][m.c];
        mc.block = cell.block;
        if (mc.block) mc.letter = '';
      }
    }
    // Any words that lived on broken-up runs become "free": clear their .placed marker.
    pruneInvalidPlacements();
    renumber();
    rerenderAll();
  }

  function pruneInvalidPlacements() {
    state.words.forEach(w => {
      if (!w.placed) return;
      const { r, c, dir } = w.placed;
      const word = readExactWord(r, c, dir, w.word.length);
      if (!word || word.text !== w.word) {
        w.placed = null;
      }
    });
  }

  function clearAll() {
    state.cells = makeEmptyGrid(state.rows, state.cols);
    state.words.forEach(w => w.placed = null);
    rerenderAll();
  }

  function resizeGrid(rows, cols) {
    const old = state.cells;
    state.rows = rows;
    state.cols = cols;
    const next = makeEmptyGrid(rows, cols);
    for (let r = 0; r < Math.min(old.length, rows); r++) {
      for (let c = 0; c < Math.min(old[0].length, cols); c++) {
        next[r][c] = old[r][c];
      }
    }
    state.cells = next;
    if (!inBounds(state.selected.r, state.selected.c)) state.selected = { r: 0, c: 0 };
    state.words.forEach(w => {
      if (!w.placed) return;
      const { r, c, dir } = w.placed;
      const endR = dir === 'down' ? r + w.word.length - 1 : r;
      const endC = dir === 'across' ? c + w.word.length - 1 : c;
      if (!inBounds(endR, endC)) w.placed = null;
    });
    pruneInvalidPlacements();
    renumber();
    rerenderAll();
  }

  // ─────────────── Word placement ───────────────
  function validateWordPlacement(wordIdx, r, c, dir) {
    const w = state.words[wordIdx];
    if (!w) return { ok: false, msg: 'Wort nicht gefunden' };
    const letters = w.word;
    if (letters.length < 2) return { ok: false, msg: 'Wort zu kurz' };

    // bounds check
    const endR = dir === 'down' ? r + letters.length - 1 : r;
    const endC = dir === 'across' ? c + letters.length - 1 : c;
    if (!inBounds(r, c)) return { ok: false, msg: 'Startfeld liegt außerhalb des Gitters' };
    if (!inBounds(endR, endC)) return { ok: false, msg: 'Wort passt nicht in das Gitter' };

    // Only existing letters before/after would merge words. Empty cells are fine while constructing.
    const beforeR = dir === 'down' ? r - 1 : r;
    const beforeC = dir === 'across' ? c - 1 : c;
    if (effectiveLetter(beforeR, beforeC, wordIdx)) {
      return { ok: false, msg: 'Davor steht ein Buchstabe — würde Wörter verschmelzen.' };
    }
    const afterR = dir === 'down' ? endR + 1 : endR;
    const afterC = dir === 'across' ? endC + 1 : endC;
    if (effectiveLetter(afterR, afterC, wordIdx)) {
      return { ok: false, msg: 'Nach dem Wort steht ein Buchstabe — würde Wörter verschmelzen.' };
    }

    // letter conflict check
    for (let i = 0; i < letters.length; i++) {
      const rr = dir === 'down' ? r + i : r;
      const cc = dir === 'across' ? c + i : c;
      const cell = state.cells[rr][cc];
      if (cell.block) return { ok: false, msg: `Konflikt mit Sperrfeld bei ${rr + 1}/${cc + 1}` };
      const existing = effectiveLetter(rr, cc, wordIdx);
      if (existing && existing !== letters[i]) {
        return { ok: false, msg: `Konflikt: ${existing} ≠ ${letters[i]} bei ${rr + 1}/${cc + 1}` };
      }
    }

    return { ok: true, word: w, letters };
  }

  function tryPlaceWord(wordIdx, r, c, dir) {
    const result = validateWordPlacement(wordIdx, r, c, dir);
    if (!result.ok) return result;
    const { word: w, letters } = result;

    // commit
    clearExistingPlacement(wordIdx);
    for (let i = 0; i < letters.length; i++) {
      const rr = dir === 'down' ? r + i : r;
      const cc = dir === 'across' ? c + i : c;
      state.cells[rr][cc].letter = letters[i];
    }
    w.placed = { r, c, dir };
    state.selectedWordIndex = -1;
    state.selected = { r, c };
    state.direction = dir;
    renumber();
    rerenderAll();
    return { ok: true };
  }

  // ─────────────── Input ───────────────
  function moveCaret(dir) {
    const sel = state.selected;
    let { r, c } = sel;
    if (state.direction === 'across') c += dir;
    else r += dir;
    if (!inBounds(r, c)) return;
    state.selected = { r, c };
  }

  function handleKey(ev) {
    const sel = state.selected;
    if (!sel) return;
    const cell = state.cells[sel.r][sel.c];

    // Direction switches
    if (ev.key === 'Tab') {
      ev.preventDefault();
      state.direction = state.direction === 'across' ? 'down' : 'across';
      updateDirButtons();
      renderGrid();
      refreshSuggestions();
      return;
    }
    if (ev.key === 'ArrowRight' || ev.key === 'ArrowLeft') {
      ev.preventDefault();
      if (state.direction !== 'across') {
        state.direction = 'across';
        updateDirButtons();
      } else {
        moveCaret(ev.key === 'ArrowRight' ? 1 : -1);
      }
      renderGrid();
      refreshSuggestions();
      return;
    }
    if (ev.key === 'ArrowDown' || ev.key === 'ArrowUp') {
      ev.preventDefault();
      if (state.direction !== 'down') {
        state.direction = 'down';
        updateDirButtons();
      } else {
        moveCaret(ev.key === 'ArrowDown' ? 1 : -1);
      }
      renderGrid();
      refreshSuggestions();
      return;
    }
    if (ev.key === 'Backspace') {
      ev.preventDefault();
      if (cell.letter) {
        cell.letter = '';
      } else {
        moveCaret(-1);
        const s = state.selected;
        if (!state.cells[s.r][s.c].block) state.cells[s.r][s.c].letter = '';
      }
      pruneInvalidPlacements();
      renumber();
      rerenderAll();
      return;
    }
    if (ev.key === 'Delete') {
      ev.preventDefault();
      cell.letter = '';
      pruneInvalidPlacements();
      rerenderAll();
      return;
    }
    if (ev.key === ' ') {
      ev.preventDefault();
      // Space toggles block on current cell.
      toggleBlock(sel.r, sel.c);
      return;
    }
    // Letters (incl. umlauts)
    if (ev.key.length === 1 && /[A-Za-zÄÖÜäöüß]/.test(ev.key)) {
      ev.preventDefault();
      if (cell.block) return;
      cell.letter = ev.key.toUpperCase();
      pruneInvalidPlacements();
      moveCaret(1);
      renumber();
      rerenderAll();
      return;
    }
  }

  // ─────────────── UI wiring ───────────────
  function rerenderAll() {
    renderGrid();
    renderWordList();
    renderClues();
    saveState();
  }

  function updatePlacementHint() {
    const hint = $('#placementHint');
    if (state.selectedWordIndex >= 0) {
      const w = state.words[state.selectedWordIndex];
      hint.innerHTML = `<strong style="color: var(--burgundy)">Platzieren:</strong> ${escapeHtml(w.word)} <span style="color: var(--ink-faint)">(${w.word.length} Buchstaben, ${state.direction === 'across' ? 'horizontal' : 'vertikal'}).</span> Ziehe ins Gitter oder klicke ein Startfeld. Rechtsklick beim Ziehen wechselt die Richtung.`;
    } else if (state.suggestionMode) {
      hint.textContent = 'Vorschlagmodus: Klicke ein Startfeld; links bleiben nur passende Wörter sichtbar. Richtung oben oder per Rechtsklick wechseln.';
    } else {
      hint.textContent = 'Modus: Buchstaben tippen. Wörter aus der Bank oder bereits platzierte Wörter ziehen. Rechtsklick wechselt die Richtung.';
    }
  }

  function updateDirButtons() {
    $$('.dir-btn').forEach(b => b.classList.toggle('active', b.dataset.dir === state.direction));
  }

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
  }
  function escapeAttr(s) { return escapeHtml(s); }

  function wordIndexFromDragEvent(ev) {
    if (dragState.wordIndex >= 0) return dragState.wordIndex;
    const raw = ev.dataTransfer?.getData('text/plain');
    const idx = Number.parseInt(raw, 10);
    return Number.isInteger(idx) && state.words[idx] ? idx : -1;
  }

  function setDragData(ev, wordIdx) {
    ev.dataTransfer.effectAllowed = 'copyMove';
    ev.dataTransfer.setData('text/plain', String(wordIdx));
  }

  function toggleDirectionFromDragRightClick(ev) {
    if (dragState.wordIndex < 0) return false;
    ev.preventDefault();
    ev.stopPropagation();
    toggleDirection();
    return true;
  }

  function updateDragRightButtonState(ev) {
    if (dragState.wordIndex < 0 || typeof ev.buttons !== 'number') return;
    const rightButtonDown = (ev.buttons & 2) === 2;
    if (rightButtonDown && !dragState.rightButtonDown) {
      dragState.rightButtonDown = true;
      toggleDirection();
    } else if (!rightButtonDown) {
      dragState.rightButtonDown = false;
    }
  }

  function attachHandlers() {
    // Tabs
    $$('.tab').forEach(t => t.addEventListener('click', () => {
      $$('.tab').forEach(b => b.classList.toggle('active', b === t));
      $$('.panel').forEach(p => p.hidden = p.dataset.panel !== t.dataset.tab);
    }));

    // Toolbar
    $('#resizeBtn').addEventListener('click', () => {
      const r = clampInt($('#rowsInput').value, 5, 30, 15);
      const c = clampInt($('#colsInput').value, 5, 30, 15);
      resizeGrid(r, c);
    });
    $('#symmetryBtn').addEventListener('click', () => {
      state.symmetry = !state.symmetry;
      $('#symmetryState').textContent = state.symmetry ? 'an' : 'aus';
      saveState();
    });
    $('#numberBtn').addEventListener('click', () => { renumber(); rerenderAll(); });
    $('#clearBtn').addEventListener('click', () => {
      if (confirm('Wirklich alle Buchstaben und Sperrfelder löschen?')) clearAll();
    });
    $('#manualSaveBtn').addEventListener('click', saveManualState);
    $('#manualLoadBtn').addEventListener('click', loadManualState);
    $('#exportBtn').addEventListener('click', exportJson);
    $('#importInput').addEventListener('change', importJson);
    $('#printBtn').addEventListener('click', () => window.print());

    // Word list filters
    $('#wordSearch').addEventListener('input', renderWordList);
    $('#sortMode').addEventListener('change', renderWordList);
    $('#suggestionModeBtn').addEventListener('click', () => {
      state.suggestionMode = !state.suggestionMode;
      refreshSuggestions();
      updatePlacementHint();
    });

    // Custom word
    $('#customWordForm').addEventListener('submit', (ev) => {
      ev.preventDefault();
      const raw = $('#customWordInput').value.trim();
      const clue = $('#customClueInput').value.trim();
      const cat = $('#customCategoryInput').value || 'Eigene';
      if (!raw) return;
      const cleaned = cleanLetters(raw);
      if (cleaned.length < 2) {
        alert('Wort muss mindestens 2 Buchstaben enthalten.');
        return;
      }
      state.words.push({
        word: cleaned,
        displayWord: raw,
        category: cat,
        clue,
        source: 'custom',
        placed: null,
      });
      state.customCounter++;
      $('#customWordInput').value = '';
      $('#customClueInput').value = '';
      renderCategoryFilter();
      renderWordList();
      saveState();
    });

    // Direction buttons
    $$('.dir-btn').forEach(b => b.addEventListener('click', () => {
      state.direction = b.dataset.dir;
      updateDirButtons();
      renderGrid();
      updatePlacementHint();
      refreshSuggestions();
    }));

    document.addEventListener('contextmenu', (ev) => {
      toggleDirectionFromDragRightClick(ev);
    }, true);
    document.addEventListener('mousedown', (ev) => {
      if (ev.button === 2) toggleDirectionFromDragRightClick(ev);
    }, true);

    // Grid interactions
    const gridHost = $('#gridHost');
    gridHost.addEventListener('contextmenu', (ev) => {
      const cell = ev.target.closest('.cell');
      if (!cell) return;
      ev.preventDefault();
      state.selected = { r: +cell.dataset.r, c: +cell.dataset.c };
      toggleDirection();
      refreshSuggestions();
    });

    gridHost.addEventListener('dragstart', (ev) => {
      const cell = ev.target.closest('.cell');
      if (!cell) return;
      const r = +cell.dataset.r;
      const c = +cell.dataset.c;
      const placedWord = placedWordAtCell(r, c);
      if (!placedWord) return;
      dragState.wordIndex = placedWord.index;
      dragState.offset = placedWord.offset;
      state.selectedWordIndex = placedWord.index;
      state.selected = { r, c };
      state.direction = placedWord.dir;
      updateDirButtons();
      updatePlacementHint();
      setDragData(ev, placedWord.index);
      updateDragPreview(placedWord.index, r, c, false);
    });

    gridHost.addEventListener('dragover', (ev) => {
      const cell = ev.target.closest('.cell');
      const wordIdx = wordIndexFromDragEvent(ev);
      if (!cell || wordIdx < 0) return;
      ev.preventDefault();
      updateDragRightButtonState(ev);
      const result = updateDragPreview(wordIdx, +cell.dataset.r, +cell.dataset.c);
      ev.dataTransfer.dropEffect = result.ok ? 'copy' : 'none';
    });

    gridHost.addEventListener('dragleave', (ev) => {
      if (!gridHost.contains(ev.relatedTarget)) clearDragPreview();
    });

    gridHost.addEventListener('drop', (ev) => {
      const cell = ev.target.closest('.cell');
      const wordIdx = wordIndexFromDragEvent(ev);
      if (!cell || wordIdx < 0) return;
      ev.preventDefault();
      const r = +cell.dataset.r;
      const c = +cell.dataset.c;
      updateDragPreview(wordIdx, r, c, false);
      const target = dragState.target;
      clearDragPreview(false);
      const result = target
        ? tryPlaceWord(wordIdx, target.r, target.c, state.direction)
        : tryPlaceWord(wordIdx, r, c, state.direction);
      if (!result.ok) {
        flashHint(result.msg, true);
        renderGrid();
      }
    });

    gridHost.addEventListener('dragend', () => {
      clearDragPreview();
      renderWordList();
    });

    gridHost.addEventListener('click', (ev) => {
      const cell = ev.target.closest('.cell');
      if (!cell) return;
      const r = +cell.dataset.r;
      const c = +cell.dataset.c;
      // If a word from the bank is selected, try to place
      if (state.selectedWordIndex >= 0) {
        const result = tryPlaceWord(state.selectedWordIndex, r, c, state.direction);
        if (!result.ok) {
          flashHint(result.msg, true);
        }
        return;
      }
      // Else: select cell and toggle direction if same cell clicked again
      if (state.selected.r === r && state.selected.c === c) {
        state.direction = state.direction === 'across' ? 'down' : 'across';
        updateDirButtons();
      } else {
        state.selected = { r, c };
      }
      renderGrid();
      refreshSuggestions();
    });
    gridHost.addEventListener('dblclick', (ev) => {
      const cell = ev.target.closest('.cell');
      if (!cell) return;
      const r = +cell.dataset.r;
      const c = +cell.dataset.c;
      toggleBlock(r, c);
    });

    // Keyboard
    document.addEventListener('keydown', (ev) => {
      // ignore if focus is in an input/textarea
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes(document.activeElement?.tagName)) return;
      if (ev.key === 'Escape') {
        clearDragPreview();
        if (state.selectedWordIndex >= 0) {
          state.selectedWordIndex = -1;
          renderWordList();
          updatePlacementHint();
        }
        return;
      }
      handleKey(ev);
    });
  }

  function clampInt(v, lo, hi, fallback) {
    const n = parseInt(v, 10);
    if (Number.isNaN(n)) return fallback;
    return Math.max(lo, Math.min(hi, n));
  }

  let hintTimer = null;
  function flashHint(msg, isError = false) {
    const hint = $('#placementHint');
    const prev = hint.innerHTML;
    hint.innerHTML = `<span style="color: ${isError ? '#a94422' : 'var(--burgundy)'}">${escapeHtml(msg)}</span>`;
    if (hintTimer) clearTimeout(hintTimer);
    hintTimer = setTimeout(() => updatePlacementHint(), 3500);
  }

  // ─────────────── Save/Load ───────────────
  function saveState() {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(snapshot()));
    } catch { /* ignore */ }
  }
  function loadState() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return false;
      const data = JSON.parse(raw);
      return restore(data);
    } catch { return false; }
  }

  function saveManualState() {
    try {
      localStorage.setItem(MANUAL_STORAGE_KEY, JSON.stringify(snapshot()));
      flashHint('Gespeichert ✓');
    } catch (err) {
      flashHint('Speichern fehlgeschlagen: ' + err.message, true);
    }
  }

  function loadManualState() {
    try {
      const raw = localStorage.getItem(MANUAL_STORAGE_KEY);
      if (!raw) {
        flashHint('Noch kein gespeicherter Stand vorhanden.', true);
        return;
      }
      const data = JSON.parse(raw);
      if (!restore(data)) throw new Error('Ungültiger Speicherstand');
      syncToolbar();
      renderCategoryFilter();
      rerenderAll();
      flashHint('Geladen ✓');
    } catch (err) {
      flashHint('Laden fehlgeschlagen: ' + err.message, true);
    }
  }

  function snapshot() {
    return {
      version: SAVE_VERSION,
      savedAt: new Date().toISOString(),
      rows: state.rows,
      cols: state.cols,
      symmetry: state.symmetry,
      suggestionMode: state.suggestionMode,
      cells: state.cells,
      words: state.words,
    };
  }
  function restore(data) {
    if (!data || ![1, SAVE_VERSION].includes(data.version)) return false;
    state.rows = data.rows;
    state.cols = data.cols;
    state.symmetry = data.version >= 2 ? !!data.symmetry : false;
    state.suggestionMode = !!data.suggestionMode;
    state.cells = data.cells;
    if (Array.isArray(data.words) && data.words.length) {
      state.words = mergeLoadedWords(data.words);
    } else {
      state.words = appWordBank.map(cloneWord);
    }
    state.selectedWordIndex = -1;
    clearDragPreview(false);
    if (!inBounds(state.selected.r, state.selected.c)) state.selected = { r: 0, c: 0 };
    return true;
  }

  function exportJson() {
    const data = snapshot();
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const ts = new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-');
    a.href = url;
    a.download = `griphos-kreuzwortraetsel-${ts}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }
  function importJson(ev) {
    const file = ev.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const data = JSON.parse(reader.result);
        if (!restore(data)) throw new Error('Ungültiges Dateiformat');
        syncToolbar();
        renderCategoryFilter();
        rerenderAll();
        flashHint('Geladen ✓');
      } catch (err) {
        flashHint('Datei konnte nicht gelesen werden: ' + err.message, true);
      }
    };
    reader.readAsText(file);
    ev.target.value = '';
  }

  function syncToolbar() {
    $('#rowsInput').value = state.rows;
    $('#colsInput').value = state.cols;
    $('#symmetryState').textContent = state.symmetry ? 'an' : 'aus';
    updateSuggestionModeControls();
  }

  // ─────────────── Init ───────────────
  function init() {
    state.cells = makeEmptyGrid(state.rows, state.cols);
    loadAppWords();
    loadState();
    syncToolbar();
    renderCategoryFilter();
    renumber();
    attachHandlers();
    rerenderAll();
    updatePlacementHint();
    updateDirButtons();
    updateSuggestionModeControls();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
