// ============================================================
// Super Mario Runner - A Mario-style endless runner game
// ============================================================

const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// ------------------------------------------------------------
// Constants
// ------------------------------------------------------------
const CANVAS_W = canvas.width;
const CANVAS_H = canvas.height;
const GROUND_Y = CANVAS_H - 64;
const GRAVITY = 0.6;
const JUMP_FORCE = -12;
const DOUBLE_JUMP_FORCE = -10;
const BASE_SPEED = 4;
const MAX_SPEED = 10;
const SPEED_INCREMENT = 0.0005;

// Colors (pixel-art inspired palette)
const COLORS = {
    sky: '#5c94fc',
    skyGradient: '#3878d8',
    ground: '#8B5E3C',
    groundDark: '#6B3F1F',
    groundTop: '#4CAF50',
    groundTopDark: '#388E3C',
    brick: '#C84C09',
    brickDark: '#A03000',
    pipe: '#30A030',
    pipeDark: '#207020',
    pipeLight: '#50D050',
    coin: '#FFD700',
    coinDark: '#DAA520',
    cloudWhite: '#F0F0F0',
    cloudLight: '#E0E8F0',
    hillGreen: '#48A848',
    hillDark: '#308030',
    bushGreen: '#3CB43C',
    bushDark: '#2A8A2A',
    text: '#FFFFFF',
    textShadow: '#000000',
    mario: {
        red: '#E04040',
        redDark: '#B02020',
        skin: '#FFB888',
        skinDark: '#D09060',
        brown: '#8B4513',
        brownDark: '#6B2F0F',
        blue: '#4040D0',
        blueDark: '#2828A0',
        white: '#FFFFFF',
        yellow: '#FFD700',
    },
    goomba: {
        body: '#C07030',
        bodyDark: '#8B4513',
        feet: '#301810',
        white: '#FFFFFF',
        black: '#000000',
    },
};

// ------------------------------------------------------------
// Game State
// ------------------------------------------------------------
let gameState = 'menu'; // 'menu', 'playing', 'gameover'
let score = 0;
let highScore = parseInt(localStorage.getItem('marioRunnerHighScore') || '0');
let gameSpeed = BASE_SPEED;
let frameCount = 0;
let shakeTimer = 0;
let shakeIntensity = 0;

// ------------------------------------------------------------
// Input handling
// ------------------------------------------------------------
const keys = {};

document.addEventListener('keydown', (e) => {
    keys[e.code] = true;
    if (e.code === 'Space' || e.code === 'ArrowUp') {
        e.preventDefault();
        if (gameState === 'menu') {
            startGame();
        } else if (gameState === 'playing') {
            player.jump();
        } else if (gameState === 'gameover') {
            startGame();
        }
    }
});

document.addEventListener('keyup', (e) => {
    keys[e.code] = false;
});

canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    if (gameState === 'menu') {
        startGame();
    } else if (gameState === 'playing') {
        player.jump();
    } else if (gameState === 'gameover') {
        startGame();
    }
});

canvas.addEventListener('click', () => {
    if (gameState === 'menu') {
        startGame();
    } else if (gameState === 'playing') {
        player.jump();
    } else if (gameState === 'gameover') {
        startGame();
    }
});

// ------------------------------------------------------------
// Player
// ------------------------------------------------------------
const player = {
    x: 80,
    y: GROUND_Y - 32,
    width: 28,
    height: 32,
    vy: 0,
    onGround: true,
    canDoubleJump: true,
    animFrame: 0,
    animTimer: 0,
    isDead: false,
    deathTimer: 0,
    ducking: false,
    invincible: 0,

    reset() {
        this.y = GROUND_Y - this.height;
        this.vy = 0;
        this.onGround = true;
        this.canDoubleJump = true;
        this.isDead = false;
        this.deathTimer = 0;
        this.animFrame = 0;
        this.ducking = false;
        this.invincible = 0;
    },

    jump() {
        if (this.isDead) return;
        if (this.onGround) {
            this.vy = JUMP_FORCE;
            this.onGround = false;
            this.canDoubleJump = true;
        } else if (this.canDoubleJump) {
            this.vy = DOUBLE_JUMP_FORCE;
            this.canDoubleJump = false;
            particles.emit(this.x + this.width / 2, this.y + this.height, 5, '#FFFFFF', 'jump');
        }
    },

    update() {
        if (this.isDead) {
            this.deathTimer++;
            this.vy += GRAVITY * 0.5;
            this.y += this.vy;
            return;
        }

        // Ducking
        this.ducking = keys['ArrowDown'] || keys['KeyS'];

        // Gravity
        this.vy += GRAVITY;
        this.y += this.vy;

        // Ground collision
        const effectiveHeight = this.ducking ? 22 : 32;
        if (this.y + effectiveHeight >= GROUND_Y) {
            this.y = GROUND_Y - effectiveHeight;
            this.vy = 0;
            this.onGround = true;
            this.canDoubleJump = true;
        }

        // Animation
        this.animTimer++;
        if (this.animTimer > (6 - Math.floor(gameSpeed / 2))) {
            this.animFrame = (this.animFrame + 1) % 4;
            this.animTimer = 0;
        }

        if (this.invincible > 0) this.invincible--;

        this.height = this.ducking ? 22 : 32;
    },

    draw() {
        if (this.invincible > 0 && frameCount % 4 < 2) return;

        const x = Math.round(this.x);
        const y = Math.round(this.y);
        const c = COLORS.mario;

        ctx.save();

        if (this.isDead) {
            // Dead Mario - simple X eyes
            drawMarioBody(x, y, c, 0, false, true);
        } else if (!this.onGround) {
            // Jumping pose
            drawMarioBody(x, y, c, 0, false, false, true);
        } else if (this.ducking) {
            // Ducking pose
            drawMarioDucking(x, y, c);
        } else {
            // Running animation
            drawMarioBody(x, y, c, this.animFrame, true, false);
        }

        ctx.restore();
    },

    getHitbox() {
        const margin = 4;
        return {
            x: this.x + margin,
            y: this.y + margin,
            width: this.width - margin * 2,
            height: this.height - margin * 2,
        };
    },
};

function drawMarioBody(x, y, c, frame, running, dead, jumping) {
    // Hat
    ctx.fillStyle = c.red;
    ctx.fillRect(x + 4, y, 20, 4);
    ctx.fillRect(x + 2, y + 4, 24, 4);
    ctx.fillStyle = c.redDark;
    ctx.fillRect(x + 6, y + 4, 4, 4);

    // Face
    ctx.fillStyle = c.skin;
    ctx.fillRect(x + 2, y + 8, 24, 8);
    ctx.fillStyle = c.skinDark;
    ctx.fillRect(x + 22, y + 8, 4, 4);

    // Eyes
    if (dead) {
        ctx.fillStyle = '#000';
        ctx.fillRect(x + 10, y + 9, 2, 2);
        ctx.fillRect(x + 14, y + 9, 2, 2);
        ctx.fillRect(x + 12, y + 11, 2, 2);
        ctx.fillRect(x + 8, y + 11, 2, 2);
        ctx.fillRect(x + 16, y + 11, 2, 2);
    } else {
        ctx.fillStyle = '#000';
        ctx.fillRect(x + 14, y + 9, 3, 3);
        ctx.fillRect(x + 19, y + 9, 3, 3);
        // White eye shine
        ctx.fillStyle = c.white;
        ctx.fillRect(x + 15, y + 9, 1, 1);
        ctx.fillRect(x + 20, y + 9, 1, 1);
    }

    // Mustache
    ctx.fillStyle = c.brown;
    ctx.fillRect(x + 12, y + 14, 12, 2);

    // Body (overalls)
    ctx.fillStyle = c.blue;
    ctx.fillRect(x + 4, y + 16, 20, 8);
    ctx.fillStyle = c.blueDark;
    ctx.fillRect(x + 10, y + 16, 8, 8);

    // Overall straps
    ctx.fillStyle = c.yellow;
    ctx.fillRect(x + 8, y + 17, 2, 2);
    ctx.fillRect(x + 18, y + 17, 2, 2);

    // Arms
    ctx.fillStyle = c.red;
    if (jumping) {
        // Arms up when jumping
        ctx.fillRect(x, y + 10, 4, 6);
        ctx.fillRect(x + 24, y + 10, 4, 6);
    } else if (running) {
        const armOffset = (frame % 2 === 0) ? 0 : 3;
        ctx.fillRect(x - 2, y + 16 + armOffset, 6, 6);
        ctx.fillRect(x + 24, y + 16 + (frame % 2 === 0 ? 3 : 0), 6, 6);
    } else {
        ctx.fillRect(x, y + 16, 4, 8);
        ctx.fillRect(x + 24, y + 16, 4, 8);
    }

    // Legs
    ctx.fillStyle = c.blue;
    if (dead) {
        // Legs spread when dead
        ctx.fillRect(x, y + 24, 8, 8);
        ctx.fillRect(x + 20, y + 24, 8, 8);
    } else if (jumping) {
        // Legs tucked when jumping
        ctx.fillRect(x + 4, y + 24, 8, 6);
        ctx.fillRect(x + 16, y + 24, 8, 6);
        ctx.fillStyle = c.brown;
        ctx.fillRect(x + 4, y + 28, 8, 4);
        ctx.fillRect(x + 16, y + 28, 8, 4);
    } else if (running) {
        // Running legs animation
        const legFrames = [
            [[4, 24, 8, 8], [16, 24, 8, 8]],
            [[2, 24, 8, 8], [18, 24, 8, 8]],
            [[4, 24, 8, 8], [16, 24, 8, 8]],
            [[6, 24, 8, 8], [14, 24, 8, 8]],
        ];
        const lf = legFrames[frame % 4];
        ctx.fillRect(x + lf[0][0], y + lf[0][1], lf[0][2], lf[0][3]);
        ctx.fillRect(x + lf[1][0], y + lf[1][1], lf[1][2], lf[1][3]);

        // Shoes
        ctx.fillStyle = c.brown;
        ctx.fillRect(x + lf[0][0], y + 28, lf[0][2], 4);
        ctx.fillRect(x + lf[1][0], y + 28, lf[1][2], 4);
    } else {
        ctx.fillRect(x + 4, y + 24, 8, 8);
        ctx.fillRect(x + 16, y + 24, 8, 8);
        ctx.fillStyle = c.brown;
        ctx.fillRect(x + 4, y + 28, 8, 4);
        ctx.fillRect(x + 16, y + 28, 8, 4);
    }
}

function drawMarioDucking(x, y, c) {
    // Compact ducking Mario
    // Hat
    ctx.fillStyle = c.red;
    ctx.fillRect(x + 2, y, 24, 4);
    ctx.fillRect(x, y + 4, 28, 4);

    // Face
    ctx.fillStyle = c.skin;
    ctx.fillRect(x, y + 8, 28, 6);

    // Eyes
    ctx.fillStyle = '#000';
    ctx.fillRect(x + 14, y + 9, 3, 3);
    ctx.fillRect(x + 19, y + 9, 3, 3);

    // Body compressed
    ctx.fillStyle = c.blue;
    ctx.fillRect(x + 2, y + 14, 24, 4);

    // Shoes
    ctx.fillStyle = c.brown;
    ctx.fillRect(x + 2, y + 18, 10, 4);
    ctx.fillRect(x + 16, y + 18, 10, 4);
}

// ------------------------------------------------------------
// Particle System
// ------------------------------------------------------------
const particles = {
    list: [],

    emit(x, y, count, color, type) {
        for (let i = 0; i < count; i++) {
            this.list.push({
                x,
                y,
                vx: (Math.random() - 0.5) * 4,
                vy: -Math.random() * 4 - 1,
                life: 20 + Math.random() * 20,
                maxLife: 40,
                size: 2 + Math.random() * 3,
                color,
                type,
            });
        }
    },

    update() {
        for (let i = this.list.length - 1; i >= 0; i--) {
            const p = this.list[i];
            p.x += p.vx;
            p.y += p.vy;
            p.vy += 0.15;
            p.life--;
            if (p.life <= 0) {
                this.list.splice(i, 1);
            }
        }
    },

    draw() {
        for (const p of this.list) {
            const alpha = p.life / p.maxLife;
            ctx.globalAlpha = alpha;
            ctx.fillStyle = p.color;
            ctx.fillRect(Math.round(p.x), Math.round(p.y), Math.round(p.size), Math.round(p.size));
        }
        ctx.globalAlpha = 1;
    },

    clear() {
        this.list = [];
    },
};

// ------------------------------------------------------------
// Background Elements
// ------------------------------------------------------------
const clouds = [];
const hills = [];
const bushes = [];

function initBackground() {
    clouds.length = 0;
    hills.length = 0;
    bushes.length = 0;

    // Clouds
    for (let i = 0; i < 6; i++) {
        clouds.push({
            x: Math.random() * CANVAS_W * 1.5,
            y: 30 + Math.random() * 80,
            width: 60 + Math.random() * 80,
            speed: 0.2 + Math.random() * 0.3,
        });
    }

    // Hills
    for (let i = 0; i < 4; i++) {
        hills.push({
            x: i * 250 + Math.random() * 100,
            width: 150 + Math.random() * 100,
            height: 50 + Math.random() * 60,
        });
    }

    // Bushes
    for (let i = 0; i < 5; i++) {
        bushes.push({
            x: i * 200 + Math.random() * 100,
            width: 40 + Math.random() * 40,
        });
    }
}

function updateBackground() {
    // Clouds (parallax - slow)
    for (const cloud of clouds) {
        cloud.x -= cloud.speed * (gameSpeed / BASE_SPEED);
        if (cloud.x + cloud.width < 0) {
            cloud.x = CANVAS_W + Math.random() * 200;
            cloud.y = 30 + Math.random() * 80;
            cloud.width = 60 + Math.random() * 80;
        }
    }

    // Hills (parallax - medium)
    for (const hill of hills) {
        hill.x -= gameSpeed * 0.3;
        if (hill.x + hill.width < 0) {
            hill.x = CANVAS_W + Math.random() * 200;
            hill.width = 150 + Math.random() * 100;
            hill.height = 50 + Math.random() * 60;
        }
    }

    // Bushes (parallax - faster)
    for (const bush of bushes) {
        bush.x -= gameSpeed * 0.6;
        if (bush.x + bush.width < 0) {
            bush.x = CANVAS_W + Math.random() * 200;
            bush.width = 40 + Math.random() * 40;
        }
    }
}

function drawBackground() {
    // Sky gradient
    const grad = ctx.createLinearGradient(0, 0, 0, GROUND_Y);
    grad.addColorStop(0, COLORS.sky);
    grad.addColorStop(1, COLORS.skyGradient);
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, CANVAS_W, GROUND_Y);

    // Hills
    for (const hill of hills) {
        ctx.fillStyle = COLORS.hillGreen;
        ctx.beginPath();
        ctx.moveTo(hill.x, GROUND_Y);
        ctx.quadraticCurveTo(hill.x + hill.width / 2, GROUND_Y - hill.height, hill.x + hill.width, GROUND_Y);
        ctx.fill();
        ctx.fillStyle = COLORS.hillDark;
        ctx.beginPath();
        ctx.moveTo(hill.x + hill.width * 0.3, GROUND_Y);
        ctx.quadraticCurveTo(hill.x + hill.width / 2, GROUND_Y - hill.height + 10, hill.x + hill.width * 0.7, GROUND_Y);
        ctx.fill();
    }

    // Clouds
    for (const cloud of clouds) {
        drawCloud(cloud.x, cloud.y, cloud.width);
    }

    // Bushes
    for (const bush of bushes) {
        drawBush(bush.x, GROUND_Y - 16, bush.width);
    }
}

function drawCloud(x, y, w) {
    const h = w * 0.4;
    ctx.fillStyle = COLORS.cloudWhite;
    // Rounded cloud shape with pixel blocks
    const cx = Math.round(x);
    const cy = Math.round(y);
    const cw = Math.round(w);
    const ch = Math.round(h);
    ctx.fillRect(cx + cw * 0.1, cy, cw * 0.8, ch);
    ctx.fillRect(cx, cy + ch * 0.2, cw, ch * 0.6);
    ctx.fillStyle = COLORS.cloudLight;
    ctx.fillRect(cx + cw * 0.15, cy + ch * 0.5, cw * 0.7, ch * 0.3);
}

function drawBush(x, y, w) {
    ctx.fillStyle = COLORS.bushGreen;
    ctx.fillRect(x, y, w, 16);
    ctx.fillRect(x + 4, y - 8, w - 8, 8);
    ctx.fillRect(x + 10, y - 14, w - 20, 6);
    ctx.fillStyle = COLORS.bushDark;
    ctx.fillRect(x + 8, y + 4, w - 16, 8);
}

function drawGround() {
    // Grass top layer
    ctx.fillStyle = COLORS.groundTop;
    ctx.fillRect(0, GROUND_Y, CANVAS_W, 8);
    ctx.fillStyle = COLORS.groundTopDark;
    for (let i = 0; i < CANVAS_W; i += 16) {
        ctx.fillRect(i + ((frameCount * 2) % 16), GROUND_Y, 8, 4);
    }

    // Dirt layer
    ctx.fillStyle = COLORS.ground;
    ctx.fillRect(0, GROUND_Y + 8, CANVAS_W, CANVAS_H - GROUND_Y - 8);

    // Dirt pattern
    ctx.fillStyle = COLORS.groundDark;
    for (let y = GROUND_Y + 16; y < CANVAS_H; y += 16) {
        for (let x = 0; x < CANVAS_W; x += 32) {
            const offset = ((y - GROUND_Y) / 16 % 2) * 16;
            ctx.fillRect(x + offset - ((frameCount * 2) % 32), y, 12, 4);
        }
    }
}

// ------------------------------------------------------------
// Obstacles
// ------------------------------------------------------------
let obstacles = [];
let coins = [];
let spawnTimer = 0;
let minSpawnInterval = 60;
let coinSpawnTimer = 0;

function spawnObstacle() {
    const types = ['goomba', 'pipe_small', 'pipe_tall', 'brick_stack', 'flying_goomba'];
    const weights = [30, 25, 15, 15, 15];

    // Adjust weights based on score
    if (score < 500) {
        weights[4] = 0; // No flying goombas early
        weights[2] = 5; // Fewer tall pipes
    }

    const totalWeight = weights.reduce((a, b) => a + b, 0);
    let rand = Math.random() * totalWeight;
    let type = types[0];

    for (let i = 0; i < types.length; i++) {
        rand -= weights[i];
        if (rand <= 0) {
            type = types[i];
            break;
        }
    }

    const obs = { x: CANVAS_W + 20, type, passed: false };

    switch (type) {
        case 'goomba':
            obs.y = GROUND_Y - 24;
            obs.width = 24;
            obs.height = 24;
            obs.animFrame = 0;
            break;
        case 'pipe_small':
            obs.y = GROUND_Y - 40;
            obs.width = 36;
            obs.height = 40;
            break;
        case 'pipe_tall':
            obs.y = GROUND_Y - 64;
            obs.width = 36;
            obs.height = 64;
            break;
        case 'brick_stack':
            obs.y = GROUND_Y - 48;
            obs.width = 32;
            obs.height = 48;
            break;
        case 'flying_goomba':
            obs.y = GROUND_Y - 80 - Math.random() * 40;
            obs.width = 28;
            obs.height = 24;
            obs.baseY = obs.y;
            obs.animFrame = 0;
            obs.flyTimer = Math.random() * Math.PI * 2;
            break;
    }

    obstacles.push(obs);
}

function spawnCoin() {
    const y = GROUND_Y - 60 - Math.random() * 80;
    coins.push({
        x: CANVAS_W + 20,
        y,
        width: 16,
        height: 16,
        animFrame: 0,
        collected: false,
        collectTimer: 0,
    });
}

function updateObstacles() {
    spawnTimer--;
    if (spawnTimer <= 0) {
        spawnObstacle();
        const interval = Math.max(minSpawnInterval, 120 - score / 20);
        spawnTimer = interval + Math.random() * 60;
    }

    coinSpawnTimer--;
    if (coinSpawnTimer <= 0) {
        spawnCoin();
        coinSpawnTimer = 80 + Math.random() * 120;
    }

    // Update obstacles
    for (let i = obstacles.length - 1; i >= 0; i--) {
        const obs = obstacles[i];
        obs.x -= gameSpeed;

        if (obs.type === 'goomba' || obs.type === 'flying_goomba') {
            obs.animFrame = Math.floor(frameCount / 8) % 2;
        }

        if (obs.type === 'flying_goomba') {
            obs.flyTimer += 0.05;
            obs.y = obs.baseY + Math.sin(obs.flyTimer) * 20;
        }

        // Score when passed
        if (!obs.passed && obs.x + obs.width < player.x) {
            obs.passed = true;
            score += 100;
        }

        // Remove off-screen
        if (obs.x + obs.width < -50) {
            obstacles.splice(i, 1);
        }
    }

    // Update coins
    for (let i = coins.length - 1; i >= 0; i--) {
        const coin = coins[i];
        coin.x -= gameSpeed;
        coin.animFrame = Math.floor(frameCount / 6) % 4;

        if (coin.collected) {
            coin.collectTimer++;
            coin.y -= 2;
            if (coin.collectTimer > 20) {
                coins.splice(i, 1);
                continue;
            }
        }

        // Remove off-screen
        if (coin.x < -20) {
            coins.splice(i, 1);
        }
    }
}

function drawObstacles() {
    for (const obs of obstacles) {
        const x = Math.round(obs.x);
        const y = Math.round(obs.y);

        switch (obs.type) {
            case 'goomba':
                drawGoomba(x, y, obs.animFrame);
                break;
            case 'flying_goomba':
                drawFlyingGoomba(x, y, obs.animFrame);
                break;
            case 'pipe_small':
            case 'pipe_tall':
                drawPipe(x, y, obs.width, obs.height);
                break;
            case 'brick_stack':
                drawBricks(x, y, obs.width, obs.height);
                break;
        }
    }

    for (const coin of coins) {
        drawCoin(coin);
    }
}

function drawGoomba(x, y, frame) {
    const c = COLORS.goomba;
    // Body
    ctx.fillStyle = c.body;
    ctx.fillRect(x + 2, y, 20, 16);
    ctx.fillRect(x, y + 4, 24, 12);
    // Darker bottom
    ctx.fillStyle = c.bodyDark;
    ctx.fillRect(x + 2, y + 12, 20, 6);
    // Eyes
    ctx.fillStyle = c.white;
    ctx.fillRect(x + 4, y + 4, 6, 6);
    ctx.fillRect(x + 14, y + 4, 6, 6);
    ctx.fillStyle = c.black;
    ctx.fillRect(x + 7, y + 6, 3, 4);
    ctx.fillRect(x + 15, y + 6, 3, 4);
    // Feet
    ctx.fillStyle = c.feet;
    if (frame === 0) {
        ctx.fillRect(x, y + 18, 10, 6);
        ctx.fillRect(x + 14, y + 18, 10, 6);
    } else {
        ctx.fillRect(x + 2, y + 18, 10, 6);
        ctx.fillRect(x + 12, y + 18, 10, 6);
    }
}

function drawFlyingGoomba(x, y, frame) {
    drawGoomba(x + 2, y + 4, frame);
    // Wings
    ctx.fillStyle = '#FFFFFF';
    const wingUp = frame === 0;
    if (wingUp) {
        ctx.fillRect(x - 6, y - 4, 10, 6);
        ctx.fillRect(x + 24, y - 4, 10, 6);
        ctx.fillRect(x - 4, y + 2, 8, 4);
        ctx.fillRect(x + 24, y + 2, 8, 4);
    } else {
        ctx.fillRect(x - 4, y + 2, 10, 6);
        ctx.fillRect(x + 22, y + 2, 10, 6);
        ctx.fillRect(x - 2, y + 8, 8, 4);
        ctx.fillRect(x + 22, y + 8, 8, 4);
    }
}

function drawPipe(x, y, w, h) {
    // Pipe body
    ctx.fillStyle = COLORS.pipe;
    ctx.fillRect(x + 4, y + 16, w - 8, h - 16);
    // Pipe top
    ctx.fillRect(x, y, w, 16);
    // Highlight
    ctx.fillStyle = COLORS.pipeLight;
    ctx.fillRect(x + 4, y + 2, 4, 12);
    ctx.fillRect(x + 8, y + 16, 4, h - 16);
    // Shadow
    ctx.fillStyle = COLORS.pipeDark;
    ctx.fillRect(x + w - 6, y + 2, 4, 12);
    ctx.fillRect(x + w - 10, y + 16, 4, h - 16);
    // Black rim
    ctx.fillStyle = '#000';
    ctx.fillRect(x, y, w, 2);
    ctx.fillRect(x, y + 14, w, 2);
}

function drawBricks(x, y, w, h) {
    ctx.fillStyle = COLORS.brick;
    ctx.fillRect(x, y, w, h);

    ctx.fillStyle = COLORS.brickDark;
    // Horizontal lines
    for (let row = 0; row < h; row += 16) {
        ctx.fillRect(x, y + row, w, 2);
    }
    // Vertical lines (offset every other row)
    for (let row = 0; row < h; row += 16) {
        const offset = (row / 16 % 2) * 8;
        for (let col = offset; col < w; col += 16) {
            ctx.fillRect(x + col, y + row, 2, 16);
        }
    }
    // Highlight
    ctx.fillStyle = '#D06020';
    for (let row = 0; row < h; row += 16) {
        ctx.fillRect(x + 2, y + row + 2, w - 4, 2);
    }
}

function drawCoin(coin) {
    const x = Math.round(coin.x);
    const y = Math.round(coin.y);

    if (coin.collected) {
        ctx.globalAlpha = 1 - coin.collectTimer / 20;
    }

    // Coin spin animation
    const widths = [14, 10, 4, 10];
    const w = widths[coin.animFrame];
    const offset = (14 - w) / 2;

    ctx.fillStyle = COLORS.coin;
    ctx.fillRect(x + offset + 1, y, w, 16);
    ctx.fillStyle = COLORS.coinDark;
    ctx.fillRect(x + offset + 1, y + 12, w, 4);

    // '?' or shine
    if (w > 6) {
        ctx.fillStyle = '#FFF8E0';
        ctx.fillRect(x + offset + 3, y + 2, Math.max(w - 6, 2), 2);
    }

    ctx.globalAlpha = 1;
}

// ------------------------------------------------------------
// Collision detection
// ------------------------------------------------------------
function checkCollisions() {
    if (player.isDead || player.invincible > 0) return;

    const ph = player.getHitbox();

    for (const obs of obstacles) {
        const oh = {
            x: obs.x + 3,
            y: obs.y + 3,
            width: obs.width - 6,
            height: obs.height - 6,
        };

        if (rectsOverlap(ph, oh)) {
            killPlayer();
            return;
        }
    }

    // Coin collection
    for (const coin of coins) {
        if (coin.collected) continue;
        if (rectsOverlap(ph, { x: coin.x, y: coin.y, width: 16, height: 16 })) {
            coin.collected = true;
            score += 200;
            particles.emit(coin.x + 8, coin.y + 8, 8, COLORS.coin, 'coin');
        }
    }
}

function rectsOverlap(a, b) {
    return a.x < b.x + b.width &&
           a.x + a.width > b.x &&
           a.y < b.y + b.height &&
           a.y + a.height > b.y;
}

function killPlayer() {
    player.isDead = true;
    player.vy = -8;
    shakeTimer = 15;
    shakeIntensity = 5;
    gameState = 'gameover';

    if (score > highScore) {
        highScore = score;
        localStorage.setItem('marioRunnerHighScore', highScore.toString());
    }

    particles.emit(player.x + player.width / 2, player.y + player.height / 2, 15, COLORS.mario.red, 'death');
}

// ------------------------------------------------------------
// UI / HUD
// ------------------------------------------------------------
function drawHUD() {
    // Score
    drawPixelText('SCORE', 20, 16, 12);
    drawPixelText(score.toString().padStart(6, '0'), 20, 32, 16);

    // High Score
    drawPixelText('HI-SCORE', CANVAS_W - 160, 16, 12);
    drawPixelText(highScore.toString().padStart(6, '0'), CANVAS_W - 160, 32, 16);

    // Speed indicator
    const speedPercent = Math.round(((gameSpeed - BASE_SPEED) / (MAX_SPEED - BASE_SPEED)) * 100);
    drawPixelText('SPD ' + speedPercent + '%', CANVAS_W / 2 - 40, 16, 10);
}

function drawPixelText(text, x, y, size) {
    ctx.font = `bold ${size}px "Courier New", monospace`;
    // Shadow
    ctx.fillStyle = COLORS.textShadow;
    ctx.fillText(text, x + 1, y + 1);
    // Main text
    ctx.fillStyle = COLORS.text;
    ctx.fillText(text, x, y);
}

function drawMenu() {
    drawBackground();
    drawGround();

    // Title
    ctx.fillStyle = 'rgba(0,0,0,0.4)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

    // Title block
    const titleY = 80;
    ctx.fillStyle = COLORS.brick;
    ctx.fillRect(CANVAS_W / 2 - 180, titleY - 10, 360, 60);
    drawBricks(CANVAS_W / 2 - 180, titleY - 10, 360, 60);

    ctx.font = 'bold 36px "Courier New", monospace';
    ctx.fillStyle = '#000';
    ctx.fillText('SUPER MARIO', CANVAS_W / 2 - 128, titleY + 23);
    ctx.fillStyle = '#FFD700';
    ctx.fillText('SUPER MARIO', CANVAS_W / 2 - 130, titleY + 21);

    ctx.font = 'bold 28px "Courier New", monospace';
    ctx.fillStyle = '#000';
    ctx.fillText('RUNNER', CANVAS_W / 2 - 50, titleY + 52);
    ctx.fillStyle = '#FF4444';
    ctx.fillText('RUNNER', CANVAS_W / 2 - 52, titleY + 50);

    // Instructions
    const instrY = 200;
    ctx.font = 'bold 16px "Courier New", monospace';
    const blink = Math.floor(frameCount / 30) % 2 === 0;
    if (blink) {
        ctx.fillStyle = '#000';
        ctx.fillText('PRESS SPACE / TAP TO START', CANVAS_W / 2 - 160, instrY + 1);
        ctx.fillStyle = '#FFF';
        ctx.fillText('PRESS SPACE / TAP TO START', CANVAS_W / 2 - 162, instrY);
    }

    ctx.font = '14px "Courier New", monospace';
    ctx.fillStyle = '#DDD';
    ctx.fillText('SPACE / UP  = Jump (x2)', CANVAS_W / 2 - 110, instrY + 40);
    ctx.fillText('DOWN / S    = Duck', CANVAS_W / 2 - 110, instrY + 60);
    ctx.fillText('Collect coins, avoid enemies!', CANVAS_W / 2 - 130, instrY + 90);

    if (highScore > 0) {
        ctx.font = 'bold 14px "Courier New", monospace';
        ctx.fillStyle = '#FFD700';
        ctx.fillText('HIGH SCORE: ' + highScore, CANVAS_W / 2 - 70, instrY + 120);
    }

    // Draw Mario idle on menu
    const menuMarioX = CANVAS_W / 2 - 14;
    const menuMarioY = GROUND_Y - 32;
    drawMarioBody(menuMarioX, menuMarioY, COLORS.mario, Math.floor(frameCount / 10) % 4, true, false);
}

function drawGameOver() {
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

    // Game Over box
    ctx.fillStyle = '#1a1a2e';
    ctx.fillRect(CANVAS_W / 2 - 160, 100, 320, 180);
    ctx.strokeStyle = '#e94560';
    ctx.lineWidth = 3;
    ctx.strokeRect(CANVAS_W / 2 - 160, 100, 320, 180);

    ctx.font = 'bold 32px "Courier New", monospace';
    ctx.fillStyle = '#e94560';
    ctx.fillText('GAME OVER', CANVAS_W / 2 - 100, 150);

    ctx.font = 'bold 18px "Courier New", monospace';
    ctx.fillStyle = '#FFF';
    ctx.fillText('SCORE: ' + score, CANVAS_W / 2 - 70, 190);

    if (score >= highScore && score > 0) {
        ctx.fillStyle = '#FFD700';
        ctx.fillText('NEW HIGH SCORE!', CANVAS_W / 2 - 100, 220);
    } else {
        ctx.fillStyle = '#AAA';
        ctx.fillText('BEST: ' + highScore, CANVAS_W / 2 - 55, 220);
    }

    const blink = Math.floor(frameCount / 25) % 2 === 0;
    if (blink) {
        ctx.font = '14px "Courier New", monospace';
        ctx.fillStyle = '#FFF';
        ctx.fillText('Press SPACE / Tap to retry', CANVAS_W / 2 - 110, 260);
    }
}

// ------------------------------------------------------------
// Game lifecycle
// ------------------------------------------------------------
function startGame() {
    gameState = 'playing';
    score = 0;
    gameSpeed = BASE_SPEED;
    frameCount = 0;
    obstacles = [];
    coins = [];
    spawnTimer = 60;
    coinSpawnTimer = 30;
    player.reset();
    particles.clear();
    initBackground();
}

function update() {
    frameCount++;

    if (gameState === 'playing') {
        // Increase speed over time
        gameSpeed = Math.min(MAX_SPEED, gameSpeed + SPEED_INCREMENT);

        // Distance score
        if (frameCount % 4 === 0) {
            score += 1;
        }

        player.update();
        updateObstacles();
        updateBackground();
        checkCollisions();
        particles.update();

        if (shakeTimer > 0) shakeTimer--;
    } else if (gameState === 'gameover') {
        player.update();
        particles.update();
        if (shakeTimer > 0) shakeTimer--;
    } else {
        // Menu
        updateBackground();
    }
}

function draw() {
    ctx.save();

    // Screen shake
    if (shakeTimer > 0) {
        const sx = (Math.random() - 0.5) * shakeIntensity;
        const sy = (Math.random() - 0.5) * shakeIntensity;
        ctx.translate(sx, sy);
        shakeIntensity *= 0.9;
    }

    if (gameState === 'menu') {
        drawMenu();
    } else {
        drawBackground();
        drawGround();
        drawObstacles();
        player.draw();
        particles.draw();
        drawHUD();

        if (gameState === 'gameover') {
            drawGameOver();
        }
    }

    ctx.restore();
}

// ------------------------------------------------------------
// Main loop
// ------------------------------------------------------------
initBackground();

function gameLoop() {
    update();
    draw();
    requestAnimationFrame(gameLoop);
}

gameLoop();
