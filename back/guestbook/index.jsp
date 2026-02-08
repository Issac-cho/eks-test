<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%!
    // --- DB Setup (Declarations) ---
    String dbUrl = "jdbc:mariadb://mydb.cr2igeouslhx.ap-northeast-2.rds.amazonaws.com:3306/guestbookDB";
    String dbUser = "dbuser";
    String dbPass = "dbuser";

    // Method to create table if it doesn't exist
    public void setupTable() {
        String createSql = "CREATE TABLE IF NOT EXISTS guestbook (" +
                           "  id INT PRIMARY KEY AUTO_INCREMENT," +
                           "  nickname VARCHAR(100) NOT NULL," +
                           "  content TEXT NOT NULL," +
                           "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                           ");";
        try {
            Class.forName("org.mariadb.jdbc.Driver");
            try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
                 Statement stmt = conn.createStatement()) {
                stmt.execute(createSql);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>
<%
    // --- 1. POST Request Logic (Save new entry) ---
    if ("POST".equals(request.getMethod())) {
        
        setupTable(); // Ensure table exists
        
        request.setCharacterEncoding("UTF-8");
        String nickname = request.getParameter("nickname");
        String content = request.getParameter("content");

        if (nickname == null || nickname.trim().isEmpty()) {
            nickname = "Anonymous";
        }

        // Use PreparedStatement for security (prevents SQL Injection)
        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
             PreparedStatement pstmt = conn.prepareStatement(
                "INSERT INTO guestbook (nickname, content) VALUES (?, ?)"
             )) {
            
            pstmt.setString(1, nickname);
            pstmt.setString(2, content);
            pstmt.executeUpdate();
        }
        
        // After saving, redirect back to this page (GET request)
        // This refreshes the page and shows the new entry
        response.sendRedirect("/");
        return; // Stop processing
    }

    // --- 2. GET Request Logic (Load all entries) ---
    setupTable(); // Ensure table exists

    String selectSql = "SELECT nickname, content FROM guestbook " +
                       "WHERE id > (IFNULL((SELECT MAX(id) FROM guestbook WHERE content = 'clear'), 0)) " +
                       "ORDER BY created_at ASC";

    List<String> entries = new ArrayList<>();
    try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
         Statement stmt = conn.createStatement();
         // Order by 'created_at ASC' (oldest first, new ones at the bottom)
         ResultSet rs = stmt.executeQuery(selectSql)) {
        
        while (rs.next()) {
            String entry = "{"  + rs.getString("nickname") + " : \"" + rs.getString("content") + "\"}";
            entries.add(entry);
        }
    }
%>

<!-- ======================================================= -->
<!--             HTML / CSS / JavaScript Section             -->
<!-- ======================================================= -->

<!DOCTYPE html>
<html>
<head>
    <title>Guestbook Terminal</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
    /* --- 3. CSS (Theme & Layout) --- */
    * {
        box-sizing: border-box;
    }
    
    html, body {
        background-color: #0a0a0a; /* #000 -> #0a0a0a (약간 밝게) */
        color: #00FF88; /* #00FF41 -> #00FF88 (더 밝은 녹색) */
        font-family: 'Consolas', 'Courier New', monospace;
        overflow: hidden; 
        margin: 0;
        padding: 0;
        height: 100%;
        position: relative;
    }

    /* CRT 모니터 효과 컨테이너 */
    #crt-screen {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 1000;
        pointer-events: none;
        overflow: hidden;
    }

    /* 스캔라인 효과 (수평선) */
    .scanlines {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: linear-gradient(
            transparent 50%,
            rgba(0, 255, 65, 0.03) 50%
        );
        background-size: 100% 4px;
        pointer-events: none;
        animation: scanline 8s linear infinite;
    }

    @keyframes scanline {
        0% {
            background-position: 0 0;
        }
        100% {
            background-position: 0 100%;
        }
    }

    /* 화면 플리커 효과 (강도 증가) - 밝게 조정 */
    .screen-flicker {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.04); /* 0.08 -> 0.04 (더 밝게) */
        pointer-events: none;
        animation: flicker 0.1s infinite; /* 0.15s -> 0.1s (더 빠른 깜빡임) */
    }

    @keyframes flicker {
        0%, 100% {
            opacity: 1;
        }
        50% {
            opacity: 0.95; /* 0.98 -> 0.95 (더 강한 깜빡임) */
        }
    }

    /* 노이즈 효과 (강도 증가) */
    .screen-noise {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><filter id="noise"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="4" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(%23noise)" opacity="0.1"/></svg>'); /* 0.05 -> 0.1 */
        opacity: 0.3; /* 0.15 -> 0.3 (2배 증가) */
        pointer-events: none;
        animation: noise 0.15s infinite; /* 0.2s -> 0.15s (더 빠른 움직임) */
    }

    @keyframes noise {
        0%, 100% {
            transform: translate(0, 0);
        }
        10% {
            transform: translate(-5%, -5%);
        }
        20% {
            transform: translate(-10%, 5%);
        }
        30% {
            transform: translate(5%, -10%);
        }
        40% {
            transform: translate(-5%, 15%);
        }
        50% {
            transform: translate(-10%, 5%);
        }
        60% {
            transform: translate(15%, 0%);
        }
        70% {
            transform: translate(0%, 10%);
        }
        80% {
            transform: translate(-15%, 0%);
        }
        90% {
            transform: translate(10%, 5%);
        }
    }

    /* 곡면 화면 효과 (왜곡) - 밝게 조정 */
    .screen-curvature {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        background: 
            radial-gradient(ellipse at center, transparent 0%, rgba(0, 0, 0, 0.15) 100%), /* 0.4 -> 0.15 */
            radial-gradient(ellipse at top, transparent 0%, rgba(0, 0, 0, 0.08) 50%), /* 0.2 -> 0.08 */
            radial-gradient(ellipse at bottom, transparent 0%, rgba(0, 0, 0, 0.08) 50%); /* 0.2 -> 0.08 */
        box-shadow: 
            inset 0 0 100px rgba(0, 0, 0, 0.2), /* 0.5 -> 0.2 */
            inset 0 0 200px rgba(0, 0, 0, 0.1); /* 0.3 -> 0.1 */
    }

    /* 화면 테두리/베젤 효과 - 밝게 조정 */
    .screen-bezel {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        z-index: 1001;
        box-shadow: 
            inset 0 0 80px rgba(0, 0, 0, 0.4), /* 0.8 -> 0.4 */
            inset 0 0 20px rgba(0, 0, 0, 0.2), /* 0.6 -> 0.2 */
            0 0 100px rgba(0, 255, 65, 0.15); /* 0.1 -> 0.15 (더 밝은 글로우) */
        border: 20px solid #2a2a2a; /* #1a1a1a -> #2a2a2a (더 밝게) */
    }

    /* 빔 효과 (화면 상단에서 내려오는 빛) */
    .screen-beam {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 2px;
        background: linear-gradient(
            to bottom,
            transparent,
            rgba(0, 255, 65, 0.1),
            transparent
        );
        pointer-events: none;
        animation: beam 3s linear infinite;
    }

    @keyframes beam {
        0% {
            top: -2px;
            opacity: 0;
        }
        50% {
            opacity: 1;
        }
        100% {
            top: 100%;
            opacity: 0;
        }
    }

    /* 화면 반사 효과 */
    .screen-reflection {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 50%;
        background: linear-gradient(
            to bottom,
            rgba(255, 255, 255, 0.03) 0%,
            transparent 100%
        );
        pointer-events: none;
    }

    /* 전체 화면에 CRT 효과 적용 */
    body::before {
        content: '';
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: 
            repeating-linear-gradient(
                0deg,
                rgba(0, 0, 0, 0.15),
                rgba(0, 0, 0, 0.15) 1px,
                transparent 1px,
                transparent 2px
            );
        pointer-events: none;
        z-index: 999;
        animation: scanlineMove 10s linear infinite;
    }

    @keyframes scanlineMove {
        0% {
            transform: translateY(0);
        }
        100% {
            transform: translateY(100%);
        }
    }

    /* 파티클 배경 효과 */
    #particles {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 0;
        pointer-events: none;
    }

    .particle {
        position: absolute;
        width: 2px;
        height: 2px;
        background: #00FF41;
        border-radius: 50%;
        opacity: 0.6;
        animation: float 15s infinite ease-in-out;
        box-shadow: 0 0 6px #00FF41;
    }

    @keyframes float {
        0%, 100% {
            transform: translateY(0) translateX(0);
            opacity: 0.6;
        }
        50% {
            transform: translateY(-100px) translateX(50px);
            opacity: 0.2;
        }
    }

    /* Pixel Trail 효과 */
    #pixel-trail {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 5;
        pointer-events: none;
        overflow: hidden;
    }

    .pixel-trail-dot {
        position: absolute;
        width: 4px;
        height: 4px;
        background: #00FF41;
        border-radius: 1px;
        pointer-events: none;
        box-shadow: 
            0 0 4px #00FF41,
            0 0 8px rgba(0, 255, 65, 0.6),
            0 0 12px rgba(0, 255, 65, 0.4);
        animation: pixelFade 0.8s ease-out forwards;
    }

    @keyframes pixelFade {
        0% {
            opacity: 1;
            transform: scale(1) translate(0, 0);
        }
        100% {
            opacity: 0;
            transform: scale(0.3) translate(var(--dx, 0), var(--dy, 0));
        }
    }

    /* 커서 스타일 (선택사항) */
    body {
        cursor: none;
        /* CRT 화면 왜곡 효과 */
        transform: perspective(1000px) rotateX(2deg);
        transform-origin: center center;
    }

    .custom-cursor {
        position: fixed;
        width: 8px;
        height: 8px;
        background: #00FF41;
        border-radius: 50%;
        pointer-events: none;
        z-index: 9999;
        box-shadow: 
            0 0 10px #00FF41,
            0 0 20px rgba(0, 255, 65, 0.8);
        transform: translate(-50%, -50%);
        transition: transform 0.1s ease-out;
    }

    /* 로그 컨테이너 - index.jsp 스타일 유지 (top: 0, flex-start) */
    #log-container {
        position: absolute;
        top: 0;
        left: 10px;
        right: 10px;
        max-height: 100vh;
        overflow: hidden;
        display: flex;
        flex-wrap: wrap;
        align-content: flex-end; /* index.jsp 스타일 */
        z-index: 1;
        padding: 20px;
    }

    /* 각 로그 엔트리 - index.jsp 스타일 (word-break 등) */
    .log-entry {
        line-height: 1.5;
        font-size: 1.2em;
        overflow-wrap: break-word;
        word-wrap: break-word;
        word-break: break-all;
        color: #00FF88; /* 기본 색상을 더 밝게 */
        text-shadow: 0 0 10px #00FF88, 0 0 20px #00FF88, 0 0 30px #00FF88; /* 더 밝은 글로우 */
    }

    /* 폼 컨테이너 - 글리치 효과 (밝게 조정) */
    .form-container {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: linear-gradient(135deg, rgba(0, 255, 136, 0.15) 0%, rgba(10, 10, 10, 0.85) 100%); /* 더 밝은 배경 */
        padding: 30px;
        border-radius: 10px;
        z-index: 10;
        border: 2px solid #00FF88; /* 더 밝은 테두리 */
        box-shadow: 
            0 0 20px #00FF88, /* 더 밝은 글로우 */
            0 0 40px rgba(0, 255, 136, 0.4), /* 더 밝은 글로우 */
            inset 0 0 20px rgba(0, 255, 136, 0.15); /* 더 밝은 내부 글로우 */
        backdrop-filter: blur(10px);
        animation: glow 2s ease-in-out infinite alternate;
        transition: all 0.3s ease;
    }

    .form-container:hover {
        box-shadow: 
            0 0 30px #00FF88, /* 더 밝은 호버 글로우 */
            0 0 60px rgba(0, 255, 136, 0.6), /* 더 밝은 호버 글로우 */
            inset 0 0 30px rgba(0, 255, 136, 0.25); /* 더 밝은 내부 글로우 */
        transform: translate(-50%, -50%) scale(1.02);
    }

    @keyframes glow {
        from {
            box-shadow: 
                0 0 20px #00FF88, /* 더 밝은 글로우 */
                0 0 40px rgba(0, 255, 136, 0.4), /* 더 밝은 글로우 */
                inset 0 0 20px rgba(0, 255, 136, 0.15); /* 더 밝은 내부 글로우 */
        }
        to {
            box-shadow: 
                0 0 30px #00FF88, /* 더 밝은 글로우 */
                0 0 60px rgba(0, 255, 136, 0.6), /* 더 밝은 글로우 */
                inset 0 0 30px rgba(0, 255, 136, 0.25); /* 더 밝은 내부 글로우 */
        }
    }

    .form-container h2 {
        margin-top: 0;
        margin-bottom: 20px;
        text-align: center;
        font-size: 2.6em;
        color: #00FF88; /* 더 밝은 색상 */
        text-shadow: 0 0 10px #00FF88; /* 더 밝은 글로우 */
        animation: titleGlow 2s ease-in-out infinite alternate;
    }
    .form-container h3 {
        margin-top: 0;
        margin-bottom: 15px;
        text-align: center;
        font-size: 1.0em;
        color: #00FF88; /* 더 밝은 색상 */
        text-shadow: 0 0 8px #00FF88; /* 더 밝은 글로우 */
    }

    @keyframes titleGlow {
        from { text-shadow: 0 0 10px #00FF88; }
        to { text-shadow: 0 0 20px #00FF88, 0 0 30px #00FF88; } /* 더 밝은 글로우 */
    }

    .form-container input,
    .form-container textarea {
        width: 100%;
        padding: 12px;
        margin-bottom: 15px;
        border: 2px solid #00FF88; /* 더 밝은 테두리 */
        border-radius: 5px;
        background-color: rgba(10, 10, 10, 0.6); /* 더 밝은 배경 */
        color: #00FF88; /* 더 밝은 텍스트 */
        font-family: 'Consolas', 'Courier New', monospace;
        font-size: 1em;
        transition: all 0.3s ease;
        outline: none;
    }

    .form-container input:focus,
    .form-container textarea:focus {
        border-color: #00FFAA; /* 더 밝은 포커스 테두리 */
        box-shadow: 
            0 0 15px rgba(0, 255, 136, 0.6), /* 더 밝은 포커스 글로우 */
            inset 0 0 10px rgba(0, 255, 136, 0.15); /* 더 밝은 내부 글로우 */
        background-color: rgba(10, 10, 10, 0.8); /* 더 밝은 포커스 배경 */
        transform: scale(1.02);
    }

    .form-container input::placeholder,
    .form-container textarea::placeholder {
        color: rgba(0, 255, 136, 0.6); /* 더 밝은 플레이스홀더 */
    }

    .form-container button {
        width: 100%;
        padding: 12px;
        background: linear-gradient(135deg, #00FF41 0%, #00CC33 100%);
        color: #000;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        font-weight: bold;
        font-size: 1.1em;
        font-family: 'Consolas', 'Courier New', monospace;
        text-transform: uppercase;
        letter-spacing: 2px;
        transition: all 0.3s ease;
        position: relative;
        overflow: hidden;
        box-shadow: 0 0 20px rgba(0, 255, 65, 0.5);
    }

    .form-container button::before {
        content: '';
        position: absolute;
        top: 50%;
        left: 50%;
        width: 0;
        height: 0;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.3);
        transform: translate(-50%, -50%);
        transition: width 0.6s, height 0.6s;
    }

    .form-container button:hover::before {
        width: 300px;
        height: 300px;
    }

    .form-container button:hover {
        transform: translateY(-2px);
        box-shadow: 0 5px 30px rgba(0, 255, 65, 0.8);
        background: linear-gradient(135deg, #00FF88 0%, #00FF41 100%);
    }

    .form-container button:active {
        transform: translateY(0);
        box-shadow: 0 2px 15px rgba(0, 255, 65, 0.6);
    }

    .form-container button span {
        position: relative;
        z-index: 1;
    }

    /* 로딩 애니메이션 */
    .loading {
        display: inline-block;
        width: 20px;
        height: 20px;
        border: 3px solid rgba(0, 255, 65, 0.3);
        border-top-color: #00FF41;
        border-radius: 50%;
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        to { transform: rotate(360deg); }
    }

    /* 반응형 디자인 */
    @media (max-width: 768px) {
        .form-container {
            width: 90%;
            padding: 20px;
        }
        
        .log-entry {
            font-size: 1em;
        }
    }
</style>
</head>
<body>
    <!-- 파티클 배경 -->
    <div id="particles"></div>

    <!-- Pixel Trail 컨테이너 -->
    <div id="pixel-trail"></div>

    <!-- 커스텀 커서 -->
    <div class="custom-cursor" id="customCursor"></div>

    <!-- CRT 모니터 효과 -->
    <div id="crt-screen">
        <div class="scanlines"></div>
        <div class="screen-flicker"></div>
        <div class="screen-noise"></div>
        <div class="screen-curvature"></div>
        <div class="screen-beam"></div>
        <div class="screen-reflection"></div>
    </div>
    <div class="screen-bezel"></div>

    <!-- --- 4. HTML (Log Container + Form) --- -->
    <div id="log-container">
        <!-- Log entries will be added here by JavaScript -->
    </div>

    <div class="form-container">
        <h2>THE VOID</h2>
        <h3>고요 속의 외침...</h3>
	<form id="guestbookForm" action="index.jsp" method="POST">
            <input type="text" name="nickname" placeholder="Nickname" maxlength="20" autocomplete="off">
            <br>
            <input type="text" name="content" placeholder="Write something..." required maxlength="100" autocomplete="off">
            <br>
            <button type="submit">
                <span>Submit</span>
            </button>
        </form>
    </div>

    <!-- --- 5. JavaScript (Render the Log) - index.jsp 방식 사용 --- -->
    <script>
        // (5-1) Get data from JSP (Java)
        const guestbookEntries = [
            <% 
            for (int i = 0; i < entries.size(); i++) {
                String entry = entries.get(i).replace("\"", "\\\""); 
                out.print("\"" + entry + "\"");
                if (i < entries.size() - 1) {
                    out.print(",");
                }
            }
            %>
        ];

        // 파티클 생성
        function createParticles() {
            const particlesContainer = document.getElementById('particles');
            const particleCount = 50;
            
            for (let i = 0; i < particleCount; i++) {
                const particle = document.createElement('div');
                particle.className = 'particle';
                particle.style.left = Math.random() * 100 + '%';
                particle.style.top = Math.random() * 100 + '%';
                particle.style.animationDelay = Math.random() * 15 + 's';
                particle.style.animationDuration = (10 + Math.random() * 10) + 's';
                particlesContainer.appendChild(particle);
            }
        }

        // Pixel Trail 효과
        class PixelTrail {
            constructor() {
                this.trailContainer = document.getElementById('pixel-trail');
                this.lastX = 0;
                this.lastY = 0;
                this.trailLength = 15; // 트레일 길이
                this.spacing = 8; // 픽셀 간격
                this.points = [];
                this.init();
            }

            init() {
                document.addEventListener('mousemove', (e) => this.onMouseMove(e));
                document.addEventListener('mouseleave', () => this.clearTrail());
            }

            onMouseMove(e) {
                const x = e.clientX;
                const y = e.clientY;

                // 커스텀 커서 업데이트
                const cursor = document.getElementById('customCursor');
                if (cursor) {
                    cursor.style.left = x + 'px';
                    cursor.style.top = y + 'px';
                }

                // 포인트 추가
                this.points.push({ x, y, time: Date.now() });

                // 오래된 포인트 제거
                const now = Date.now();
                this.points = this.points.filter(point => now - point.time < 500);

                // 픽셀 생성
                this.createPixels(x, y);
            }

            createPixels(x, y) {
                // 이전 위치와의 거리 계산
                const dx = x - this.lastX;
                const dy = y - this.lastY;
                const distance = Math.sqrt(dx * dx + dy * dy);

                if (distance > this.spacing) {
                    // 여러 픽셀 생성 (트레일 효과)
                    const steps = Math.floor(distance / this.spacing);
                    
                    for (let i = 0; i < steps; i++) {
                        const ratio = i / steps;
                        const px = this.lastX + dx * ratio;
                        const py = this.lastY + dy * ratio;
                        
                        this.createPixel(px, py, dx, dy);
                    }
                } else {
                    this.createPixel(x, y, dx, dy);
                }

                this.lastX = x;
                this.lastY = y;
            }

            createPixel(x, y, dx, dy) {
                const pixel = document.createElement('div');
                pixel.className = 'pixel-trail-dot';
                pixel.style.left = x + 'px';
                pixel.style.top = y + 'px';
                
                // 랜덤한 방향으로 흩어지는 효과
                const randomAngle = Math.random() * Math.PI * 2;
                const randomDistance = Math.random() * 20;
                const randomDx = Math.cos(randomAngle) * randomDistance;
                const randomDy = Math.sin(randomAngle) * randomDistance;
                
                pixel.style.setProperty('--dx', randomDx + 'px');
                pixel.style.setProperty('--dy', randomDy + 'px');
                
                // 랜덤한 크기와 색상 변화
                const size = 3 + Math.random() * 3;
                pixel.style.width = size + 'px';
                pixel.style.height = size + 'px';
                
                // 색상 변화 (녹색 계열)
                const hue = 120 + Math.random() * 20 - 10; // 110-130
                const saturation = 80 + Math.random() * 20;
                const lightness = 40 + Math.random() * 20;
                pixel.style.background = `hsl(${hue}, ${saturation}%, ${lightness}%)`;
                
                this.trailContainer.appendChild(pixel);

                // 애니메이션 후 제거
                setTimeout(() => {
                    if (pixel.parentNode) {
                        pixel.parentNode.removeChild(pixel);
                    }
                }, 800);
            }

            clearTrail() {
                this.points = [];
                const pixels = this.trailContainer.querySelectorAll('.pixel-trail-dot');
                pixels.forEach(pixel => pixel.remove());
            }
        }

        // CRT 모니터 추가 효과
        function initCRTEffects() {
            // 주기적인 화면 깜빡임 (강도 증가: opacity 높임, 빈도 증가)
            setInterval(() => {
                const flicker = document.querySelector('.screen-flicker');
                if (flicker) {
                    flicker.style.opacity = '0.15'; // 0.05 -> 0.15 (3배 증가)
                    setTimeout(() => {
                        flicker.style.opacity = '0.1'; // 0.03 -> 0.1 (3배 증가)
                    }, 50);
                }
            }, 1500 + Math.random() * 1000); // 3000-5000ms -> 1500-2500ms (더 자주 깜빡임)

            // 랜덤 노이즈 강도 변화 (강도 증가)
            setInterval(() => {
                const noise = document.querySelector('.screen-noise');
                if (noise) {
                    noise.style.opacity = (0.2 + Math.random() * 0.2).toString(); // 0.1-0.2 -> 0.2-0.4 (2배 증가)
                }
            }, 300); // 500ms -> 300ms (더 빠른 변화)

            // 화면 진동 효과 (빈도 증가)
            setInterval(() => {
                if (Math.random() > 0.9) { // 0.95 -> 0.9 (더 자주 진동)
                    document.body.style.transform = 'perspective(1000px) rotateX(2deg) translateX(' + (Math.random() - 0.5) * 4 + 'px)'; // 2px -> 4px (진동 강도 증가)
                    setTimeout(() => {
                        document.body.style.transform = 'perspective(1000px) rotateX(2deg)';
                    }, 100);
                }
            }, 1500); // 2000ms -> 1500ms (더 자주 체크)
        }

        // 초기화
        window.addEventListener('DOMContentLoaded', function() {
            // 파티클 생성
            createParticles();
            
            // Pixel Trail 초기화
            const pixelTrail = new PixelTrail();
            
            // CRT 효과 초기화
            initCRTEffects();
            
            // (5-2) Get the log container
            const logContainer = document.getElementById('log-container');

            // (5-3) Add each entry to the log - index.jsp 방식 (모든 로그를 하나의 span으로)
            const allLogs = guestbookEntries.join(' ');
            const singleLogBlock = document.createElement('span');
            singleLogBlock.className = 'log-entry';
            singleLogBlock.textContent = allLogs;
            logContainer.appendChild(singleLogBlock);

            // 마우스 움직임에 따른 파티클 효과
            document.addEventListener('mousemove', function(e) {
                const particles = document.querySelectorAll('.particle');
                particles.forEach((particle, index) => {
                    if (index % 5 === 0) {
                        const rect = particle.getBoundingClientRect();
                        const x = e.clientX - rect.left;
                        const y = e.clientY - rect.top;
                        const distance = Math.sqrt(x * x + y * y);
                        
                        if (distance < 100) {
                            const force = (100 - distance) / 100;
                            particle.style.transform = `translate(${x * force * 0.1}px, ${y * force * 0.1}px)`;
                        }
                    }
                });
            });

            // 폼 제출 애니메이션
            document.getElementById('guestbookForm').addEventListener('submit', function(e) {
                const button = this.querySelector('button');
                const originalText = button.querySelector('span').textContent;
                button.querySelector('span').textContent = 'Sending...';
                button.disabled = true;
                button.style.opacity = '0.7';
            });

            // 키보드 입력 효과
            const inputs = document.querySelectorAll('input, textarea');
            inputs.forEach(input => {
                input.addEventListener('keydown', function() {
                    this.style.boxShadow = '0 0 20px rgba(0, 255, 65, 0.8)';
                });
                
                input.addEventListener('keyup', function() {
                    setTimeout(() => {
                        this.style.boxShadow = '';
                    }, 100);
                });
            });

            // 입력 필드에서는 기본 커서 표시
            inputs.forEach(input => {
                input.addEventListener('mouseenter', function() {
                    document.body.style.cursor = 'text';
                    document.getElementById('customCursor').style.display = 'none';
                });
                
                input.addEventListener('mouseleave', function() {
                    document.body.style.cursor = 'none';
                    document.getElementById('customCursor').style.display = 'block';
                });
            });
        });

        // 페이지 언로드 시 애니메이션
        window.addEventListener('beforeunload', function() {
            document.body.style.opacity = '0';
            document.body.style.transition = 'opacity 0.3s';
        });
    </script>

</body>
</html>

