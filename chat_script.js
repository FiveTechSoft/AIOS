let sidebar, mainContent, resizeObserver;
let isSidebarOpen = false;
document.addEventListener('DOMContentLoaded', function () {
    sidebar = document.getElementById('sidebar');
    mainContent = document.getElementById('main-content');
    resizeObserver = new ResizeObserver(entries => {
        for (let entry of entries) {
            if (isSidebarOpen) {
                mainContent.style.marginLeft = entry.contentRect.width + 'px';
                mainContent.style.width = 'calc(100% - ' + entry.contentRect.width + 'px)';
            }
        }
    });
    if (sidebar) resizeObserver.observe(sidebar);
});
function toggleSidebar() {
    isSidebarOpen = !isSidebarOpen;
    if (isSidebarOpen) {
        sidebar.classList.add('open');
        mainContent.classList.add('shifted');
        mainContent.style.marginLeft = sidebar.offsetWidth + 'px';
        mainContent.style.width = 'calc(100% - ' + sidebar.offsetWidth + 'px)';
    } else {
        sidebar.classList.remove('open');
        mainContent.classList.remove('shifted');
        mainContent.style.marginLeft = '0';
        mainContent.style.width = '100%';
    }
}
let taskGroupCounter = 0;
function toggleTaskSteps(taskId) {
    var el = document.getElementById('steps-' + taskId);
    if (el) {
        if (el.style.display === 'none') {
            el.style.display = 'block';
            el.parentElement.style.backgroundColor = 'rgba(168, 85, 247, 0.2)';
            setTimeout(() => el.parentElement.style.backgroundColor = 'rgba(0,0,0,0.3)', 1000);
            el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        } else {
            el.style.display = 'none';
        }
    }
}
function renderAgentTasks(tasksJson, planId, isBase64) {
    try {
        if (isBase64) tasksJson = decodeURIComponent(escape(window.atob(tasksJson)));
        var tasks = typeof tasksJson === 'string' ? JSON.parse(tasksJson) : tasksJson;
        var container = document.getElementById('tasks-container');
        var isUpdate = false;
        var planDivId = 'plan-container-' + (planId || 'temp');
        var existingDiv = document.getElementById(planDivId);
        if (existingDiv) { isUpdate = true; }
        else {
            taskGroupCounter++;
            if (planId) planDivId = 'plan-container-' + planId;
            else planDivId = 'plan-container-gen-' + taskGroupCounter;
        }
        if (window.ui_conversations && window.ui_conversations.length > 0) {
            if (!window.ui_conversations[0].taskId) {
                window.ui_conversations[0].taskId = 'task-' + planDivId + '-0';
                renderConversations(window.ui_conversations);
            }
        }
        var html = '';
        var planTitle = 'Plan #' + taskGroupCounter;
        if (window.ui_conversations && window.ui_conversations.length > 0) {
            planTitle = window.ui_conversations[0].title;
        }

        if (!isUpdate) {
            html += `<div id="${planDivId}" style="border-bottom: 1px solid rgba(255,255,255,0.1); margin-bottom: 1rem; padding-bottom: 1rem;">
                    <div style="font-size: 0.85rem; color: #a0aec0; margin-bottom: 0.5rem; display:flex; justify-content:space-between; align-items:center;">
                        <span style="font-weight:600; color:#e2e8f0;">${planTitle} <span id="${planDivId}-time" style="font-weight:normal; margin-left:8px; color:#718096; font-size:0.75rem;">${new Date().toLocaleTimeString()}</span></span>
                        <div onclick="openContextMenu(event, 'task', '${planDivId}')" style="cursor:pointer; padding:0 5px; color:#94a3b8; font-weight:bold;">&#8942;</div>
                    </div>
                    <div id="${planDivId}-content">`;
        }
        var innerHtml = '';
        var pendingCount = 0;
        tasks.forEach(function (task, i) {
            console.log("Task Debug:", task);
            var tName = task.name || task.NAME || task.Name || task.title || task.TITLE || "Sin Título";
            var tDesc = task.description || task.DESCRIPTION || task.Description || task.descripcion || "Sin descripción";
            if (task.status !== 'completed') pendingCount++;
            var statusIcon = task.status === 'completed' ? '✅' : (task.status === 'in-progress' ? '🔄' : (task.status === 'error' ? '❌' : '⏳'));
            var statusColor = task.status === 'completed' ? '#4ade80' : (task.status === 'in-progress' ? '#fbbf24' : (task.status === 'error' ? '#ef4444' : '#a0aec0'));
            var uniqueId = 'task-' + planDivId + '-' + i;
            var isTaskChecked = task.status === 'completed' ? 'checked' : '';
            var taskTextStyle = task.status === 'completed' ? 'text-decoration:line-through;color:#94a3b8;' : 'color:#e2e8f0;';

            innerHtml += `<div class="sidebar-item" style="cursor:pointer;" onclick="toggleTaskSteps('${uniqueId}')">
                    <label style="display:flex; align-items:flex-start; gap:8px; font-size:0.85rem; cursor:pointer;" onclick="event.stopPropagation();">
                        <input type="checkbox" disabled ${isTaskChecked} style="margin-top:3px;">
                        <span style="${taskTextStyle}"><b>${tName}</b>: ${tDesc}</span>
                    </label>`;

            if (task.steps && task.steps.length > 0) {
                innerHtml += `<div id="steps-${uniqueId}" style="display:none; margin-top:0.5rem; padding-left:1.5rem;">`;
                task.steps.forEach(function (step) {
                    var sName = step.name || step.NAME || step.Name || "Paso";
                    var isChecked = step.status === 'completed' ? 'checked' : '';
                    var textStyle = step.status === 'completed' ? 'text-decoration:line-through;color:#94a3b8;' : 'color:#cbd5e1;';
                    innerHtml += `<label style="display:flex; align-items:flex-start; gap:8px; font-size:0.8rem; margin-bottom:0.4rem; cursor:pointer;">
                        <input type="checkbox" disabled ${isChecked} style="margin-top:3px;">
                        <span style="${textStyle}">${sName}</span>
                    </label>`;
                });
                innerHtml += `</div>`;
            }
            innerHtml += `</div>`;
        });
        if (isUpdate) {
            document.getElementById(planDivId + '-content').innerHTML = innerHtml;
            var timeEl = document.getElementById(planDivId + '-time');
            if (timeEl) timeEl.innerText = new Date().toLocaleTimeString();
        } else {
            html += innerHtml;
            html += `</div></div>`;
            container.innerHTML = html + container.innerHTML;
        }
        document.getElementById('task-status-counter').innerText = pendingCount + ' pending';
        if (!isSidebarOpen) toggleSidebar();
    } catch (e) { console.error('Failed to render tasks', e); }
}
function updateTaskCounter() {
    var container = document.getElementById('tasks-container');
    if (!container) return;
    var taskItems = container.querySelectorAll('.sidebar-item > label > input[type="checkbox"]');
    var pendingCount = 0;
    taskItems.forEach(function (cb) {
        if (!cb.checked) pendingCount++;
    });
    var counterEl = document.getElementById('task-status-counter');
    if (counterEl) counterEl.innerText = pendingCount + ' pending';
}
function renderConversations(convJson) {
    try {
        var convs = typeof convJson === 'string' ? JSON.parse(convJson) : convJson;
        var html = '';
        convs.forEach(function (conv) {
            html += `<div class="sidebar-item" style="cursor:pointer; padding: 0.6rem; margin-bottom: 0.3rem; background: rgba(255,255,255,0.05);" onclick="toggleTaskSteps('${conv.taskId}')">
                    <div style="display:flex; justify-content:space-between; align-items:flex-start;">
                        <div style="font-size:0.85rem; font-weight:600; color:#e2e8f0; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${conv.title}</div>
                        <div onclick="openContextMenu(event, 'conversation', '${conv.sessionId}')" style="cursor:pointer; padding:0 5px; color:#94a3b8; font-weight:bold;">&#8942;</div>
                    </div>
                    <div style="font-size:0.7rem; color:#a0aec0; margin-top:0.2rem;">${conv.date}</div>
                </div>`;
        });
        document.getElementById('conversations-container').innerHTML = html;
    } catch (e) { console.error('Failed to render conversations', e); }
}
let activeContextMenu = null;

function closeContextMenu() {
    if (activeContextMenu) {
        document.body.removeChild(activeContextMenu);
        activeContextMenu = null;
    }
}

document.addEventListener('click', function (e) {
    if (activeContextMenu && !activeContextMenu.contains(e.target)) {
        closeContextMenu();
    }
});

function openContextMenu(event, type, id) {
    event.stopPropagation();
    closeContextMenu();

    const menu = document.createElement('div');
    menu.className = 'context-menu';

    const deleteItem = document.createElement('div');
    deleteItem.className = 'context-menu-item';
    deleteItem.innerHTML = '🗑️ Eliminar';
    deleteItem.onclick = function (e) {
        e.stopPropagation();
        closeContextMenu();
        if (type === 'conversation') {
            var convToDelete = window.ui_conversations.find(c => c.sessionId === id);
            if (convToDelete && convToDelete.taskId) {
                // Extraemos el ID del contenedor (ej 'plan-container-gen-3') a partir de 'task-plan-container-gen-3-0'
                var planContainerId = convToDelete.taskId.replace(/^task-/, '').replace(/-\d+$/, '');
                var planEl = document.getElementById(planContainerId);
                if (planEl) planEl.parentNode.removeChild(planEl);
                // Si había algún taskId antiguo que no incluye 'plan-container'
                var fallbackEl = document.getElementById('plan-container-gen-' + planContainerId);
                if (fallbackEl) fallbackEl.parentNode.removeChild(fallbackEl);
            }
            window.ui_conversations = window.ui_conversations.filter(c => c.sessionId !== id);
            renderConversations(window.ui_conversations);
            if (id === current_session_id) clearChat();
        } else if (type === 'task') {
            var element = document.getElementById(id);
            if (element) element.parentNode.removeChild(element);
        }
        updateTaskCounter();
    };

    menu.appendChild(deleteItem);
    document.body.appendChild(menu);

    const rect = event.target.getBoundingClientRect();
    menu.style.top = (rect.bottom + 5) + 'px';

    if (rect.left + menu.offsetWidth > window.innerWidth) {
        menu.style.left = (rect.right - menu.offsetWidth) + 'px';
    } else {
        menu.style.left = (rect.left - (menu.offsetWidth / 2) + 10) + 'px';
    }

    activeContextMenu = menu;
}
window.onerror = function (m, u, l) { alert('Error: ' + m + ' en ' + l); };
var current_session_id = 'sess_' + Date.now();
var history_data = [];
var total_tokens = 0;
var current_attachment = null;
/* Gemini 1.5 Pro cost estimate: $1.25 per 1M prompt / $3.75 per 1M output approx -> simplified average $2.50 / 1M = $0.0000025 per token */
var cost_per_token = 0.0000025;
function handleFileSelect(event) {
    var file = event.target.files[0];
    if (!file) return;
    current_attachment = file;
    document.getElementById('attach-name').textContent = file.name;
}
function addMessage(role, text) {
    if (!text) return;
    var container = document.getElementById('chat-container');
    var div = document.createElement('div');
    div.className = 'message ' + role;

    var formatted = text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    formatted = formatted.replace(/!\[(.*?)\]\((.*?)\)/g, `<img src="$2" alt="$1" />`);
    formatted = formatted.replace(/-\s\[\s\]\s(.*)/g, `<label style="display:flex;align-items:center;gap:8px;margin-bottom:4px;"><input type="checkbox" disabled style="flex:none;width:auto;"> <span>$1</span></label>`);
    formatted = formatted.replace(/-\s\[x\]\s(.*)/g, `<label style="display:flex;align-items:center;gap:8px;margin-bottom:4px;"><input type="checkbox" checked disabled style="flex:none;width:auto;"> <span style="text-decoration:line-through;color:#a0aec0;">$1</span></label>`);
    formatted = formatted.replace(/\r\n/g, '<br>').replace(/\n/g, '<br>');

    div.innerHTML = formatted;
    container.appendChild(div);
    setTimeout(function () { container.scrollTop = container.scrollHeight; }, 50);
}
function addTyping() {
    var container = document.getElementById('chat-container');
    var div = document.createElement('div');
    div.id = 'typing-indicator';
    div.className = 'message bot typing';
    div.innerHTML = '⚙️ Pensando...';
    container.appendChild(div);
    container.scrollTop = container.scrollHeight;
}
function removeTyping() {
    var indicator = document.getElementById('typing-indicator');
    if (indicator) indicator.parentNode.removeChild(indicator);
}
async function sendMessage() {
    var input = document.getElementById('input');
    var text = input.value.trim();
    var btn = document.getElementById('send-btn');
    if (!text && !current_attachment) return;
    var attachName = current_attachment ? current_attachment.name : '';
    var msgText = text + (current_attachment ? '\n[📎 ' + attachName + ']' : '');
    addMessage('user', msgText);
    var tempTitle = text.substring(0, 30) + (text.length > 30 ? '...' : '');
    if (!tempTitle) tempTitle = 'Con Archivo: ' + attachName;
    window.ui_conversations = window.ui_conversations || [];
    var existingConv = window.ui_conversations.find(function (c) { return c.sessionId === current_session_id; });
    var convObj;
    if (existingConv) {
        convObj = existingConv;
    } else {
        convObj = { sessionId: current_session_id, title: tempTitle, date: new Date().toLocaleTimeString(), taskId: null };
        window.ui_conversations.unshift(convObj);
        renderConversations(window.ui_conversations);
    }
    if (!isSidebarOpen && window.ui_conversations.length === 1 && existingConv === undefined) {
        // Option to open sidebar automatically on the very first message if desired, 
        // though normally we want it closed unless they ask for a task.
        // We'll leave it closed to match the user request.
    }
    input.value = '';
    addTyping();
    btn.disabled = true;
    var formData = new FormData();
    formData.append('query', text);
    formData.append('session_id', current_session_id);
    formData.append('is_first', !existingConv ? '1' : '0');
    if (history_data.length > 0) formData.append('history', JSON.stringify(history_data));
    var url = 'aios.prg';

    if (current_attachment) {
        url = 'http://localhost:8080/'; // fallback if needed by proxy
        var base64Data = await new Promise((resolve) => {
            var reader = new FileReader();
            reader.onload = function (e) {
                var ds = e.target.result;
                resolve(ds.includes(',') ? ds.split(',')[1] : ds);
            };
            reader.readAsDataURL(current_attachment);
        });
        var attachObj = { name: current_attachment.name, type: current_attachment.type, data: base64Data };
        var blob = new Blob([JSON.stringify(attachObj)], { type: 'application/json' });
        formData.append('attachment', blob, current_attachment.name);
        document.getElementById('attach-name').textContent = '';
        document.getElementById('file-upload').value = '';
        current_attachment = null;
    }

    fetch(url, {
        method: 'POST',
        body: formData
    })
        .then(response => {
            removeTyping(); btn.disabled = false;
            if (!response.ok) throw new Error('Server Error: ' + response.status);
            return response.json();
        })
        .then(data => {
            if (data.success) {
                addMessage('bot', data.text);
                speakText(data.text);
                if (data.summary && !existingConv) {
                    convObj.title = data.summary;
                    renderConversations(window.ui_conversations);
                }
                history_data.push({ role: 'user', parts: [{ text: text }] });
                history_data.push({ role: 'model', parts: [{ text: data.text }] });
                if (data.usageMetadata && data.usageMetadata.totalTokenCount) {
                    total_tokens += data.usageMetadata.totalTokenCount;
                    var cost = (total_tokens * cost_per_token).toFixed(4);
                    document.getElementById('token-counter').innerHTML = `Tokens: ${total_tokens} <span class="price">$${cost}</span>`;
                }
                if (typeof data.js_eval !== 'undefined' && data.js_eval !== '') {
                    setTimeout(function () {
                        try {
                            var executeJs = new Function(data.js_eval);
                            executeJs();
                        } catch (err) {
                            console.error('JS Eval Error: ', err);
                        }
                    }, 100);
                }
            } else {
                addMessage('error', 'Error: ' + data.error);
            }
        })
        .catch(error => {
            console.error('Fetch Exception Detailed:', error);
            removeTyping(); btn.disabled = false;
            addMessage('error', 'Fetch Error: ' + error.message);
        });
}
function clearChat() {
    document.getElementById('chat-container').innerHTML = '';
    history_data = [];
    total_tokens = 0;
    current_session_id = 'sess_' + Date.now();
    document.getElementById('token-counter').innerHTML = 'Tokens: 0 <span class="price">$0.0000</span>';
    if (window.speechSynthesis) window.speechSynthesis.cancel();
}
var ttsEnabled = true;
var ttsVoices = [];
function populateVoices() {
    if (!window.speechSynthesis) return;
    ttsVoices = window.speechSynthesis.getVoices();
    var voiceSelect = document.getElementById('voice-select');
    if (!voiceSelect || ttsVoices.length === 0) return;
    var currentVal = voiceSelect.value;
    voiceSelect.innerHTML = '';

    // We want to prioritize Google's Spanish voice
    var esVoices = ttsVoices.filter(function (v) {
        return v.lang.startsWith('es') || v.name.toLowerCase().includes('google español');
    });

    if (esVoices.length > 0) {
        voiceSelect.style.display = 'block';
        var defaultIndex = esVoices.length - 1; // El usuario pidió que por defecto use la última voz de la lista
        esVoices.forEach(function (voice, index) {
            var option = document.createElement('option');
            option.textContent = voice.name + ' (' + voice.lang + ')';
            option.value = index;
            // No pisamos defaultIndex para asegurar que se quede con la última
            voiceSelect.appendChild(option);
        });

        if (currentVal === '') {
            voiceSelect.selectedIndex = defaultIndex;
        } else {
            voiceSelect.value = currentVal;
        }
    }
}
if (window.speechSynthesis) {
    populateVoices();
    if (speechSynthesis.onvoiceschanged !== undefined) {
        speechSynthesis.onvoiceschanged = populateVoices;
    }
}
function toggleTTS() {
    ttsEnabled = !ttsEnabled;
    var btn = document.getElementById('tts-btn');
    var sel = document.getElementById('voice-select');
    if (ttsEnabled) { btn.innerHTML = '🔊'; btn.style.opacity = '1'; sel.style.opacity = '1'; } else { btn.innerHTML = '🔇'; btn.style.opacity = '0.5'; sel.style.opacity = '0.5'; if (window.speechSynthesis) window.speechSynthesis.cancel(); }
}
function speakText(text) {
    if (!ttsEnabled || !window.speechSynthesis) return;
    window.speechSynthesis.cancel();
    var cleanText = text.replace(/```[\s\S]*?```/g, 'bloque de código omitido');
    cleanText = cleanText.replace(/!\[.*?\]\(data:image.*?\)/g, ' [Imagen generada] ');
    cleanText = cleanText.replace(/[*_#`]/g, '').replace(/<[^>]+>/g, '');
    cleanText = cleanText.replace(/(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])/g, '');
    var utterance = new SpeechSynthesisUtterance(cleanText);
    utterance.lang = 'es-ES'; // Set utterance language hint to Spain Spanish
    var voiceSelect = document.getElementById('voice-select');

    var esVoices = ttsVoices.filter(function (v) {
        return v.lang.startsWith('es') || v.name.toLowerCase().includes('google español');
    });

    if (esVoices.length > 0 && voiceSelect.value !== '') {
        utterance.voice = esVoices[voiceSelect.value];
    }
    window.speechSynthesis.speak(utterance);
}
var SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
var recognition = null;
var isListening = false;
if (SpeechRecognition) {
    recognition = new SpeechRecognition();
    recognition.lang = 'es-ES';
    recognition.continuous = false;
    recognition.interimResults = false;
    recognition.onstart = function () {
        isListening = true;
        document.getElementById('mic-btn').classList.add('listening');
        document.getElementById('input').placeholder = 'Escuchando...';
    };
    recognition.onresult = function (event) {
        var transcript = event.results[0][0].transcript;
        document.getElementById('input').value = transcript;
        sendMessage();
    };
    recognition.onerror = function (event) {
        console.error('Error de voz:', event.error);
        if (event.error === 'not-allowed') alert('Permiso de micrófono denegado. Revisa la configuración de permisos.');
        stopListening();
    };
    recognition.onend = function () {
        stopListening();
    };
} else {
    console.warn('Reconocimiento de voz no soportado.');
}
function toggleSpeech() {
    if (!recognition) {
        alert('API de voz no soportada en este navegador.');
        return;
    }
    if (isListening) {
        recognition.stop();
    } else {
        try {
            recognition.start();
        } catch (e) {
            console.error(e);
        }
    }
}
function stopListening() {
    isListening = false;
    var btn = document.getElementById('mic-btn');
    if (btn) btn.classList.remove('listening');
    var inp = document.getElementById('input');
    if (inp) inp.placeholder = 'Pregunta algo...';
}
