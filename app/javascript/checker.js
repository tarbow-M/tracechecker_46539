// --- グローバル変数 (Turboオフのため 'var' を使用) ---
var isSelectionMode = false; // データ範囲選択モード (ドラッグ)
var isKeySelectionMode = false; // キー選択モード (シングルクリック)

var selectionCoordsA = [];
var selectionCoordsB = [];
var keySelectionCoordsA = [];
var keySelectionCoordsB = [];

var templatesCache = [];
var comparisonResultsCache = [];
var selectedFileAId = null;
var selectedFileBId = null;
var currentDiffCount = 0;

// ▼▼▼ ドラッグ選択用の変数 ▼▼▼
var isDragging = false;
var dragStartCell = null;
var currentDocType = null;
var dragStartOffsetX = 0; // Relative X start position
var dragStartOffsetY = 0; // Relative Y start position
var selectionBox = null; // Reference to the temporary selection box

// ==========================================
// 1. ヘルパー関数 (定義順を冒頭に移動)
// ==========================================

// --- 4. 照合実行機能ヘルパー ---
function applyComparisonBorder(selectionCoords) {
   selectionCoords.forEach(cellData => {
     const cell = document.querySelector(`td[data-coords="${cellData.coords}"], th[data-coords="${cellData.coords}"]`);
     if(cell) cell.classList.add('comparison-cell-border');
   });
}

function applyHighlight(cellElement, highlightClass) {
  if(cellElement) cellElement.classList.add(highlightClass);
}

// (resetHighlights 関数 - 照合結果(赤緑黄)と赤枠のみリセット)
function resetHighlights() {
  document.querySelectorAll('.comparable-cell td, thead th').forEach(cell => {
    cell.classList.remove(
      'diff-highlight',
      'match-highlight',
      'unmatched-highlight',
      'comparison-cell-border'
      // 'template-highlight' はリセットしない (範囲指定は維持)
    );
  });

  // サマリーを隠し、キャッシュをリセット
  document.getElementById('result-summary-section').classList.add('hidden');
  currentDiffCount = 0;
  comparisonResultsCache = [];
}

// --- 共通ユーティリティ ---
function getCellDataFromElement(cell) {
    const coords = cell.dataset.coords;
    const rowIndex = parseInt(cell.dataset.rowIndex, 10);
    const colIndex = parseInt(cell.dataset.colIndex, 10);

    return {
        coords: coords,
        value: cell.textContent,
        row: rowIndex,
        col: colIndex
    };
}

function updateKeySelectionStatus() {
  const keySelectionStatusP = document.getElementById('key-selection-status');
  if (keySelectionStatusP) {
    keySelectionStatusP.textContent = `キー選択: 資料A: ${keySelectionCoordsA.length} セル / 資料B: ${keySelectionCoordsB.length} セル`;
  }
}

function updateSelectionStatus() {
  const dataSelectionStatusP = document.getElementById('data-selection-status');
  if (dataSelectionStatusP) {
    dataSelectionStatusP.textContent = `データ範囲: 資料A: ${selectionCoordsA.length} セル / 資料B: ${selectionCoordsB.length} セル`;
  }
}

// --- イベントリスナー登録 (Turboオフ対応) ---
document.addEventListener('DOMContentLoaded', () => {
  console.log('TraceChecker JS (DOMContentLoaded) loaded.');

  // 1. 各種DOM要素の取得
  const selectA = document.getElementById('file_a_select');
  const selectB = document.getElementById('file_b_select');
  const templateSelect = document.getElementById('template_select');
  const toggleSelectionButton = document.getElementById('toggle-selection-mode-button');
  const toggleKeySelectionModeButton = document.getElementById('toggle-key-selection-mode-button');
  const resetKeySelectionButton = document.getElementById('reset-key-selection-button');
  const resetSelectionButton = document.getElementById('reset-selection-button');
  const startComparisonButton = document.getElementById('start-comparison-button');

  // 2. テンプレート機能のセットアップ
  setupTemplateListeners();
  loadTemplates();

  // 3. アーカイブ機能のセットアップ
  setupArchiveButtonListener();

  // 4. ファイル選択・プレビュー機能のセットアップ
  if (selectA) selectA.addEventListener('change', () => updatePreview(selectA, 'A'));
  if (selectB) selectB.addEventListener('change', () => updatePreview(selectB, 'B'));

  // 5. 範囲指定モードのセットアップ
  if (toggleSelectionButton) {
    toggleSelectionButton.addEventListener('click', toggleSelectionMode);
  }
  if (toggleKeySelectionModeButton) {
    toggleKeySelectionModeButton.addEventListener('click', toggleKeySelectionMode);
  }
  if (resetKeySelectionButton) {
    resetKeySelectionButton.addEventListener('click', resetKeySelection);
  }
  if (resetSelectionButton) {
    resetSelectionButton.addEventListener('click', resetSelection);
  }

  // 6. 照合実行機能のセットアップ
  if (startComparisonButton) {
    startComparisonButton.addEventListener('click', startComparison);
  }

  // 7. セル選択リスナーのセットアップ (ドラッグ/クリックロジックを統合)
  setupSelectionListeners();

  // 8. CSVエクスポート機能のセットアップ
  const exportButton = document.getElementById('export-button');
  if (exportButton) {
    exportButton.addEventListener('click', exportResultsToCSV);
  }

  // 9. ロック解除ボタンのリスナー (ERBのbutton_toはJSではなくフォーム送信で処理されるため、ここでは不要)
  // const unlockButton = document.getElementById('unlock-project-button');
  // if (unlockButton) {
  //   // (ボタンは button_to で実装済み。機能は ProjectsController#unlock が処理)
  // }
});

// ==========================================
// 1. ファイル選択 & プレビュー機能
// ==========================================

function generatePreviewTable(docType, data) {
  const tableData = Array.isArray(data) ? data : [];

  const tableBody = document.getElementById(`table-${docType}`);
  const tableHead = tableBody ? tableBody.previousElementSibling : null;
  if (!tableBody || !tableHead) return;

  tableBody.innerHTML = '';
  tableHead.innerHTML = '';

  if (tableData.length === 0) {
    tableHead.innerHTML = '<tr><th scope="col" class="px-4 py-2">(プレビューなし)</th></tr>';
    if (data && data.errors) {
      tableBody.innerHTML = `<tr><td class="px-4 py-2 text-red-600">${data.errors[0]}</td></tr>`;
    }
    return;
  }

  // --- ヘッダー行 (tableData[0]) を描画 ---
  const headerRow = document.createElement('tr');
  tableData[0].forEach((cellText, colIndex) => {
    const th = document.createElement('th');
    th.scope = 'col';
    th.classList.add('px-4', 'py-2');
    th.textContent = cellText || "";

    th.dataset.rowIndex = 0;
    th.dataset.colIndex = colIndex;
    th.dataset.coords = `${docType}:0:${colIndex}`;
    headerRow.appendChild(th);
  });
  tableHead.appendChild(headerRow);

  // --- データ行 (tableData[1] 以降) を描画 ---
  tableData.slice(1).forEach((row, rowIndex) => {
    const actualRowIndex = rowIndex + 1;

    const tr = document.createElement('tr');
    tr.classList.add('bg-white', 'border-b', 'comparable-cell');
    tr.dataset.docType = docType;
    tr.dataset.rowIndex = actualRowIndex;

    row.forEach((cellText, colIndex) => {
      const td = document.createElement('td');
      td.classList.add('px-4', 'py-2');
      td.textContent = cellText || "";
      td.dataset.colIndex = colIndex;
      td.dataset.coords = `${docType}:${actualRowIndex}:${colIndex}`;
      tr.appendChild(td);
    });

    tableBody.appendChild(tr);
  });
}


function updatePreview(selectEl, docType) {
  const selectedOption = selectEl.options[selectEl.selectedIndex];
  const filename = selectedOption.dataset.filename;
  const blobId = selectedOption.value;
  const h3 = document.getElementById(`preview-${docType}-header`);
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  if (filename && blobId) {
    h3.textContent = `資料${docType}: ${filename} (読み込み中...)`;

    if (docType === 'A') selectedFileAId = blobId;
    else selectedFileBId = blobId;

    // ERBのパスをJavaScript変数から取得
    const previewUrl = window.traceCheckerConfig.filePreviewBasePath.replace("FILE_ID_PLACEHOLDER", blobId);

    fetch(previewUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(errorData => {
           throw new Error(errorData.errors ? errorData.errors.join(', ') : 'File processing error');
        });
      }
      return response.json();
    })
    .then(data => {
      h3.textContent = `資料${docType}: ${filename}`;
      generatePreviewTable(docType, data);

      // プレビューが更新されたら、既存の選択をクリア
      resetSelection();
      resetKeySelection();
    })
    .catch(error => {
      console.error('Error fetching file preview:', error);
      h3.textContent = `資料${docType}: ${filename} (エラー)`;
      generatePreviewTable(docType, { errors: ['ファイルの読み込みに失敗しました: ' + error.message] });
    });

  } else {
    h3.textContent = `資料${docType}: (ファイル未選択)`;
    if (docType === 'A') selectedFileAId = null;
    else selectedFileBId = null;
    generatePreviewTable(docType, []);
  }
}


// ==========================================
// 2. 範囲指定モード機能
// ==========================================

// (データ範囲選択モードの切り替え)
function toggleSelectionMode() {
  isSelectionMode = !isSelectionMode;
  const button = document.getElementById('toggle-selection-mode-button');
  const area = document.getElementById('comparison-area');

  // キー選択モードがオンならオフにする
  if (isSelectionMode && isKeySelectionMode) {
    toggleKeySelectionMode();
  }

  if (isSelectionMode) {
    button.textContent = 'データ範囲モード終了';
    button.classList.remove('bg-yellow-500', 'hover:bg-yellow-600');
    button.classList.add('bg-red-500', 'hover:bg-red-600');
    area.classList.add('selection-mode-active');
    resetHighlights(); // モード開始時、結果ハイライトはクリア
  } else {
    button.textContent = 'データ範囲モード開始';
    button.classList.remove('bg-red-500', 'hover:bg-red-600');
    button.classList.add('bg-yellow-500', 'hover:bg-yellow-600');
    area.classList.remove('selection-mode-active');
  }
}

// (キー選択モードの切り替え)
function toggleKeySelectionMode() {
  isKeySelectionMode = !isKeySelectionMode;
  const button = document.getElementById('toggle-key-selection-mode-button');
  const area = document.getElementById('comparison-area');

  // データ範囲選択モードがオンならオフにする
  if (isKeySelectionMode && isSelectionMode) {
    toggleSelectionMode(); // isSelectionMode を false にする
  }

  if (isKeySelectionMode) {
    button.textContent = 'キー選択モード終了';
    button.classList.remove('bg-blue-500', 'hover:bg-blue-600');
    button.classList.add('bg-red-500', 'hover:bg-red-600');
    area.classList.add('selection-mode-active');
  } else {
    button.textContent = 'キー選択モード開始';
    button.classList.remove('bg-red-500', 'hover:bg-red-600');
    button.classList.add('bg-blue-500', 'hover:bg-blue-600');
    area.classList.remove('selection-mode-active');
  }
}

function resetKeySelection() {
  keySelectionCoordsA = [];
  keySelectionCoordsB = [];
  document.querySelectorAll('.key-highlight').forEach(cell => {
    cell.classList.remove('key-highlight');
  });
  updateKeySelectionStatus();
}


function resetSelection() {
  selectionCoordsA = [];
  selectionCoordsB = [];
  document.querySelectorAll('.template-highlight').forEach(cell => {
    cell.classList.remove('template-highlight');
  });
  updateSelectionStatus();
}

// --- セル選択リスナー (ドラッグ/クリック統合ロジック) ---
function setupSelectionListeners() {
  const previewA = document.getElementById('preview-A');
  const previewB = document.getElementById('preview-B');
  const comparisonArea = document.getElementById('comparison-area');

  // --- ドラッグ選択用のイベント ---
  const handleMouseDown = (e) => {
    if (e.currentTarget.closest('.selection-mode-disabled')) return;

    const targetCell = e.target.closest('.comparable-cell td, thead th');
    if (!targetCell) return;

    const docType = targetCell.dataset.coords.split(':')[0];
    currentDocType = docType;

    // データ範囲選択モードの場合、ドラッグ開始
    if (isSelectionMode) {
      isDragging = true;
      dragStartCell = targetCell;

      const containerRect = document.getElementById(`preview-${docType}`).getBoundingClientRect();
      const scrollContainer = document.getElementById(`preview-${docType}`);

      dragStartOffsetX = e.clientX - containerRect.left + scrollContainer.scrollLeft;
      dragStartOffsetY = e.clientY - containerRect.top + scrollContainer.scrollTop;

      // 以前の選択ボックスを削除し、新しいボックスを作成 (一時的な視覚フィードバックのみ)
      removeSelectionBox(); // 既存のボックスを削除
      const overlay = document.getElementById(`selection-overlay-${docType}`);
      selectionBox = createSelectionBox(overlay);

      e.preventDefault();
      e.stopPropagation();
    }
  };

  // マウスムーブ: ドラッグ中
  const handleMouseMove = (e) => {
    if (!isDragging || isKeySelectionMode || !isSelectionMode) return;

    const docType = currentDocType;
    if (!docType) return;

    const container = document.getElementById(`preview-${docType}`);
    const rect = container.getBoundingClientRect();
    const scrollContainer = document.getElementById(`preview-${docType}`);

    const currentX = e.clientX - rect.left + scrollContainer.scrollLeft;
    const currentY = e.clientY - rect.top + scrollContainer.scrollTop;

    // 選択ボックスの座標を更新 (スクロール位置考慮)
    const x = Math.min(dragStartOffsetX, currentX);
    const y = Math.min(dragStartOffsetY, currentY);
    const w = Math.abs(dragStartOffsetX - currentX);
    const h = Math.abs(dragStartOffsetY - currentY);

    if (selectionBox) {
      selectionBox.style.left = `${x}px`;
      selectionBox.style.top = `${y}px`;
      selectionBox.style.width = `${w}px`;
      selectionBox.style.height = `${h}px`;
    }

    // ドラッグ中のハイライトをリアルタイムで更新
    highlightCellsInRect({ x: x, y: y, w, h }, docType);
    e.preventDefault();
  };

  // マウスアップ: ドラッグ終了/確定
  const handleMouseUp = (e) => {
    if (!isDragging) return;
    isDragging = false;

    const docTypeToSave = currentDocType;

    removeSelectionBox(); // 一時的なボックスを削除

    if (!docTypeToSave || !dragStartCell) return;

    // 小さいクリックの場合は、単一クリックとして扱う（単一選択/解除）
    const startRect = dragStartCell.getBoundingClientRect();
    const endRect = e.target.closest('.comparable-cell td, thead th')?.getBoundingClientRect() || startRect;

    const dx = Math.abs(startRect.x - endRect.x);
    const dy = Math.abs(startRect.y - endRect.y);

    if (dx < 5 && dy < 5 && isSelectionMode) {
        // 単一クリックと判断し、ドラッグハイライトをクリアしてからクリック処理を実行
        handleSingleCellToggle(e, dragStartCell, false);
        dragStartCell = null;
        return;
    }

    // 最終的な選択範囲を selectionCoords に格納 (ドラッグの場合)
    saveFinalDragSelection(docTypeToSave);
    dragStartCell = null;
    currentDocType = null;
    e.preventDefault();
  };

  // 単一クリック (キー選択/データ範囲の微調整)
  const handleClick = (e) => {
      const targetCell = e.target.closest('.comparable-cell td, thead th');
      if (!targetCell || e.currentTarget.closest('.selection-mode-disabled') || isDragging) return;

      if (isKeySelectionMode) {
           handleSingleCellToggle(e, targetCell, true);
      } else if (isSelectionMode) {
           // データ選択モードで単一クリックした場合 (累積/解除)
           handleSingleCellToggle(e, targetCell, false);
      }
  };

  // イベントリスナーを登録
  [previewA, previewB].forEach(previewEl => {
    if (previewEl) {
      previewEl.addEventListener('mousedown', handleMouseDown);
      previewEl.addEventListener('mousemove', handleMouseMove);
      previewEl.addEventListener('click', handleClick); // 単一クリック用
    }
  });
  // mousemove/mouseup は comparisonArea に移譲
  comparisonArea.addEventListener('mousemove', handleMouseMove);
  document.addEventListener('mouseup', handleMouseUp);
}

// --- ドラッグ選択ヘルパー ---
function getCellDataFromElement(cell) {
    const coords = cell.dataset.coords;
    const rowIndex = parseInt(cell.dataset.rowIndex, 10);
    const colIndex = parseInt(cell.dataset.colIndex, 10);

    return {
        coords: coords,
        value: cell.textContent,
        row: rowIndex,
        col: colIndex
    };
}

function handleSingleCellToggle(e, targetCell, isKey) {
      const coords = targetCell.dataset.coords;
      const docType = coords.split(':')[0];

      let selectionArray = isKey ? keySelectionCoordsA : selectionCoordsA;
      if (docType === 'B') selectionArray = isKey ? keySelectionCoordsB : selectionCoordsB;

      let highlightClass = isKey ? 'key-highlight' : 'template-highlight';

      const existingIndex = selectionArray.findIndex(c => c.coords === coords);

      if (existingIndex > -1) {
        selectionArray.splice(existingIndex, 1);
        targetCell.classList.remove(highlightClass);
      } else {
        selectionArray.push(getCellDataFromElement(targetCell));
        targetCell.classList.add(highlightClass);
      }

      if (isKey) updateKeySelectionStatus();
      else updateSelectionStatus();
  };

function createSelectionBox(overlayEl) {
    const box = document.createElement('div');
    box.className = 'selection-box';
    overlayEl.appendChild(box);
    return box;
}

function removeSelectionBox() {
    if (selectionBox) selectionBox.remove();
    selectionBox = null;
}

function clearDocHighlights(docType, className) {
    document.querySelectorAll(`#preview-${docType} .${className}`).forEach(cell => {
        cell.classList.remove(className);
    });
}

// ドラッグ選択範囲内のセルをハイライト
function highlightCellsInRect(rect, docType) {
    const container = document.getElementById(`preview-${docType}`);

    // 既存の累積された選択範囲をクリアせずに、新しいドラッグ範囲をハイライト
    // 既存のハイライトを保持する Map を使用
    const existingSelectionMap = new Map();
    const coordsContainer = (docType === 'A') ? selectionCoordsA : selectionCoordsB;

    // ★ 累積された青ハッチを保持 ★
    coordsContainer.forEach(cell => existingSelectionMap.set(cell.coords, true));

    const scrollContainer = document.getElementById(`preview-${docType}`);

    container.querySelectorAll('.comparable-cell td, thead th').forEach(cell => {
        const cellRect = cell.getBoundingClientRect();
        const containerRect = container.getBoundingClientRect();

        // セルのコンテナ内での相対座標 (スクロール位置考慮)
        const cellX = cellRect.left - containerRect.left + scrollContainer.scrollLeft;
        const cellY = cellRect.top - containerRect.top + scrollContainer.scrollTop;
        const cellW = cellRect.width;
        const cellH = cellRect.height;

        const selectX1 = rect.x;
        const selectY1 = rect.y;
        const selectX2 = rect.x + rect.w;
        const selectY2 = rect.y + rect.h;

        // セルと選択ボックスが交差するかどうかを判定
        const overlap = (
            selectX1 < (cellX + cellW) &&
            selectX2 > cellX &&
            selectY1 < (cellY + cellH) &&
            selectY2 > cellY
        );

        // 累積選択ロジック:
        if (overlap) {
            cell.classList.add('template-highlight');
        } else if (existingSelectionMap.has(cell.dataset.coords)) {
            // 既存の選択範囲内のセルはそのまま青ハイライトを維持
            cell.classList.add('template-highlight');
        } else {
            // 既存になく、現在のドラッグ範囲外ならクリア
            cell.classList.remove('template-highlight');
        }
    });
}

function saveFinalDragSelection(docTypeToSave) {
    const container = document.getElementById(`preview-${docTypeToSave}`);
    const coordsContainer = (docTypeToSave === 'A') ? selectionCoordsA : selectionCoordsB;

    // 1. 現在ハイライトされている全セルを一時リストに格納
    const currentHighlightedCells = new Map();
    container.querySelectorAll('.template-highlight').forEach(cell => {
        const cellData = getCellDataFromElement(cell);
        currentHighlightedCells.set(cellData.coords, cellData);
    });

    // 2. selectionCoordsA/B をこの最終リストで完全に上書き（マージではなく、最終状態を確定）
    coordsContainer.length = 0; // 配列をクリア
    currentHighlightedCells.forEach(cellData => coordsContainer.push(cellData));

    updateSelectionStatus();
}


function updateSelectionStatus() {
  const dataSelectionStatusP = document.getElementById('data-selection-status');
  if (dataSelectionStatusP) {
    dataSelectionStatusP.textContent = `データ範囲: 資料A: ${selectionCoordsA.length} セル / 資料B: ${selectionCoordsB.length} セル`;
  }
}

function updateKeySelectionStatus() {
  const keySelectionStatusP = document.getElementById('key-selection-status');
  if (keySelectionStatusP) {
    keySelectionStatusP.textContent = `キー選択: 資料A: ${keySelectionCoordsA.length} セル / 資料B: ${keySelectionCoordsB.length} セル`;
  }
}

// ==========================================
// 3. テンプレート機能 (Fetch)
// ==========================================

function setupTemplateListeners() {
  const form = document.getElementById('template-name-form');
  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const templateName = document.getElementById('template-name').value;

      // ▼▼▼ モーダルから "mapping" 情報を読み取る ▼▼▼
      const orientation = document.querySelector('input[name="mapping_orientation"]:checked').value;
      const keyIndex = document.getElementById('mapping-key-index');
      const valueIndex = document.getElementById('mapping-value-index');

      if (!keyIndex.value || !valueIndex.value) {
          alert("キーと値の列/行番号を正しく入力してください。");
          return;
      }

      const mapping = {
        key_orientation: orientation,
        key_index: parseInt(keyIndex.value, 10),
        value_index: parseInt(valueIndex.value, 10)
      };

      const range = {
        a: selectionCoordsA.map(c => c.coords),
        b: selectionCoordsB.map(c => c.coords)
      };
      saveTemplate(templateName, range, mapping);
    });
  }

  const saveButton = document.getElementById('save-template-button');
  if (saveButton) {
    saveButton.addEventListener('click', () => {
      if (saveButton.disabled) return;
      if (selectionCoordsA.length === 0 && selectionCoordsB.length === 0) {
        alert("データ範囲選択モードでセルを選択してください。");
        return;
      }

      // モーダルに現在の選択数を表示
      document.getElementById('template-modal-count-a').textContent = selectionCoordsA.length;
      document.getElementById('template-modal-count-b').textContent = selectionCoordsB.length;
      openModal('template-name-modal');
    });
  }

  const select = document.getElementById('template_select');
  if (select) {
    select.addEventListener('change', (e) => {
      applyTemplate(e.target.value);
    });
  }
}

function loadTemplates() {
  const select = document.getElementById('template_select');
  if (!select || select.disabled) return;

  fetch('/templates')
    .then(response => {
      if (!response.ok) throw new Error('Network response was not ok');
      return response.json();
    })
    .then(templates => {
      templatesCache = templates;
      select.options.length = 1;

      templates.forEach(template => {
        const option = document.createElement('option');
        option.value = template.id;
        option.textContent = template.name;
        select.appendChild(option);
      });
    })
    .catch(error => {
      console.error('Error loading templates:', error);
    });
}

// (saveTemplate を "mapping" も送信するように修正)
function saveTemplate(templateName, range, mapping) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  fetch('/templates', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({
      template: {
        name: templateName,
        range: {
          a: range.a,
          b: range.b
        },
        mapping: mapping // (mapping を追加)
      }
    })
  })
  .then(response => response.json())
  .then(newTemplate => {
    if (newTemplate.errors) {
      alert('Error saving template: ' + newTemplate.errors.join(', '));
    } else {
      closeModal('template-name-modal');
      document.getElementById('template-name-form').reset();
      loadTemplates(); // プルダウンを再読み込み
      showMessage(`テンプレート「${newTemplate.name}」を保存しました。`, 'success');
    }
  })
  .catch(error => {
    console.error('Error saving template:', error);
  });
}

// (applyTemplate を "data-key" 属性なしで動作するように修正)
function applyTemplate(templateId) {
  resetSelection();
  resetKeySelection(); // キー選択もリセット
  if (templateId === 'none') return;

  const template = templatesCache.find(t => t.id == templateId);
  if (!template || !template.range) {
     console.warn("Template data or range not found in cache.");
     return;
  }

  // (template.mapping をモーダルに反映)
  if (template.mapping) {
    document.getElementById('mapping-orientation-' + (template.mapping.key_orientation || 'column')).checked = true;
    document.getElementById('mapping-key-index').value = template.mapping.key_index || 0;
    document.getElementById('mapping-value-index').value = template.mapping.value_index || 1;
  }

  const allCoords = (template.range.a || []).concat(template.range.b || []);

  allCoords.forEach(coordsStr => {
    const cell = document.querySelector(`td[data-coords="${coordsStr}"], th[data-coords="${coordsStr}"]`);
    if (cell) {
      cell.classList.add('template-highlight');

      const docType = coordsStr.split(':')[0];
      const selectionArray = (docType === 'A') ? selectionCoordsA : selectionCoordsB;

      selectionArray.push(getCellDataFromElement(cell));
    }
  });
  updateSelectionStatus();
}


// ==========================================
// 4. 照合実行機能
// (リファクタリング: "mapping" 属性に依存)
// ==========================================

function startComparison() {
    console.log("照合実行 (順次マッチング方式)");

    // 1. 前提条件チェック
    if (selectionCoordsA.length === 0 || selectionCoordsB.length === 0) {
        alert("資料Aと資料Bの両方で、1セル以上のデータ範囲を選択してください。");
        return;
    }

    // 2. ハイライトをリセット
    document.querySelectorAll('.template-highlight').forEach(cell => {
        cell.classList.remove('template-highlight');
    });
    resetHighlights();

    // 3. 赤枠を適用
    applyComparisonBorder(selectionCoordsA);
    applyComparisonBorder(selectionCoordsB);

    // 4. 照合実行
    comparisonResultsCache = [];
    currentDiffCount = 0;
    let matchCount = 0;
    let unmatchCount = 0;

    // Bの使用済みセルを追跡するSet（coordsで管理）
    const usedBCells = new Set();

    // Aの各セルについて順次処理
    selectionCoordsA.forEach((cellDataA, indexA) => {
        const cellA = document.querySelector(`td[data-coords="${cellDataA.coords}"], th[data-coords="${cellDataA.coords}"]`);
        const valueA = cellDataA.value?.trim() || "";

        let matched = false;

        // Bの中から未使用のセルを順に探す
        for (let i = 0; i < selectionCoordsB.length; i++) {
            const cellDataB = selectionCoordsB[i];

            // すでに使用済みのBセルはスキップ
            if (usedBCells.has(cellDataB.coords)) {
                continue;
            }

            const valueB = cellDataB.value?.trim() || "";

            // 値が一致したら
            if (valueA === valueB) {
                const cellB = document.querySelector(`td[data-coords="${cellDataB.coords}"], th[data-coords="${cellDataB.coords}"]`);

                // 両方のセルを緑にする
                applyHighlight(cellA, 'match-highlight');
                applyHighlight(cellB, 'match-highlight');

                // Bのセルを使用済みとしてマーク
                usedBCells.add(cellDataB.coords);

                // カウントアップ
                matchCount++;

                // 結果を記録
                comparisonResultsCache.push({
                    key: valueA,
                    flag: 'match',
                    comment: null,
                    target_cell: {
                        a: cellDataA.coords,
                        b: cellDataB.coords
                    }
                });

                matched = true;
                break; // マッチしたらBのループを抜ける
            }
        }

        // マッチしなかった場合
        if (!matched) {
            // Aのセルを赤にする
            applyHighlight(cellA, 'diff-highlight');

            // カウントアップ
            unmatchCount++;

            // 結果を記録
            comparisonResultsCache.push({
                key: valueA,
                flag: 'unmatched_a',
                comment: null,
                target_cell: {
                    a: cellDataA.coords,
                    b: null
                }
            });
        }
    });

    // Bで使われなかったセルを黄色にする（オプション）
    let unmatchedBCount = 0;
    selectionCoordsB.forEach(cellDataB => {
        if (!usedBCells.has(cellDataB.coords)) {
            const cellB = document.querySelector(`td[data-coords="${cellDataB.coords}"], th[data-coords="${cellDataB.coords}"]`);
            applyHighlight(cellB, 'unmatched-highlight');
            unmatchedBCount++;

            comparisonResultsCache.push({
                key: cellDataB.value?.trim() || "",
                flag: 'unmatched_b',
                comment: null,
                target_cell: {
                    a: null,
                    b: cellDataB.coords
                }
            });
        }
    });

    // 5. サマリー表示
    const summaryContent = document.getElementById('summary-content');
    summaryContent.innerHTML = `
        <p class="text-green-600 font-semibold">一致: ${matchCount} 件</p>
        <p class="text-red-600">不一致 (Aのみ): ${unmatchCount} 件</p>
        <p class="text-yellow-700">未使用 (Bのみ): ${unmatchedBCount} 件</p>
        <p class="text-gray-600 text-sm mt-2">※ Aの順に照合。一度マッチしたBのセルは再利用しません。</p>
    `;
    document.getElementById('result-summary-section').classList.remove('hidden');
    currentDiffCount = unmatchCount;
}

// (buildDataset を "mapping" を使ってキーを動的に解決するように修正)
// function buildDataset(allSelectedCells, explicitKeyCells, mapping) {
//   const dataMap = new Map();

//   // (1. セルを "行" または "列" ごとにグループ化)
//   const groups = new Map();
//   const orientation = mapping["key_orientation"] || 'column';

//   // A. 選択範囲のセルをグループ化
//   allSelectedCells.forEach(cellData => {
//     const groupIndex = (orientation === 'column') ? cellData.row : cellData.col;
//     if (!groups.has(groupIndex)) groups.set(groupIndex, []);
//     groups.get(groupIndex).push(cellData);
//   });

//   // B. 明示的に選択されたキーセルをキーセットとして準備 (ユニークな座標を保持)
//   const explicitKeyMap = new Map();
//   explicitKeyCells.forEach(cellData => explicitKeyMap.set(cellData.coords, cellData));


//   // (2. グループごとに key と value を解決)
//   groups.forEach(cellsInGroup => {

//     const keyIndex = mapping["key_index"];
//     const valueIndex = mapping["value_index"];

//     let keyCell, valueCell;

//     // (1) 明示的なキーセルがグループ内にあるか (キー選択モードで選んだ場合)
//     keyCell = cellsInGroup.find(c => explicitKeyMap.has(c.coords));

//     // (2) 明示的なキーセルがない場合、テンプレートの key_index を使用
//     if (!keyCell) {
//       if (orientation === 'column') {
//         keyCell = cellsInGroup.find(c => c.col == keyIndex);
//       } else {
//         keyCell = cellsInGroup.find(c => c.row == keyIndex);
//       }
//     }

//     // (3) 値セルは常にテンプレートの value_index を使用
//     if (mapping) {
//       if (orientation === 'column') {
//         valueCell = cellsInGroup.find(c => c.col == valueIndex);
//       } else {
//         valueCell = cellsInGroup.find(c => c.row == valueIndex);
//       }
//     }

//     // (4) キーと値の両方が見つかった場合のみデータマップに追加
//     if (keyCell && valueCell) {
//       const key = keyCell.value;
//       const value = valueCell.value;
//       // 値セルのDOM要素を参照
//       const cellRef = document.querySelector(`td[data-coords="${valueCell.coords}"], th[data-coords="${valueCell.coords}"]`);

//       if (key && !dataMap.has(key)) {
//         dataMap.set(key, { value: value, cellRef: cellRef, keyCellRef: document.querySelector(`td[data-coords="${keyCell.coords}"], th[data-coords="${keyCell.coords}"]`) });
//       } else if (key) {
//         console.warn(`重複キー "${key}" が検出されました。最初の値のみを使用します。`);
//       }
//     }
//   });

//   return dataMap;
// }


function applyComparisonBorder(selectionCoords) {
   selectionCoords.forEach(cellData => {
     const cell = document.querySelector(`td[data-coords="${cellData.coords}"], th[data-coords="${cellData.coords}"]`);
     if(cell) cell.classList.add('comparison-cell-border');
   });
}

function applyHighlight(cellElement, highlightClass) {
  if(cellElement) cellElement.classList.add(highlightClass);
}

// (resetHighlights 関数 - 照合結果(赤緑黄)と赤枠のみリセット)
function resetHighlights() {
  document.querySelectorAll('.comparable-cell td, thead th').forEach(cell => {
    cell.classList.remove(
      'diff-highlight',
      'match-highlight',
      'unmatched-highlight',
      'comparison-cell-border'
      // 'template-highlight' はリセットしない (範囲指定は維持)
    );
  });

  // サマリーを隠し、キャッシュをリセット
  document.getElementById('result-summary-section').classList.add('hidden');
  currentDiffCount = 0;
  comparisonResultsCache = [];

  // (selectionCoordsA/B は「照合実行」のためにリセットしない)
}

// ==========================================
// 5. アーカイブ機能 (Fetch)
// ==========================================

function setupArchiveButtonListener() {
  const form = document.getElementById('archive-name-form');
  if (form) {
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const archiveName = document.getElementById('archive-name').value;
      saveArchive(archiveName);
    });
  }

  const saveButton = document.getElementById('save-archive-button');
  if (saveButton) {
    saveButton.addEventListener('click', () => {
      if (saveButton.disabled) return;
      if (comparisonResultsCache.length === 0) {
        alert("先に「照合実行」ボタンを押して、照合結果を生成してください。");
        return;
      }
      if (!selectedFileAId || !selectedFileBId) {
        alert("資料Aと資料Bの両方を選択してください。");
        return;
      }

      document.getElementById('archive-modal-diff-count').textContent = currentDiffCount;
      openModal('archive-name-modal');
    });
  }
}

function saveArchive(archiveName) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  // プレビューのHTMLを取得
  const tableA_HTML = document.getElementById('table-A').innerHTML;
  const tableB_HTML = document.getElementById('table-B').innerHTML;

  const archiveData = {
    name: archiveName,
    diff_count: currentDiffCount,
    file_a_id: selectedFileAId,
    file_b_id: selectedFileBId,
    // preview_data を追加
    preview_data: {
      table_a_html: tableA_HTML,
      table_b_html: tableB_HTML
    }
  };
  const resultsData = comparisonResultsCache;
  // ERBのパスをJavaScript変数から取得
  const postUrl = window.traceCheckerConfig.archiveResultsPath;

  fetch(postUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({
      archived_result: archiveData,
      results: resultsData
    })
  })
  .then(response => {
    // (サーバが 422 や 500 を返した場合)
    if (!response.ok) {
      // .json() を呼ぶ前に、テキストとしてエラーを先に確認する
      return response.text().then(text => {
         try {
           // JSONエラー (バリデーションエラーなど) の場合
           return JSON.parse(text);
         } catch (e) {
           // HTMLエラー (500 Internal Server Error など) の場合
           console.error("Server returned non-JSON error:", text);
           return { errors: ["サーバーで致命的なエラーが発生しました (500 Internal Server Error). Railsのログを確認してください。"] };
         }
      });
    }
    return response.json();
  })
  .then(data => {
    // (構文エラー 'T + を修正)
    if (data.errors) {
      alert('Error saving archive: ' + data.errors.join(', '));
    } else {
      console.log('Archive saved:', data);
      closeModal('archive-name-modal');
      document.getElementById('archive-name-form').reset();
      // is_locked = true の場合にenableLockModeを呼び出してページをロックモードにする
      if (data.is_locked) {
        enableLockMode();
        alert('証跡を保存し、ロックしました！編集は「再確認モードへ移行」ボタンから解除できます。');
      } else {
        alert('証跡を保存しました！');
      }
    }
  })
  .catch(error => {
    console.error('Error saving archive:', error);
    alert('証跡の保存中に致命的なエラーが発生しました。コンソールを確認してください。');
  });
}

// ==========================================
// 6. ユーティリティ (モーダル)
// ==========================================
function openModal(modalId) {
  const modal = document.getElementById(modalId);
  if(modal) modal.classList.remove('hidden');
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if(modal) modal.classList.add('hidden');
}

// ==========================================
// 7. CSVエクスポート機能 (新規追加)
// ==========================================
function exportResultsToCSV() {
  console.log("Exporting results to CSV...");
  if (comparisonResultsCache.length === 0) {
    alert("先に「照合実行」ボタンを押して、照合結果を生成してください。");
    return;
  }

  let csvContent = "data:text/csv;charset=utf-8,";
  // ヘッダー行 (BOM + ヘッダー)
  // (Excel for Windows がUTF-8を正しく認識するために \uFEFF (BOM) を追加)
  csvContent += "\uFEFF" + "Key,Flag,Comment,TargetCell_A,TargetCell_B\r\n";

  comparisonResultsCache.forEach(row => {
    // CSVインジェクション対策 + カンマ/改行のエスケープ
    const sanitize = (str) => {
      if (str === null || str === undefined) return '""';
      let s = String(str);
      // ダブルクォートを2重にする
      s = s.replace(/"/g, '""');
      // カンマ、改行、ダブルクォートが含まれる場合は全体をダブルクォートで囲む
      if (s.search(/("|,|\n)/g) >= 0) {
        s = `"${s}"`;
      }
      return s;
    };

    const key = sanitize(row.key);
    const flag = sanitize(row.flag);
    const comment = sanitize(row.comment); // (現在は常にnull)
    const cellA = sanitize(row.target_cell.a);
    const cellB = sanitize(row.target_cell.b);

    let csvRow = [key, flag, comment, cellA, cellB].join(",");
    csvContent += csvRow + "\r\n";
  });

  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);

  // ファイル名の生成
  const fileNameAEl = document.getElementById('file_a_select');
  const fileNameBEl = document.getElementById('file_b_select');

  const fileNameA = fileNameAEl.options[fileNameAEl.selectedIndex]?.dataset.filename || "fileA";
  const fileNameB = fileNameBEl.options[fileNameBEl.selectedIndex]?.dataset.filename || "fileB";
  const date = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  link.setAttribute("download", `TraceChecker_Result_${date}_${fileNameA}_vs_${fileNameB}.csv`);
  document.body.appendChild(link); // Required for FF

  link.click(); // This will download the data file
  document.body.removeChild(link);
}

// ==========================================
// 8. ロックモード制御 (新規追加)
// ==========================================

function enableLockMode() {
    console.log("ロックモードを有効化");

    // 1. ロック警告を表示 (既存の警告がない場合のみ追加)
    const existingLockWarning = document.getElementById('lock-warning-dynamic');
    if (!existingLockWarning) {
        const lockWarningHTML = `
            <div id="lock-warning-dynamic" class="mb-6 p-4 bg-yellow-100 border-l-4 border-yellow-500 text-yellow-800 rounded-lg shadow">
              <h3 class="font-bold text-lg">
                <svg class="w-6 h-6 inline-block mr-2 -mt-1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M10 1a4.5 4.5 0 00-4.5 4.5V9H5a2 2 0 00-2 2v6a2 2 0 002 2h10a2 2 0 002-2v-6a2 2 0 00-2-2h-.5V5.5A4.5 4.5 0 0010 1zm3 8V5.5a3 3 0 10-6 0V9h6z" clip-rule="evenodd" />
                </svg>
                証跡ロック済み
              </h3>
              <p class="mt-1">この照合単位は「確定済み」としてアーカイブ保存されているため、編集できません。</p>
              <button id="unlock-button-dynamic" class="mt-2 inline-block bg-gray-500 hover:bg-gray-600 text-white font-bold py-1 px-3 rounded-lg text-sm">
                再確認モードへ移行
              </button>
            </div>
        `;

        const header = document.querySelector('h1');
        header.insertAdjacentHTML('afterend', lockWarningHTML);

        // ロック解除ボタンのイベントリスナー
        document.getElementById('unlock-button-dynamic').addEventListener('click', () => {
            if (confirm('本当にロックを解除しますか？再度編集が可能になります。')) {
                unlockProject();
            }
        });
    }

    // 2. ファイル選択エリアを無効化
    const fieldsets = document.querySelectorAll('fieldset');
    fieldsets.forEach(fieldset => {
        fieldset.setAttribute('disabled', true);
        fieldset.querySelector('.bg-white')?.classList.add('opacity-60');
    });

    // 3. 照合実行ボタンを非表示
    const comparisonSection = document.querySelector('#start-comparison-button')?.closest('.bg-white');
    if (comparisonSection) {
        comparisonSection.classList.add('hidden');
    }

    // 4. 選択モードを無効化
    isSelectionMode = false;
    isKeySelectionMode = false;
    const comparisonArea = document.getElementById('comparison-area');
    comparisonArea.classList.add('selection-mode-disabled');
    comparisonArea.classList.remove('selection-mode-active');

    // モードボタンをリセット
    const toggleSelectionButton = document.getElementById('toggle-selection-mode-button');
    const toggleKeyButton = document.getElementById('toggle-key-selection-mode-button');
    if (toggleSelectionButton) {
        toggleSelectionButton.textContent = 'データ範囲モード開始';
        toggleSelectionButton.classList.remove('bg-red-500', 'hover:bg-red-600');
        toggleSelectionButton.classList.add('bg-yellow-500', 'hover:bg-yellow-600');
        toggleSelectionButton.disabled = true;
    }
    if (toggleKeyButton) {
        toggleKeyButton.textContent = 'キー選択モード開始';
        toggleKeyButton.classList.remove('bg-red-500', 'hover:bg-red-600');
        toggleKeyButton.classList.add('bg-blue-500', 'hover:bg-blue-600');
        toggleKeyButton.disabled = true;
    }

    // 5. テンプレート保存ボタンを無効化
    const saveTemplateButton = document.getElementById('save-template-button');
    if (saveTemplateButton) {
        saveTemplateButton.disabled = true;
    }

    // 6. アーカイブ保存ボタンを削除し、ロック解除ボタンに置き換え
    const saveArchiveButton = document.getElementById('save-archive-button');
    if (saveArchiveButton) {
        saveArchiveButton.remove();
    }
}

function unlockProject() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    // ERBのパスをJavaScript変数から取得
    const unlockUrl = window.traceCheckerConfig.unlockProjectPath;

    fetch(unlockUrl, {
        method: 'PATCH',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert('ロックを解除しました。ページを再読み込みします。');
            window.location.reload();
        } else {
            alert('ロック解除に失敗しました: ' + (data.errors || ['不明なエラー']).join(', '));
        }
    })
    .catch(error => {
        console.error('Error unlocking project:', error);
        alert('ロック解除中にエラーが発生しました。');
    });
}


function showMessage(message, type = 'info') {
  alert(message); // 一時的にalertで対応
}
