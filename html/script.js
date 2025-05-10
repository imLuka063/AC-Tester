window.addEventListener('DOMContentLoaded', () => {
    // Menü öffnen/schließen
    const closeBtn = document.getElementById('closeBtn');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            fetch('https://Luka_Cheat/close', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            document.getElementById('cheat-container').style.display = 'none';
        });
    }
    window.addEventListener('message', (event) => {
        if (event.data.action === 'open') {
            document.getElementById('cheat-container').style.display = 'block';
        }
    });
    document.getElementById('cheat-container').style.display = 'none';

    // Checkbox-Events für Cheats
    const cheats = ['aimbot', 'drawlines', 'drawlinesnpc', 'nametags', 'aimbotnpc', 'noclip'];
    cheats.forEach(cheat => {
        const el = document.getElementById(cheat);
        if (el) {
            el.addEventListener('change', (e) => {
                fetch(`https://Luka_Cheat/toggleCheat`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ cheat: cheat, enabled: e.target.checked })
                });
            });
        }
    });

    // DrawLines Settings anzeigen/verstecken
    const drawlinesCheckbox = document.getElementById('drawlines');
    const drawlinesSettings = document.getElementById('drawlines-settings');
    const drawlinesDistance = document.getElementById('drawlines-distance');
    const drawlinesDistanceValue = document.getElementById('drawlines-distance-value');
    if (drawlinesCheckbox && drawlinesSettings && drawlinesDistance && drawlinesDistanceValue) {
        drawlinesCheckbox.addEventListener('change', (e) => {
            drawlinesSettings.style.display = e.target.checked ? 'block' : 'none';
            if (e.target.checked) {
                fetch('https://Luka_Cheat/drawlinesDistance', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ distance: Number(drawlinesDistance.value) })
                });
            }
        });
        drawlinesDistance.addEventListener('input', (e) => {
            drawlinesDistanceValue.textContent = e.target.value;
            fetch('https://Luka_Cheat/drawlinesDistance', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ distance: Number(e.target.value) })
            });
        });
        drawlinesDistanceValue.textContent = drawlinesDistance.value;
        drawlinesSettings.style.display = drawlinesCheckbox.checked ? 'block' : 'none';
    }

    // Warp Into Closed Vehicle
    const warpBtn = document.getElementById('warpBtn');
    if (warpBtn) {
        warpBtn.addEventListener('click', () => {
            fetch('https://Luka_Cheat/warpIntoClosedVehicle', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        });
    }

    // FOV Kreis Einstellungen und Overlay
    const fovSlider = document.getElementById('fov-slider');
    const fovSliderValue = document.getElementById('fov-slider-value');
    const fovOverlayCheckbox = document.getElementById('fovoverlay');
    const fovCanvas = document.getElementById('fov-canvas');
    let showFovOverlayState = true;
    let currentFov = 60;
    let currentFovColor = '#e74c3c';
    let currentDrawlinesColor = '#ff0000';
    let currentDrawlinesNpcColor = '#00ff00';

    function drawFovNuiCircle() {
        if (!fovCanvas) return;
        if (!showFovOverlayState) {
            fovCanvas.width = window.innerWidth;
            fovCanvas.height = window.innerHeight;
            const ctx = fovCanvas.getContext('2d');
            ctx.clearRect(0, 0, fovCanvas.width, fovCanvas.height);
            return;
        }
        fovCanvas.width = window.innerWidth;
        fovCanvas.height = window.innerHeight;
        const ctx = fovCanvas.getContext('2d');
        ctx.clearRect(0, 0, fovCanvas.width, fovCanvas.height);
        const centerX = fovCanvas.width / 2;
        const centerY = fovCanvas.height / 2;
        const baseRadius = fovCanvas.height * 0.35;
        const radius = baseRadius * (currentFov / 90);
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
        ctx.strokeStyle = currentFovColor;
        ctx.lineWidth = 3;
        ctx.shadowColor = 'rgba(0,0,0,0.3)';
        ctx.shadowBlur = 6;
        ctx.stroke();
    }
    window.addEventListener('resize', drawFovNuiCircle);
    if (fovSlider && fovSliderValue) {
        fovSlider.addEventListener('input', (e) => {
            fovSliderValue.textContent = e.target.value;
            currentFov = Number(e.target.value);
            drawFovNuiCircle();
            fetch('https://Luka_Cheat/fovSlider', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ fov: currentFov })
            });
        });
        fovSliderValue.textContent = fovSlider.value;
        currentFov = Number(fovSlider.value);
        drawFovNuiCircle();
    }
    if (fovOverlayCheckbox) {
        fovOverlayCheckbox.addEventListener('change', (e) => {
            showFovOverlayState = e.target.checked;
            drawFovNuiCircle();
            fetch('https://Luka_Cheat/fovOverlay', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ enabled: e.target.checked })
            });
        });
        showFovOverlayState = fovOverlayCheckbox.checked;
        drawFovNuiCircle();
    }

    // Farbwahl für FOV, DrawLines, DrawLines NPC
    const fovColor = document.getElementById('fov-color');
    const drawlinesColor = document.getElementById('drawlines-color');
    const drawlinesNpcColor = document.getElementById('drawlinesnpc-color');

    if (fovColor) {
        fovColor.addEventListener('input', (e) => {
            currentFovColor = e.target.value;
            drawFovNuiCircle();
            fetch('https://Luka_Cheat/fovColor', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ color: currentFovColor })
            });
        });
    }
    if (drawlinesColor) {
        drawlinesColor.addEventListener('input', (e) => {
            currentDrawlinesColor = e.target.value;
            fetch('https://Luka_Cheat/drawlinesColor', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ color: currentDrawlinesColor })
            });
        });
    }
    if (drawlinesNpcColor) {
        drawlinesNpcColor.addEventListener('input', (e) => {
            currentDrawlinesNpcColor = e.target.value;
            fetch('https://Luka_Cheat/drawlinesNpcColor', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ color: currentDrawlinesNpcColor })
            });
        });
    }

    // Event-Executer
    const execInput = document.getElementById('exec-input');
    const execBtn = document.getElementById('exec-btn');
    if (execInput && execBtn) {
        execBtn.addEventListener('click', () => {
            const code = execInput.value.trim();
            if (code.length > 0) {
                fetch('https://Luka_Cheat/execCode', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ code: code })
                });
                execInput.value = '';
            }
        });
    }

    // Client Dump Button (Platzhalter)
    const clientDumpBtn = document.getElementById('client-dump-btn');
    if (clientDumpBtn) {
        clientDumpBtn.addEventListener('click', () => {
            alert('Client Dump ist in einer normalen Resource nicht möglich. (Platzhalter)');
            // Hier könnte später ein echtes Dump-Event getriggert werden
        });
    }
}); 