import React, { useState, useEffect } from 'react';
import { Settings, Info, Trophy, Play, User, X } from 'lucide-react';

export default function App() {
  const [showHowToPlay, setShowHowToPlay] = useState(false);
  const [gameState, setGameState] = useState('title');

  const handleStart = () => {
    setGameState('playing');
  };

  if (gameState === 'playing') {
    return <GameCanvas onExit={() => setGameState('title')} />;
  }

  return (
    <div className="flex items-center justify-center h-full bg-gray-900 text-slate-100 font-sans overflow-hidden">
      <div className="relative w-full max-w-md h-full sm:h-[850px] sm:max-h-[90vh] sm:rounded-3xl shadow-2xl overflow-hidden bg-green-950 sm:border-4 border-slate-800">
        
        {/* 배경 영역 */}
        <div className="absolute inset-0 z-0">
          <div className="absolute inset-0 bg-gradient-to-b from-green-800 via-emerald-900 to-green-950"></div>
          <div className="absolute top-[-10%] left-[-20%] w-[150%] h-[150%] bg-[radial-gradient(circle_at_50%_50%,rgba(255,255,255,0.1)_0%,transparent_50%)] animate-pulse" style={{ animationDuration: '4s' }}></div>
          <div className="absolute top-0 left-0 w-full h-full backdrop-blur-sm"></div>
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_0%,rgba(0,0,0,0.7)_100%)] z-10"></div>
        </div>

        <Particles />

        {/* 메인 콘텐츠 영역 */}
        <div className="relative z-20 w-full h-full flex flex-col items-center justify-between py-12 px-6">
          
          <div className="flex flex-col items-center mt-12 w-full">
            <div className="relative flex justify-center items-center w-full">
              {/* 장식용 나이프 (좌우) */}
              <div className="absolute left-4 top-4 animate-bounce" style={{ animationDuration: '3s' }}>
                <KnifeIcon color="#c0c0c0" rotation={-30} />
              </div>
              <div className="absolute right-4 top-0 animate-bounce" style={{ animationDuration: '2.5s', animationDelay: '0.5s' }}>
                <KnifeIcon color="#a0a0b0" rotation={30} />
              </div>

              <div className="text-center transform transition-transform hover:scale-105 duration-300">
                <h2 className="text-xl md:text-2xl font-black text-orange-400 drop-shadow-[0_2px_2px_rgba(0,0,0,0.8)] tracking-widest mb-1">
                  콩퍼스의
                </h2>
                <h1 className="text-5xl md:text-6xl font-black text-white drop-shadow-[0_4px_0_#b45309,0_6px_4px_rgba(0,0,0,0.5)] tracking-tighter">
                  <span className="text-yellow-400">유성</span>막기
                </h1>
              </div>
            </div>

            <div className="mt-8 bg-black/40 backdrop-blur-md px-4 py-2 rounded-full border border-white/10">
              <p className="text-sm md:text-base text-emerald-100 font-medium">
                🌠 쏟아지는 유성을 막아내며 최고 점수에 도전하세요!
              </p>
            </div>
          </div>

          <div className="w-full flex flex-col items-center gap-4 mt-auto mb-16">
            <button 
              onClick={handleStart}
              className="relative group w-full max-w-[280px] h-20 rounded-2xl bg-gradient-to-b from-green-400 to-green-600 border-b-8 border-green-800 active:border-b-0 active:translate-y-2 transition-all flex items-center justify-center shadow-[0_10px_20px_rgba(0,0,0,0.5)] overflow-hidden"
            >
              <div className="absolute inset-0 bg-white/20 group-hover:bg-white/30 animate-pulse" style={{ animationDuration: '2s' }}></div>
              <div className="flex items-center gap-2 z-10 text-white font-black text-2xl drop-shadow-[0_2px_2px_rgba(0,0,0,0.5)]">
                <Play fill="currentColor" size={28} />
                게임 시작
              </div>
            </button>

            <button 
              onClick={() => setShowHowToPlay(true)}
              className="mt-2 text-slate-300 hover:text-white font-medium text-sm flex items-center gap-1.5 px-4 py-2 bg-black/20 rounded-full transition-colors"
            >
              <Info size={16} />
              어떻게 플레이하나요?
            </button>
          </div>

          <div className="w-full flex justify-between items-end text-xs font-medium text-slate-400">
            <div className="flex flex-col gap-2">
              <div className="bg-blue-600 text-white text-[10px] px-1.5 py-0.5 rounded font-bold w-fit">
                DEV v0.1
              </div>
              <button className="flex items-center gap-1.5 hover:text-white transition-colors bg-black/30 px-3 py-1.5 rounded-lg">
                <User size={14} />
                <span>unknown373</span>
              </button>
            </div>

            <div className="flex flex-col items-end gap-2">
              <button className="p-2 bg-black/30 hover:bg-black/50 rounded-full transition-colors mb-1">
                <Settings size={18} />
              </button>
              <div className="flex items-center gap-1.5 bg-black/40 px-3 py-1.5 rounded-lg border border-yellow-500/30">
                <Trophy size={14} className="text-yellow-500" />
                <span className="text-yellow-100">최고 점수: <span className="font-bold text-yellow-400">0</span></span>
              </div>
            </div>
          </div>
        </div>

        {showHowToPlay && (
          <div className="absolute inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-6 animate-in fade-in duration-200">
            <div className="bg-slate-800 rounded-2xl w-full max-w-sm border-2 border-slate-600 shadow-2xl flex flex-col">
              <div className="flex justify-between items-center p-4 border-b border-slate-700">
                <h3 className="text-lg font-bold text-white flex items-center gap-2">
                  <Info className="text-green-400" /> 플레이 방법
                </h3>
                <button onClick={() => setShowHowToPlay(false)} className="text-slate-400 hover:text-white">
                  <X size={24} />
                </button>
              </div>
              <div className="p-6 text-slate-300 space-y-4 text-sm">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-indigo-900 rounded-lg flex items-center justify-center text-xl">🔪</div>
                  <p>화면을 좌우로 터치하여 <strong>메이드</strong>를 움직이세요.</p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-yellow-900 rounded-lg flex items-center justify-center text-xl">⭐</div>
                  <p>스테이지의 <strong>별 블록</strong>을 모두 없애면 클리어!</p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-red-900 rounded-lg flex items-center justify-center text-xl">☄️</div>
                  <p>빨간 <strong>악당 유성</strong>이 바닥에 닿으면 하트가 깎입니다.</p>
                </div>
              </div>
              <div className="p-4">
                <button 
                  onClick={() => setShowHowToPlay(false)}
                  className="w-full py-3 bg-slate-700 hover:bg-slate-600 rounded-xl font-bold text-white transition-colors"
                >
                  확인
                </button>
              </div>
            </div>
          </div>
        )}
        
      </div>

      <style dangerouslySetInnerHTML={{__html: `
        @keyframes bounce-slow {
          0%, 100% { transform: translateY(-5%); }
          50% { transform: translateY(5%); }
        }
        .animate-bounce {
          animation: bounce-slow infinite ease-in-out;
        }
      `}} />
    </div>
  );
}

function Particles() {
  const [items] = useState(() =>
    Array.from({ length: 15 }, (_, i) => ({
      key: i,
      left: `${Math.random() * 100}%`,
      top: `${Math.random() * 100}%`,
      size: Math.random() * 4 + 2,
      delay: `${Math.random() * 5}s`,
      duration: `${Math.random() * 3 + 2}s`,
      opacity: Math.random() * 0.5 + 0.1,
    }))
  );
  return (
    <div className="absolute inset-0 pointer-events-none z-10 overflow-hidden">
      {items.map((p) => (
        <div
          key={p.key}
          className="absolute bg-yellow-200 rounded-full animate-pulse blur-[1px]"
          style={{
            left: p.left,
            top: p.top,
            width: `${p.size}px`,
            height: `${p.size}px`,
            animationDelay: p.delay,
            animationDuration: p.duration,
            opacity: p.opacity,
          }}
        />
      ))}
    </div>
  );
}

// 나이프 아이콘 (타이틀 장식용)
function KnifeIcon({ color, rotation = 0 }) {
  return (
    <svg width="40" height="40" viewBox="0 0 100 100" className="drop-shadow-lg" style={{ transform: `rotate(${rotation}deg)` }}>
      <polygon points="50,5 60,50 50,55 40,50" fill={color} />
      <polygon points="50,5 60,50 50,45" fill="white" opacity="0.3" />
      <rect x="35" y="52" width="30" height="6" rx="2" fill="#4B5563" />
      <rect x="44" y="58" width="12" height="30" rx="3" fill="#92400E" />
      <rect x="46" y="60" width="8" height="26" rx="2" fill="#B45309" opacity="0.5" />
    </svg>
  );
}

// --- [변경] 게임 상수: 캔버스·블록·물리 한곳에 정리 ---
const CANVAS_W = 400;
const CANVAS_H = 700;
const BOTTOM_Y = 620;
const UI_TOP_H = 50;
const BALL_SPEED = 12;
const BLOCK_COLS = 7;
const BLOCK_W = CANVAS_W / BLOCK_COLS;
const BLOCK_H = BLOCK_W;
const PADDLE_SPEED = 7;
const PADDLE_WIDTH = 80;
const MAID_CHAR_W = 60;
const MAID_CHAR_H = 72;
const MAID_ANIM_FPS = 10;
const MAID_FRAME_INTERVAL = Math.round(60 / MAID_ANIM_FPS);
const STAGE_CLEAR_HOLD_FRAMES = 55;
const PADDLE_LERP = 0.42;
const MAX_PARTICLES = 220;
const ATLAS_SRC = '/assets/sprite-atlas.jpg';

// [변경] 아틀라스 프레임 좌표 (phaser/public/assets/atlas.json 과 동일)
const ATLAS_FRAMES = {
  maid_big_1: { x: 16, y: 52, w: 120, h: 160 },
  maid_big_2: { x: 140, y: 52, w: 120, h: 160 },
  maid_big_3: { x: 264, y: 52, w: 120, h: 160 },
  maid_big_4: { x: 388, y: 52, w: 120, h: 160 },
  maid_small_1: { x: 32, y: 228, w: 96, h: 120 },
  maid_small_2: { x: 148, y: 228, w: 96, h: 120 },
  maid_small_3: { x: 268, y: 228, w: 96, h: 120 },
  maid_small_4: { x: 388, y: 228, w: 96, h: 120 },
  knife_big: { x: 580, y: 100, w: 48, h: 96 },
  knife_small: { x: 720, y: 100, w: 32, h: 64 },
  block_normal: { x: 260, y: 395, w: 96, h: 96 },
  block_pow_dark: { x: 460, y: 375, w: 96, h: 96 },
  block_pow_lit: { x: 568, y: 375, w: 96, h: 96 },
  block_star_dim: { x: 260, y: 500, w: 96, h: 96 },
  block_star_bright: { x: 368, y: 500, w: 96, h: 96 },
  block_star_glow: { x: 476, y: 500, w: 96, h: 96 },
  block_red_enemy: { x: 688, y: 375, w: 96, h: 96 },
  block_red_enemy_alt: { x: 688, y: 500, w: 96, h: 96 },
  paddle_tray: { x: 30, y: 670, w: 220, h: 48 },
  brick_tile: { x: 330, y: 660, w: 200, h: 64 },
  particle_red: { x: 598, y: 680, w: 16, h: 16 },
  particle_green: { x: 620, y: 680, w: 16, h: 16 },
  particle_orange: { x: 642, y: 664, w: 16, h: 16 },
  icon_knife: { x: 710, y: 660, w: 40, h: 80 },
  icon_star: { x: 780, y: 670, w: 48, h: 48 },
};

/**
 * [변경] 스프라이트 시트: 아틀라스에서 잘라 그리기
 */
class SpriteSheet {
  constructor(image) {
    this.image = image;
  }

  getFrame(name) {
    return ATLAS_FRAMES[name] || null;
  }

  /** 소스 프레임을 (dx,dy)에 (dw,dh) 크기로 그림 */
  drawFrame(ctx, name, dx, dy, dw, dh) {
    const f = this.getFrame(name);
    if (!f || !this.image?.complete) return false;
    ctx.drawImage(this.image, f.x, f.y, f.w, f.h, dx, dy, dw, dh);
    return true;
  }

  /** 회전(라디안): 블레이드 중심 기준 */
  drawFrameRotated(ctx, name, cx, cy, dw, dh, rotation) {
    const f = this.getFrame(name);
    if (!f || !this.image?.complete) return false;
    ctx.save();
    ctx.translate(cx, cy);
    ctx.rotate(rotation);
    ctx.drawImage(this.image, f.x, f.y, f.w, f.h, -dw / 2, -dh / 2, dw, dh);
    ctx.restore();
    return true;
  }
}

function GameCanvas({ onExit }) {
  const canvasRef = React.useRef(null);
  
  const engineRef = React.useRef({
    state: 'AIMING',
    level: 1,
    ballCount: 3,      
    ballsToShoot: 0,   
    balls: [],
    blocks: [],
    particles: [],
    startPos: { x: 200, y: 620 }, 
    firePos: { x: 200, y: 620 },  
    aimAngle: -Math.PI / 2,
    dragging: false,       
    paddleDragging: false, 
    frameCount: 0,
    bgBricks: [],
    pendingStars: 0,
    hearts: 3,
    keys: { left: false, right: false }, 
    tutorialTimer: 0,
    atlas: null,
    atlasReady: false,
    spriteSheet: null,
    screenShake: 0,
    stageClearTimer: 0,
    pointerCanvasX: CANVAS_W / 2,
    maidFrame: 0,
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d', { alpha: false });
    const eng = engineRef.current;
    let animationId;
    let running = true;

    const generateRow = (yPos = 60, isInit = false) => {
      for (let i = 0; i < BLOCK_COLS; i++) {
        if (Math.random() > 0.4) {
          let type = 'NORMAL';
          let hp = eng.level;
          const rand = Math.random();
          
          if (rand < 0.1) type = 'POW';
          else if (isInit && rand < 0.25) type = 'STAR'; 
          else if (rand < 0.35) type = 'RED_ENEMY'; 

          eng.blocks.push({
            x: i * BLOCK_W + 2,
            y: yPos + 2,
            w: BLOCK_W - 4,
            h: BLOCK_H - 4,
            hp: (type === 'NORMAL' || type === 'RED_ENEMY') ? hp : 1, 
            maxHp: hp,
            type: type
          });
        }
      }
    };

    eng.initLevel = (level) => {
      eng.blocks = [];
      eng.balls = [];
      eng.ballsToShoot = 0;
      eng.pendingStars = 0;
      eng.tutorialTimer = 0;
      eng.stageClearTimer = 0;
      eng.screenShake = 0;
      eng.startPos.x = CANVAS_W / 2;
      
      const rows = 3 + Math.floor(level / 2);
      for(let r = 0; r < rows; r++) {
        generateRow(60 + r * BLOCK_H, true); 
      }
      
      if (eng.blocks.filter(b => b.type === 'STAR').length === 0) {
         eng.blocks.push({
            x: 3 * BLOCK_W + 2, y: 60 + 2, w: BLOCK_W - 4, h: BLOCK_H - 4,
            hp: 1, maxHp: 1, type: 'STAR'
         });
      }
      
      eng.state = 'AIMING';
    };

    const initGame = () => {
      eng.bgBricks = Array.from({ length: 24 }).map(() => ({
        x: Math.random() * (CANVAS_W - 40), y: Math.random() * (CANVAS_H - 80),
        w: 28 + Math.random() * 36, h: 18 + Math.random() * 22
      }));

      const atlas = new Image();
      atlas.src = ATLAS_SRC;
      atlas.onload = () => {
        eng.atlas = atlas;
        eng.atlasReady = true;
        eng.spriteSheet = new SpriteSheet(atlas);
      };
      eng.atlas = atlas;

      eng.initLevel(eng.level);
    };

    /** 파티클 색 → 아틀라스 프레임 이름 */
    const particleFrameForColor = (color) => {
      if (color === '#EF4444' || color === '#f00') return 'particle_red';
      if (color === '#4ADE80') return 'particle_green';
      return 'particle_orange';
    };

    const addParticles = (x, y, color, count = 10) => {
      const frame = particleFrameForColor(color);
      const cap = MAX_PARTICLES;
      let start = eng.particles.length;
      if (start + count > cap) {
        eng.particles.splice(0, start + count - cap);
        start = eng.particles.length;
      }
      for (let i = 0; i < count; i++) {
        eng.particles.push({
          x, y,
          vx: (Math.random() - 0.5) * 10,
          vy: (Math.random() - 0.5) * 10,
          life: 1.0,
          frame,
        });
      }
    };

    const bumpShake = (amount) => {
      eng.screenShake = Math.min(eng.screenShake + amount, 28);
    };

    const resolveCollision = (ball, block) => {
      let testX = ball.x;
      let testY = ball.y;

      if (ball.x < block.x) testX = block.x;
      else if (ball.x > block.x + block.w) testX = block.x + block.w;

      if (ball.y < block.y) testY = block.y;
      else if (ball.y > block.y + block.h) testY = block.y + block.h;

      let distX = ball.x - testX;
      let distY = ball.y - testY;
      let distance = Math.sqrt((distX * distX) + (distY * distY));

      if (distance <= ball.radius) {
        let overlap = ball.radius - distance;
        if (distance === 0) {
          distX = ball.vx > 0 ? -1 : 1;
          distY = ball.vy > 0 ? -1 : 1;
          distance = 1.414;
        }
        let nx = distX / distance;
        let ny = distY / distance;

        ball.x += nx * overlap;
        ball.y += ny * overlap;

        if (Math.abs(nx) > Math.abs(ny)) ball.vx = -ball.vx;
        else ball.vy = -ball.vy;

        return true;
      }
      return false;
    };

    /** [변경] 메이드 idle / throw 애니메이션 프레임 갱신 (약 10fps) */
    const updateMaidAnimation = () => {
      if (eng.frameCount % MAID_FRAME_INTERVAL === 0) {
        eng.maidFrame = (eng.maidFrame + 1) % 4;
      }
    };

    /** [변경] 스테이지 클리어: 타이머만큼 대기 후 다음 레벨 */
    const updateStageClear = () => {
      if (eng.state !== 'STAGE_CLEAR') return;
      eng.stageClearTimer++;
      if (eng.stageClearTimer >= STAGE_CLEAR_HOLD_FRAMES) {
        eng.level++;
        eng.initLevel(eng.level);
      }
    };

    /** 패들 위치: 키보드 + (슈팅 중) 포인터 타깃 보간 */
    const updatePaddle = () => {
      if (eng.state === 'STAGE_CLEAR') return;

      if (eng.keys.left) eng.startPos.x -= PADDLE_SPEED;
      if (eng.keys.right) eng.startPos.x += PADDLE_SPEED;

      if (eng.state === 'SHOOTING' && eng.paddleDragging) {
        eng.startPos.x += (eng.pointerCanvasX - eng.startPos.x) * PADDLE_LERP;
      }

      eng.startPos.x = Math.max(20, Math.min(CANVAS_W - 20, eng.startPos.x));
      eng.pointerCanvasX = Math.max(20, Math.min(CANVAS_W - 20, eng.pointerCanvasX));
    };

    /** 빨간 적 블록 하강 */
    const updateRedEnemyBlocks = () => {
      if (eng.state !== 'SHOOTING') return;
      eng.blocks.forEach(b => {
        if (b.type === 'RED_ENEMY') {
          b.y += 0.5; 
          if (b.y + b.h > BOTTOM_Y - 20 && b.hp > 0) {
            b.hp = 0; 
            eng.hearts--;
            addParticles(b.x + b.w / 2, b.y + b.h, '#EF4444', 14);
            bumpShake(14);
            if (eng.hearts <= 0) eng.state = 'GAME_OVER';
          }
        }
      });
    };

    const spawnBallsFromQueue = () => {
      if (eng.state !== 'SHOOTING') return;
      if (eng.ballsToShoot > 0 && eng.frameCount % 4 === 0) {
        eng.balls.push({
          x: eng.firePos.x,
          y: eng.firePos.y - 76,
          vx: Math.cos(eng.aimAngle) * BALL_SPEED,
          vy: Math.sin(eng.aimAngle) * BALL_SPEED,
          radius: 5,
          active: true,
          isSmall: false,
          drawAngle: eng.aimAngle + Math.PI / 2,
        });
        eng.ballsToShoot--;
      }
    };

    /** [변경] 나이프 회전: 목표 각도로 부드럽게 보간 */
    const smoothKnifeRotation = (b) => {
      const target = Math.atan2(b.vy, b.vx) + Math.PI / 2;
      if (b.drawAngle === undefined) b.drawAngle = target;
      let diff = target - b.drawAngle;
      while (diff > Math.PI) diff -= Math.PI * 2;
      while (diff < -Math.PI) diff += Math.PI * 2;
      b.drawAngle += diff * 0.28;
    };

    const stepBall = (b) => {
      if (!b.active) return;
      b.x += b.vx / 2;
      b.y += b.vy / 2;

      if (b.x < b.radius) { b.x = b.radius; b.vx = Math.abs(b.vx); }
      if (b.x > CANVAS_W - b.radius) { b.x = CANVAS_W - b.radius; b.vx = -Math.abs(b.vx); }
      if (b.y < UI_TOP_H + b.radius) { b.y = UI_TOP_H + b.radius; b.vy = Math.abs(b.vy); }

      if (Math.abs(b.vy) < 0.3) b.vy = b.vy >= 0 ? 0.3 : -0.3;

      if (b.vy > 0) { 
        const px = eng.startPos.x;
        const py = eng.startPos.y;
        if (b.y + b.radius >= py - 76 && b.y - b.radius <= py - 64) {
          if (b.x >= px - PADDLE_WIDTH / 2 && b.x <= px + PADDLE_WIDTH / 2) {
            const hitPoint = b.x - px;
            const normalizedHit = hitPoint / (PADDLE_WIDTH / 2); 
            const maxBounceAngle = Math.PI / 2.5; 
            const bounceAngle = normalizedHit * maxBounceAngle;
            const currentSpeed = Math.sqrt(b.vx*b.vx + b.vy*b.vy);
            b.vx = Math.sin(bounceAngle) * currentSpeed;
            b.vy = -Math.cos(bounceAngle) * currentSpeed;
            b.y = py - 76 - b.radius;
            addParticles(b.x, b.y, '#4ADE80', 8);
          }
        }
      }

      if (b.y >= BOTTOM_Y) {
        b.y = BOTTOM_Y;
        b.active = false;
      }

      smoothKnifeRotation(b);
    };

    const handleBallBlockHits = (b) => {
      for (let j = 0; j < eng.blocks.length; j++) {
        let block = eng.blocks[j];
        if (block.hp > 0 && resolveCollision(b, block)) {
          block.hp--;
          const hitColor = block.type === 'NORMAL' ? '#000' : '#FBBF24';
          addParticles(b.x, b.y, hitColor, 12);
          bumpShake(5);
          
          if (block.hp <= 0) {
            addParticles(block.x + block.w/2, block.y + block.h/2, '#FBBF24', 16);
            bumpShake(8);
            if (block.type === 'STAR') {
              eng.pendingStars++;
            } else if (block.type === 'POW') {
              for (let k = 0; k < 8; k++) {
                let angle = (k / 8) * Math.PI * 2;
                eng.balls.push({
                  x: block.x + block.w / 2,
                  y: block.y + block.h / 2,
                  vx: Math.cos(angle) * BALL_SPEED * 0.6,
                  vy: Math.sin(angle) * BALL_SPEED * 0.6,
                  radius: 5,
                  active: true,
                  isSmall: true,
                  drawAngle: angle + Math.PI / 2,
                });
              }
            }
          }
        }
      }
    };

    const updateBalls = () => {
      if (eng.state !== 'SHOOTING') return;

      spawnBallsFromQueue();

      let allInactive = true;
      for (let step = 0; step < 2; step++) {
        for (let i = 0; i < eng.balls.length; i++) {
          let b = eng.balls[i];
          if (!b.active) continue;
          allInactive = false;
          stepBall(b);
          handleBallBlockHits(b);
        }
      }

      eng.blocks = eng.blocks.filter(b => b.hp > 0);

      const starsLeft = eng.blocks.filter(b => b.type === 'STAR').length;

      if (starsLeft === 0) {
        eng.balls = []; 
        eng.ballCount += eng.pendingStars;
        eng.pendingStars = 0;
        eng.stageClearTimer = 0;
        eng.state = 'STAGE_CLEAR';
      }
      else if (allInactive && eng.ballsToShoot === 0) {
        eng.balls = []; 
        eng.pendingStars = 0; 
        eng.state = 'GAME_OVER';
      }
    };

    const updateParticles = () => {
      const next = [];
      for (let i = 0; i < eng.particles.length; i++) {
        const p = eng.particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.life -= 0.045;
        if (p.life > 0) next.push(p);
      }
      eng.particles = next;
    };

    const decayShake = () => {
      eng.screenShake *= 0.88;
      if (eng.screenShake < 0.2) eng.screenShake = 0;
    };

    /** 배경 타일 + UI 영역 흰색 바 */
    const drawBackground = (sheet) => {
      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

      if (sheet && eng.atlasReady) {
        eng.bgBricks.forEach(br => {
          sheet.drawFrame(ctx, 'brick_tile', br.x, br.y, br.w, br.h);
        });
      } else {
        ctx.strokeStyle = '#F1F5F9';
        ctx.lineWidth = 2;
        eng.bgBricks.forEach(b => {
          ctx.strokeRect(b.x, b.y, b.w, b.h);
        });
      }

      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, CANVAS_W, UI_TOP_H);
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 3;
      ctx.beginPath(); ctx.moveTo(0, UI_TOP_H); ctx.lineTo(CANVAS_W, UI_TOP_H); ctx.stroke();
    };

    /** [변경] 하트(아틀라스 입자), 나이프/별 아이콘 + 숫자 */
    const drawUI = (sheet) => {
      const iconY = 8;
      if (sheet && eng.atlasReady) {
        let hx = 12;
        for (let h = 0; h < eng.hearts; h++) {
          sheet.drawFrame(ctx, 'particle_red', hx, iconY + 6, 14, 14);
          hx += 18;
        }
        sheet.drawFrame(ctx, 'icon_knife', CANVAS_W / 2 - 52, iconY, 22, 44);
        ctx.fillStyle = '#000000';
        ctx.font = 'bold 20px monospace';
        ctx.textAlign = 'left';
        ctx.textBaseline = 'middle';
        let ballStr = eng.ballCount < 10 ? `0${eng.ballCount}` : String(eng.ballCount);
        ctx.fillText(ballStr, CANVAS_W / 2 - 22, 26);

        const starCount = eng.blocks.filter(b => b.type === 'STAR').length;
        sheet.drawFrame(ctx, 'icon_star', CANVAS_W - 88, iconY + 2, 28, 28);
        ctx.fillStyle = '#FBBF24';
        ctx.font = 'bold 16px sans-serif';
        ctx.textAlign = 'left';
        ctx.fillText(`목표 ${starCount}`, CANVAS_W - 54, 26);
      } else {
        ctx.fillStyle = '#EF4444';
        ctx.font = '24px sans-serif';
        ctx.textAlign = 'left';
        ctx.fillText('♥'.repeat(Math.max(0, eng.hearts)), 15, 35);
        ctx.fillStyle = '#000000';
        ctx.font = 'bold 22px monospace';
        ctx.textAlign = 'center';
        let ballStr = eng.ballCount < 10 ? `0${eng.ballCount}` : String(eng.ballCount);
        ctx.fillText(`🗡️${ballStr}/99`, CANVAS_W / 2, 35);
        const starCount = eng.blocks.filter(b => b.type === 'STAR').length;
        ctx.fillStyle = '#FBBF24'; 
        ctx.font = 'bold 18px sans-serif';
        ctx.textAlign = 'right';
        ctx.fillText(`목표: ⭐ ${starCount}`, CANVAS_W - 15, 33);
      }
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
    };

    const blockFrameName = (b) => {
      const t = eng.frameCount;
      if (b.type === 'NORMAL') return 'block_normal';
      if (b.type === 'POW') return (Math.floor(t / 20) % 2 === 0) ? 'block_pow_dark' : 'block_pow_lit';
      if (b.type === 'STAR') {
        const c = Math.floor(t / 15) % 3;
        if (c === 0) return 'block_star_dim';
        if (c === 1) return 'block_star_bright';
        return 'block_star_glow';
      }
      if (b.type === 'RED_ENEMY') return (Math.floor(t / 18) % 2 === 0) ? 'block_red_enemy' : 'block_red_enemy_alt';
      return 'block_normal';
    };

    const drawBlocks = (sheet) => {
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      eng.blocks.forEach(b => {
        const name = blockFrameName(b);
        if (sheet && eng.atlasReady) {
          sheet.drawFrame(ctx, name, b.x, b.y, b.w, b.h);
        } else {
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(b.x, b.y, b.w, b.h);
          ctx.strokeStyle = '#000';
          ctx.lineWidth = 2;
          ctx.strokeRect(b.x, b.y, b.w, b.h);
        }
        if (b.type === 'NORMAL' || b.type === 'RED_ENEMY') {
          ctx.fillStyle = '#000000';
          ctx.font = 'bold 18px sans-serif';
          ctx.fillText(b.hp, b.x + b.w / 2, b.y + b.h / 2 + 2);
        }
        if (b.type === 'POW') {
          ctx.fillStyle = '#FBBF24';
          ctx.font = 'bold 14px sans-serif';
          ctx.fillText('POW', b.x + b.w / 2, b.y + b.h / 2 + 2);
        }
        if (b.type === 'STAR') {
          ctx.fillStyle = '#FBBF24';
          ctx.font = 'bold 22px sans-serif';
          ctx.fillText('★', b.x + b.w / 2, b.y + b.h / 2 + 2);
        }
      });
    };

    const drawAimLine = () => {
      if (eng.state === 'AIMING' && eng.dragging) {
        ctx.strokeStyle = '#FBBF24';
        ctx.lineWidth = 3;
        ctx.setLineDash([8, 8]);
        ctx.beginPath();
        ctx.moveTo(eng.startPos.x, eng.startPos.y - 76);
        ctx.lineTo(eng.startPos.x + Math.cos(eng.aimAngle) * CANVAS_H, eng.startPos.y - 76 + Math.sin(eng.aimAngle) * CANVAS_H);
        ctx.stroke();
        ctx.setLineDash([]);
      }
    };

    const drawTutorialHint = () => {
      if (eng.state === 'SHOOTING' && eng.level <= 2 && Math.floor(eng.frameCount / 30) % 2 === 0) {
        ctx.fillStyle = '#4ADE80';
        ctx.font = 'bold 16px sans-serif';
        ctx.fillText('좌우(방향키, A/D)로 나이프를 튕겨내세요!', CANVAS_W / 2, CANVAS_H / 2 + 100);
      }
    };

    const drawBalls = (sheet) => {
      const mainW = 14, mainH = 28;
      const smallW = 11, smallH = 22;
      eng.balls.forEach(b => {
        if (!b.active) return;
        const angle = b.drawAngle !== undefined ? b.drawAngle : Math.atan2(b.vy, b.vx) + Math.PI / 2;
        if (sheet && eng.atlasReady) {
          const name = b.isSmall ? 'knife_small' : 'knife_big';
          const dw = b.isSmall ? smallW : mainW;
          const dh = b.isSmall ? smallH : mainH;
          sheet.drawFrameRotated(ctx, name, b.x, b.y, dw, dh, angle);
        } else {
          ctx.save();
          ctx.translate(b.x, b.y);
          ctx.rotate(angle);
          ctx.fillStyle = b.isSmall ? '#A0A0B0' : '#C0C0C0';
          ctx.fillRect(-3, -12, 6, 14);
          ctx.restore();
        }
      });
    };

    const drawKnifeStack = (sheet) => {
      if (eng.state !== 'AIMING' || eng.ballCount <= 0) return;
      const knifeCount = Math.min(eng.ballCount, 12);
      const spacing = 5;
      const rowOffsetX = -((knifeCount - 1) * spacing) / 2;
      for (let ki = 0; ki < knifeCount; ki++) {
        const kx = eng.startPos.x + rowOffsetX + ki * spacing;
        const ky = eng.startPos.y + 2;
        if (sheet && eng.atlasReady) {
          sheet.drawFrameRotated(ctx, 'knife_small', kx, ky, 8, 16, 0);
        } else {
          ctx.fillStyle = '#C0C0C0';
          ctx.fillRect(kx - 2, ky - 6, 4, 8);
        }
      }
    };

    const drawMaid = (sheet) => {
      const px = eng.startPos.x;
      const py = eng.startPos.y;
      const idleNames = ['maid_small_1', 'maid_small_2', 'maid_small_3', 'maid_small_4'];
      const throwNames = ['maid_big_1', 'maid_big_2', 'maid_big_3', 'maid_big_4'];
      const names = eng.state === 'SHOOTING' ? throwNames : idleNames;
      const frameName = names[eng.maidFrame % 4];

      if (sheet && eng.atlasReady) {
        sheet.drawFrame(ctx, frameName, px - MAID_CHAR_W / 2, py - MAID_CHAR_H + 8, MAID_CHAR_W, MAID_CHAR_H);
      } else {
        ctx.fillStyle = '#3730A3';
        ctx.fillRect(px - 15, py - 40, 30, 44);
      }
    };

    const drawPaddle = (sheet) => {
      const px = eng.startPos.x;
      const py = eng.startPos.y;
      const paddleY = py - 70;
      const half = PADDLE_WIDTH / 2;
      if (sheet && eng.atlasReady) {
        sheet.drawFrame(ctx, 'paddle_tray', px - half, paddleY, PADDLE_WIDTH, 12);
      } else {
        ctx.fillStyle = '#E5E7EB';
        ctx.fillRect(px - half, paddleY, PADDLE_WIDTH, 10);
        ctx.strokeStyle = '#6B7280';
        ctx.lineWidth = 2;
        ctx.strokeRect(px - half, paddleY, PADDLE_WIDTH, 10);
      }
    };

    const drawParticles = (sheet) => {
      for (let i = 0; i < eng.particles.length; i++) {
        const p = eng.particles[i];
        const s = 3 + p.life * 2;
        ctx.globalAlpha = Math.min(1, p.life);
        if (sheet && eng.atlasReady && p.frame) {
          sheet.drawFrame(ctx, p.frame, p.x, p.y, s, s);
        } else {
          ctx.fillStyle = '#888';
          ctx.fillRect(p.x, p.y, s, s);
        }
      }
      ctx.globalAlpha = 1;
    };

    /** 스테이지 클리어: 알파·문구로 부드럽게 */
    const drawStageClearOverlay = () => {
      if (eng.state !== 'STAGE_CLEAR') return;
      const t = eng.stageClearTimer;
      const a = Math.min(0.65, 0.12 + t * 0.02);
      ctx.fillStyle = `rgba(0,0,0,${a})`;
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
      ctx.fillStyle = '#4ADE80'; 
      ctx.font = 'bold 34px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('STAGE CLEAR!', CANVAS_W / 2, CANVAS_H / 2 - 24);
      ctx.fillStyle = '#FFFFFF';
      ctx.font = '18px sans-serif';
      ctx.fillText(`다음 레벨: ${eng.level + 1}`, CANVAS_W / 2, CANVAS_H / 2 + 18);
    };

    const drawGameOverOverlay = () => {
      if (eng.state !== 'GAME_OVER') return;
      ctx.fillStyle = 'rgba(0,0,0,0.82)';
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
      ctx.fillStyle = '#EF4444';
      ctx.font = 'bold 38px sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('GAME OVER', CANVAS_W / 2, CANVAS_H / 2 - 24);
      ctx.fillStyle = '#FFFFFF';
      ctx.font = '18px sans-serif';
      ctx.fillText('터치하여 현재 레벨 재시작', CANVAS_W / 2, CANVAS_H / 2 + 28);
    };

    const update = () => {
      if (!running) return;
      eng.frameCount++;

      const sheet = eng.spriteSheet;

      updateMaidAnimation();
      updateStageClear();
      updatePaddle();

      if (eng.state === 'SHOOTING') {
        updateRedEnemyBlocks();
        updateBalls();
      } else if (eng.state !== 'STAGE_CLEAR') {
        eng.tutorialTimer = 0; 
      }

      updateParticles();
      decayShake();

      const sx = eng.screenShake > 0 ? (Math.random() - 0.5) * eng.screenShake : 0;
      const sy = eng.screenShake > 0 ? (Math.random() - 0.5) * eng.screenShake * 0.7 : 0;
      ctx.setTransform(1, 0, 0, 1, sx, sy);

      drawBackground(sheet);
      drawUI(sheet);
      drawBlocks(sheet);
      drawAimLine();
      drawTutorialHint();
      drawBalls(sheet);
      drawKnifeStack(sheet);
      drawMaid(sheet);
      drawPaddle(sheet);
      drawParticles(sheet);
      drawStageClearOverlay();
      drawGameOverOverlay();

      ctx.setTransform(1, 0, 0, 1, 0, 0);

      if (running) {
        animationId = requestAnimationFrame(update);
      }
    };

    const handleKeyDown = (e) => {
      if (e.key === 'a' || e.key === 'A' || e.key === 'ArrowLeft') eng.keys.left = true;
      if (e.key === 'd' || e.key === 'D' || e.key === 'ArrowRight') eng.keys.right = true;
    };
    
    const handleKeyUp = (e) => {
      if (e.key === 'a' || e.key === 'A' || e.key === 'ArrowLeft') eng.keys.left = false;
      if (e.key === 'd' || e.key === 'D' || e.key === 'ArrowRight') eng.keys.right = false;
    };
    
    window.addEventListener('keydown', handleKeyDown);
    window.addEventListener('keyup', handleKeyUp);

    initGame();
    animationId = requestAnimationFrame(update);

    return () => {
      running = false;
      cancelAnimationFrame(animationId);
      window.removeEventListener('keydown', handleKeyDown); 
      window.removeEventListener('keyup', handleKeyUp);
    };
  }, []);

  const handlePointerDown = (e) => {
    const eng = engineRef.current;
    
    if (eng.state === 'GAME_OVER') {
      eng.hearts = 3; 
      eng.ballCount = 3;
      if (eng.initLevel) eng.initLevel(eng.level);
      return;
    }
    
    if (eng.state === 'AIMING') {
      eng.dragging = true;
    } else if (eng.state === 'SHOOTING') {
      eng.paddleDragging = true;
    }
    
    handlePointerMove(e);
    e.target.setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e) => {
    const eng = engineRef.current;
    if (eng.state === 'STAGE_CLEAR' || eng.state === 'GAME_OVER') return;

    const rect = canvasRef.current.getBoundingClientRect();
    const scaleX = CANVAS_W / rect.width;
    const scaleY = CANVAS_H / rect.height;
    const x = (e.clientX - rect.left) * scaleX;
    const y = (e.clientY - rect.top) * scaleY;
    eng.pointerCanvasX = Math.max(20, Math.min(CANVAS_W - 20, x));

    if (eng.state === 'AIMING' && eng.dragging) {
      const dx = x - eng.startPos.x;
      const dy = y - eng.startPos.y;
      let angle = Math.atan2(dy, dx);
      if (angle > -0.1) angle = -0.1;
      if (angle < -Math.PI + 0.1) angle = -Math.PI + 0.1;
      eng.aimAngle = angle;
    } 
    // [변경] 슈팅 중 패들은 좌표만 저장하고, 실제 이동은 updatePaddle에서 보간(모바일 떨림 완화)
    else if (eng.state === 'SHOOTING' && eng.paddleDragging) {
      eng.pointerCanvasX = Math.max(20, Math.min(CANVAS_W - 20, x));
    }
  };

  const handlePointerUp = () => {
    const eng = engineRef.current;
    if (eng.state === 'AIMING' && eng.dragging) {
      eng.dragging = false;
      eng.state = 'SHOOTING';
      eng.ballsToShoot = eng.ballCount;
      eng.firePos = { x: eng.startPos.x, y: eng.startPos.y };
      eng.pointerCanvasX = eng.startPos.x;
    } else if (eng.state === 'SHOOTING' && eng.paddleDragging) {
      eng.paddleDragging = false;
    }
  };

  return (
    <div className="flex items-center justify-center h-full bg-gray-900 font-sans overflow-hidden">
      <div className="relative w-full max-w-md h-full sm:h-[850px] sm:max-h-[90vh] sm:rounded-3xl shadow-2xl overflow-hidden bg-white sm:border-4 border-slate-800 cursor-crosshair">
        
        <button 
          onClick={onExit}
          className="absolute top-2 right-4 z-50 p-2 bg-black/10 hover:bg-black/20 rounded-full transition-colors font-bold text-xl"
        >
          ✖
        </button>

        <canvas
          ref={canvasRef}
          width={CANVAS_W}
          height={CANVAS_H}
          className="w-full h-full object-cover touch-none"
          onPointerDown={handlePointerDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          onPointerCancel={handlePointerUp}
          style={{ imageRendering: 'pixelated' }}
        />
      </div>
    </div>
  );
}
