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
      {/* 칼날 */}
      <polygon points="50,5 60,50 50,55 40,50" fill={color} />
      <polygon points="50,5 60,50 50,45" fill="white" opacity="0.3" />
      {/* 가드 */}
      <rect x="35" y="52" width="30" height="6" rx="2" fill="#4B5563" />
      {/* 손잡이 */}
      <rect x="44" y="58" width="12" height="30" rx="3" fill="#92400E" />
      <rect x="46" y="60" width="8" height="26" rx="2" fill="#B45309" opacity="0.5" />
    </svg>
  );
}

// --- 게임 플레이 캔버스 (물리 엔진 및 렌더링) ---
const CANVAS_W = 400;
const CANVAS_H = 700;
const BOTTOM_Y = 620;
const BALL_SPEED = 12;
const BLOCK_COLS = 7;
const BLOCK_W = CANVAS_W / BLOCK_COLS;
const BLOCK_H = BLOCK_W;

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
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    const eng = engineRef.current;
    let animationId;
    let running = true;

    // --- ✨ 줄 생성 로직 (호이스팅을 위해 상단 배치) ---
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

    // --- ✨ 외부 클릭 핸들러에서도 재시작할 수 있도록 engineRef에 함수 바인딩 ---
    eng.initLevel = (level) => {
      eng.blocks = [];
      eng.balls = [];
      eng.ballsToShoot = 0;
      eng.pendingStars = 0;
      eng.tutorialTimer = 0;
      eng.startPos.x = CANVAS_W / 2; // 재시작 시 콩퍼스(패들)를 중앙으로 원복
      
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
      eng.bgBricks = Array.from({ length: 30 }).map(() => ({
        x: Math.random() * CANVAS_W, y: Math.random() * CANVAS_H,
        w: 20 + Math.random() * 30, h: 15
      }));

      // --- 메이드 캐릭터 스프라이트 로딩 ---
      eng.sprites = {};
      const idleImg = new Image();
      idleImg.src = '/assets/maid_idle.png';
      eng.sprites.idle = idleImg;
      const throwImg = new Image();
      throwImg.src = '/assets/maid_throw.png';
      eng.sprites.throw = throwImg;

      eng.initLevel(eng.level);
    };

    const addParticles = (x, y, color) => {
      for (let i = 0; i < 8; i++) {
        eng.particles.push({
          x, y,
          vx: (Math.random() - 0.5) * 8,
          vy: (Math.random() - 0.5) * 8,
          life: 1.0,
          color: color
        });
      }
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

    const update = () => {
      if (!running) return;
      eng.frameCount++;

      if (eng.state === 'STAGE_CLEAR') {
        eng.tutorialTimer++;
        if (eng.tutorialTimer > 18) {
          eng.level++;
          eng.initLevel(eng.level);
        }
      }

      const PADDLE_SPEED = 7;
      if (eng.keys.left && eng.state !== 'STAGE_CLEAR') eng.startPos.x -= PADDLE_SPEED;
      if (eng.keys.right && eng.state !== 'STAGE_CLEAR') eng.startPos.x += PADDLE_SPEED;
      
      eng.startPos.x = Math.max(20, Math.min(CANVAS_W - 20, eng.startPos.x));

      if (eng.state === 'SHOOTING') {
        
        eng.blocks.forEach(b => {
          if (b.type === 'RED_ENEMY') {
            b.y += 0.5; 
            
            if (b.y + b.h > BOTTOM_Y - 20 && b.hp > 0) {
              b.hp = 0; 
              eng.hearts--;
              addParticles(b.x + b.w / 2, b.y + b.h, '#EF4444');
              if (eng.hearts <= 0) eng.state = 'GAME_OVER';
            }
          }
        });

        if (eng.ballsToShoot > 0 && eng.frameCount % 4 === 0) {
          eng.balls.push({
            x: eng.firePos.x,
            y: eng.firePos.y - 76,
            vx: Math.cos(eng.aimAngle) * BALL_SPEED,
            vy: Math.sin(eng.aimAngle) * BALL_SPEED,
            radius: 5,
            active: true,
            isSmall: false
          });
          eng.ballsToShoot--;
        }

        let allInactive = true;
        
        for (let step = 0; step < 2; step++) {
          for (let i = 0; i < eng.balls.length; i++) {
            let b = eng.balls[i];
            if (!b.active) continue;
            allInactive = false;

            b.x += b.vx / 2;
            b.y += b.vy / 2;

            if (b.x < b.radius) { b.x = b.radius; b.vx = Math.abs(b.vx); }
            if (b.x > CANVAS_W - b.radius) { b.x = CANVAS_W - b.radius; b.vx = -Math.abs(b.vx); }
            if (b.y < 50 + b.radius) { b.y = 50 + b.radius; b.vy = Math.abs(b.vy); }

            if (Math.abs(b.vy) < 0.3) b.vy = b.vy >= 0 ? 0.3 : -0.3;

            if (b.vy > 0) { 
              const px = eng.startPos.x;
              const py = eng.startPos.y;
              const paddleWidth = 80;
              
              if (b.y + b.radius >= py - 76 && b.y - b.radius <= py - 64) {
                if (b.x >= px - paddleWidth / 2 && b.x <= px + paddleWidth / 2) {
                  const hitPoint = b.x - px;
                  const normalizedHit = hitPoint / (paddleWidth / 2); 
                  const maxBounceAngle = Math.PI / 2.5; 
                  const bounceAngle = normalizedHit * maxBounceAngle;
                  
                  const currentSpeed = Math.sqrt(b.vx*b.vx + b.vy*b.vy);
                  
                  b.vx = Math.sin(bounceAngle) * currentSpeed;
                  b.vy = -Math.cos(bounceAngle) * currentSpeed;
                  b.y = py - 76 - b.radius;
                  
                  addParticles(b.x, b.y, '#4ADE80');
                }
              }
            }

            if (b.y >= BOTTOM_Y) {
              b.y = BOTTOM_Y;
              b.active = false;
            }

            for (let j = 0; j < eng.blocks.length; j++) {
              let block = eng.blocks[j];
              if (block.hp > 0 && resolveCollision(b, block)) {
                block.hp--;
                addParticles(b.x, b.y, block.type === 'NORMAL' ? '#000' : '#FBBF24');
                
                if (block.hp <= 0) {
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
                        isSmall: true
                      });
                    }
                  }
                }
              }
            }
          }
        }

        eng.blocks = eng.blocks.filter(b => b.hp > 0);

        const starsLeft = eng.blocks.filter(b => b.type === 'STAR').length;

        // --- ✨ 별(목표)을 모두 파괴하면 즉시 클리어 ---
        if (starsLeft === 0) {
          eng.balls = []; // 화면에 남은 공 즉시 제거
          eng.ballCount += eng.pendingStars;
          eng.pendingStars = 0;
          eng.tutorialTimer = 0; // STAGE_CLEAR 대기 타이머 초기화
          eng.state = 'STAGE_CLEAR';
        }
        // --- ✨ 목표를 달성하지 못했는데 모든 공이 떨어지면 게임 오버 ---
        else if (allInactive && eng.ballsToShoot === 0) {
          eng.balls = []; 
          eng.pendingStars = 0; 
          eng.state = 'GAME_OVER';
        }
      } else if (eng.state !== 'STAGE_CLEAR') {
        eng.tutorialTimer = 0; 
      }

      eng.particles.forEach(p => {
        p.x += p.vx; p.y += p.vy;
        p.life -= 0.05;
      });
      eng.particles = eng.particles.filter(p => p.life > 0);

      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

      ctx.strokeStyle = '#F1F5F9';
      ctx.lineWidth = 2;
      eng.bgBricks.forEach(b => {
        ctx.strokeRect(b.x, b.y, b.w, b.h);
      });

      ctx.fillStyle = '#FFFFFF';
      ctx.fillRect(0, 0, CANVAS_W, 50);
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 3;
      ctx.beginPath(); ctx.moveTo(0, 50); ctx.lineTo(CANVAS_W, 50); ctx.stroke();

      ctx.fillStyle = '#EF4444';
      ctx.font = '24px sans-serif';
      ctx.textAlign = 'left';
      ctx.fillText('♥'.repeat(Math.max(0, eng.hearts)), 15, 35);

      ctx.fillStyle = '#000000';
      ctx.font = 'bold 22px monospace';
      ctx.textAlign = 'center';
      let ballStr = eng.ballCount < 10 ? `0${eng.ballCount}` : eng.ballCount;
      ctx.fillText(`🗡️${ballStr}/99`, CANVAS_W / 2, 35);

      const starCount = eng.blocks.filter(b => b.type === 'STAR').length;
      ctx.fillStyle = '#FBBF24'; 
      ctx.font = 'bold 18px sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(`목표: ⭐ ${starCount}`, CANVAS_W - 15, 33);

      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      eng.blocks.forEach(b => {
        if (b.type === 'NORMAL') {
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(b.x, b.y, b.w, b.h);
          ctx.strokeStyle = '#000000';
          ctx.lineWidth = 3;
          ctx.strokeRect(b.x, b.y, b.w, b.h);
          ctx.fillStyle = '#000000';
          ctx.font = 'bold 20px sans-serif';
          ctx.fillText(b.hp, b.x + b.w / 2, b.y + b.h / 2 + 2);
        } else if (b.type === 'POW') {
          ctx.fillStyle = '#000000';
          ctx.fillRect(b.x, b.y, b.w, b.h);
          ctx.fillStyle = '#FBBF24';
          ctx.font = 'bold 16px sans-serif';
          ctx.fillText('POW', b.x + b.w / 2, b.y + b.h / 2 + 2);
        } else if (b.type === 'STAR') {
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(b.x, b.y, b.w, b.h);
          ctx.strokeStyle = '#000000';
          ctx.lineWidth = 3;
          ctx.strokeRect(b.x, b.y, b.w, b.h);
          ctx.fillStyle = '#FBBF24';
          ctx.font = '24px sans-serif';
          ctx.fillText('★', b.x + b.w / 2, b.y + b.h / 2 + 2);
        } else if (b.type === 'RED_ENEMY') {
          ctx.fillStyle = '#EF4444'; 
          ctx.fillRect(b.x, b.y, b.w, b.h);
          ctx.strokeStyle = '#000000';
          ctx.lineWidth = 3;
          ctx.strokeRect(b.x, b.y, b.w, b.h);
          
          ctx.strokeStyle = '#000000';
          ctx.lineWidth = 2;
          ctx.beginPath(); ctx.moveTo(b.x + 8, b.y + 12); ctx.lineTo(b.x + 20, b.y + 18); ctx.stroke(); 
          ctx.beginPath(); ctx.moveTo(b.x + b.w - 8, b.y + 12); ctx.lineTo(b.x + b.w - 20, b.y + 18); ctx.stroke(); 
          
          ctx.fillStyle = '#FFFFFF';
          ctx.fillRect(b.x + 10, b.y + 18, 8, 8); 
          ctx.fillRect(b.x + b.w - 18, b.y + 18, 8, 8); 
          ctx.fillStyle = '#000000';
          ctx.fillRect(b.x + 12, b.y + 20, 4, 4); 
          ctx.fillRect(b.x + b.w - 16, b.y + 20, 4, 4); 
          
          ctx.fillStyle = '#FFFFFF';
          ctx.font = 'bold 16px sans-serif';
          ctx.fillText(b.hp, b.x + b.w / 2, b.y + b.h - 10);
        }
      });

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

      if (eng.state === 'SHOOTING' && eng.level <= 2 && Math.floor(eng.frameCount / 30) % 2 === 0) {
        ctx.fillStyle = '#4ADE80';
        ctx.font = 'bold 18px sans-serif';
        ctx.fillText('좌우(방향키, A/D)로 나이프를 튕겨내세요!', CANVAS_W / 2, CANVAS_H / 2 + 100);
      }

      // --- 나이프(투사체) 렌더링 ---
      eng.balls.forEach(b => {
        if (!b.active) return;
        ctx.save();
        ctx.translate(b.x, b.y);
        // 진행 방향에 따라 나이프 회전
        const angle = Math.atan2(b.vy, b.vx);
        ctx.rotate(angle + Math.PI / 2);
        
        if (!b.isSmall) {
          // 메인 나이프
          ctx.fillStyle = '#C0C0C0';
          ctx.beginPath();
          ctx.moveTo(0, -10);
          ctx.lineTo(3, 2);
          ctx.lineTo(-3, 2);
          ctx.closePath();
          ctx.fill();
          // 하이라이트
          ctx.fillStyle = '#FFFFFF';
          ctx.beginPath();
          ctx.moveTo(0, -10);
          ctx.lineTo(1.5, 0);
          ctx.lineTo(-0.5, 0);
          ctx.closePath();
          ctx.fill();
          ctx.globalAlpha = 0.5;
          ctx.fill();
          ctx.globalAlpha = 1.0;
          // 가드
          ctx.fillStyle = '#4B5563';
          ctx.fillRect(-4, 2, 8, 2);
          // 손잡이
          ctx.fillStyle = '#92400E';
          ctx.fillRect(-2, 4, 4, 6);
        } else {
          // 작은 나이프 (POW 파편) — 메인보다 작되 이전보다 크게
          ctx.fillStyle = '#A0A0B0';
          ctx.beginPath();
          ctx.moveTo(0, -9);
          ctx.lineTo(3, 2);
          ctx.lineTo(-3, 2);
          ctx.closePath();
          ctx.fill();
          ctx.fillStyle = '#4B5563';
          ctx.fillRect(-3.5, 2, 7, 2.5);
        }
        ctx.restore();
      });

      // --- 대기 중 나이프 표시 (최대 12자루, 캐릭터 기준 가운데 정렬) ---
      if (eng.state === 'AIMING' && eng.ballCount > 0) {
        const knifeCount = Math.min(eng.ballCount, 12);
        const spacing = 5;
        const rowOffsetX = -((knifeCount - 1) * spacing) / 2;
        for (let ki = 0; ki < knifeCount; ki++) {
          ctx.save();
          ctx.translate(eng.startPos.x + rowOffsetX + ki * spacing, eng.startPos.y + 2);
          ctx.fillStyle = '#C0C0C0';
          ctx.beginPath();
          ctx.moveTo(0, -6);
          ctx.lineTo(2, 1);
          ctx.lineTo(-2, 1);
          ctx.closePath();
          ctx.fill();
          ctx.fillStyle = '#92400E';
          ctx.fillRect(-1.5, 1, 3, 4);
          ctx.restore();
        }
      }

      const px = eng.startPos.x;
      const py = eng.startPos.y;

      // --- 메이드 캐릭터 스프라이트 렌더링 ---
      const spriteKey = eng.state === 'SHOOTING' ? 'throw' : 'idle';
      const sprite = eng.sprites?.[spriteKey];
      const CHAR_W = 60;
      const CHAR_H = 72;
      
      if (sprite && sprite.complete) {
        ctx.drawImage(sprite, px - CHAR_W / 2, py - CHAR_H + 8, CHAR_W, CHAR_H);
      } else {
        // 폴백: 간단한 메이드 실루엣
        // 머리 (은발)
        ctx.fillStyle = '#C0C0D0';
        ctx.beginPath(); ctx.arc(px, py - 40, 14, 0, Math.PI * 2); ctx.fill();
        // 헤드밴드
        ctx.fillStyle = '#FFFFFF';
        ctx.fillRect(px - 16, py - 52, 32, 6);
        ctx.strokeStyle = '#FFB0C0';
        ctx.lineWidth = 1;
        ctx.strokeRect(px - 16, py - 52, 32, 6);
        // 눈
        ctx.fillStyle = '#000000';
        ctx.beginPath(); ctx.arc(px - 5, py - 42, 2, 0, Math.PI * 2); ctx.fill();
        ctx.beginPath(); ctx.arc(px + 5, py - 42, 2, 0, Math.PI * 2); ctx.fill();
        // 드레스 (파란색)
        ctx.fillStyle = '#3730A3';
        ctx.beginPath();
        ctx.moveTo(px - 12, py - 28);
        ctx.lineTo(px + 12, py - 28);
        ctx.lineTo(px + 18, py + 4);
        ctx.lineTo(px - 18, py + 4);
        ctx.closePath();
        ctx.fill();
        // 에이프런 (흰색)
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.moveTo(px - 8, py - 26);
        ctx.lineTo(px + 8, py - 26);
        ctx.lineTo(px + 12, py + 4);
        ctx.lineTo(px - 12, py + 4);
        ctx.closePath();
        ctx.fill();
        // 녹색 리본
        ctx.fillStyle = '#10B981';
        ctx.beginPath();
        ctx.moveTo(px - 5, py - 28);
        ctx.lineTo(px, py - 24);
        ctx.lineTo(px + 5, py - 28);
        ctx.closePath();
        ctx.fill();
      }

      // --- 패들(은빛 쟁반/막대): 캐릭터 머리 위 ---
      const pWidth = 80;
      const paddleY = py - 70;

      // 은빛 쟁반 스타일 패들
      const paddleGrad = ctx.createLinearGradient(px - pWidth/2, paddleY, px + pWidth/2, paddleY + 10);
      paddleGrad.addColorStop(0, '#9CA3AF');
      paddleGrad.addColorStop(0.3, '#E5E7EB');
      paddleGrad.addColorStop(0.5, '#F9FAFB');
      paddleGrad.addColorStop(0.7, '#E5E7EB');
      paddleGrad.addColorStop(1, '#9CA3AF');
      ctx.fillStyle = paddleGrad;
      ctx.fillRect(px - pWidth / 2, paddleY, pWidth, 10);
      ctx.strokeStyle = '#6B7280';
      ctx.lineWidth = 2;
      ctx.strokeRect(px - pWidth / 2, paddleY, pWidth, 10);

      // 패들 하이라이트 라인
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1;
      ctx.globalAlpha = 0.6;
      ctx.beginPath();
      ctx.moveTo(px - pWidth / 2 + 8, paddleY + 3);
      ctx.lineTo(px + pWidth / 2 - 8, paddleY + 3);
      ctx.stroke();
      ctx.globalAlpha = 1.0;

      eng.particles.forEach(p => {
        ctx.fillStyle = p.color;
        ctx.globalAlpha = p.life;
        ctx.fillRect(p.x, p.y, 4, 4);
      });
      ctx.globalAlpha = 1.0;

      if (eng.state === 'STAGE_CLEAR') {
        ctx.fillStyle = 'rgba(0,0,0,0.6)';
        ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
        ctx.fillStyle = '#4ADE80'; 
        ctx.font = 'bold 36px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('STAGE CLEAR!', CANVAS_W / 2, CANVAS_H / 2 - 20);
        ctx.fillStyle = '#FFFFFF';
        ctx.font = '20px sans-serif';
        ctx.fillText(`다음 레벨: ${eng.level + 1}`, CANVAS_W / 2, CANVAS_H / 2 + 20);
      }

      // --- ✨ GAME OVER 연출 업데이트 ---
      if (eng.state === 'GAME_OVER') {
        ctx.fillStyle = 'rgba(0,0,0,0.8)';
        ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
        ctx.fillStyle = '#EF4444';
        ctx.font = 'bold 40px sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('GAME OVER', CANVAS_W / 2, CANVAS_H / 2 - 20);
        
        ctx.fillStyle = '#FFFFFF';
        ctx.font = '20px sans-serif';
        ctx.fillText('터치하여 현재 레벨 재시작', CANVAS_W / 2, CANVAS_H / 2 + 30);
      }

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
    
    // --- ✨ 게임 오버 화면 클릭 시 현재 레벨(eng.level)을 즉시 다시 시작 ---
    if (eng.state === 'GAME_OVER') {
      eng.hearts = 3; 
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

    if (eng.state === 'AIMING' && eng.dragging) {
      const dx = x - eng.startPos.x;
      const dy = y - eng.startPos.y;
      let angle = Math.atan2(dy, dx);
      if (angle > -0.1) angle = -0.1;
      if (angle < -Math.PI + 0.1) angle = -Math.PI + 0.1;
      eng.aimAngle = angle;
    } 
    else if (eng.state === 'SHOOTING' && eng.paddleDragging) {
      eng.startPos.x = Math.max(20, Math.min(CANVAS_W - 20, x));
    }
  };

  const handlePointerUp = () => {
    const eng = engineRef.current;
    if (eng.state === 'AIMING' && eng.dragging) {
      eng.dragging = false;
      eng.state = 'SHOOTING';
      eng.ballsToShoot = eng.ballCount;
      eng.firePos = { x: eng.startPos.x, y: eng.startPos.y }; 
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