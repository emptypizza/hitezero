import { BLOCK_W, BLOCK_H, PADDLE_WIDTH } from '../constants';

export function generateTextures(scene: Phaser.Scene): void {
  createKnifeTexture(scene);
  createMiniKnifeTexture(scene);
  createBlockTextures(scene);
  createPaddleTexture(scene);
  createParticleTexture(scene);
  createMaidFallback(scene);
}

function createKnifeTexture(scene: Phaser.Scene): void {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  // Blade
  g.fillStyle(0xc0c0c0);
  g.fillTriangle(6, 0, 9, 12, 3, 12);
  // Highlight
  g.fillStyle(0xffffff, 0.5);
  g.fillTriangle(6, 0, 7.5, 10, 5.5, 10);
  // Guard
  g.fillStyle(0x4b5563);
  g.fillRect(2, 12, 8, 2);
  // Handle
  g.fillStyle(0x92400e);
  g.fillRect(4, 14, 4, 6);
  g.generateTexture('knife', 12, 20);
  g.destroy();
}

function createMiniKnifeTexture(scene: Phaser.Scene): void {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(0xa0a0b0);
  g.fillTriangle(5, 0, 8, 11, 2, 11);
  g.fillStyle(0x4b5563);
  g.fillRect(1.5, 11, 7, 2.5);
  g.generateTexture('mini_knife', 10, 14);
  g.destroy();
}

function createBlockTextures(scene: Phaser.Scene): void {
  const bw = Math.floor(BLOCK_W - 4);
  const bh = Math.floor(BLOCK_H - 4);

  // NORMAL block (dark with neon border)
  let g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(0x16162a);
  g.fillRect(0, 0, bw, bh);
  g.lineStyle(2, 0x4444aa, 0.7);
  g.strokeRect(1, 1, bw - 2, bh - 2);
  // Inner highlight
  g.fillStyle(0x222244, 0.5);
  g.fillRect(2, 2, bw - 4, 3);
  g.generateTexture('block_normal', bw, bh);
  g.destroy();

  // POW block (dark with magenta glow)
  g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(0x1a0a2e);
  g.fillRect(0, 0, bw, bh);
  g.lineStyle(2, 0xff00ff, 0.6);
  g.strokeRect(1, 1, bw - 2, bh - 2);
  g.generateTexture('block_pow', bw, bh);
  g.destroy();

  // STAR block (dark with golden neon border)
  g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(0x1a1a0a);
  g.fillRect(0, 0, bw, bh);
  g.lineStyle(2, 0xffcc00, 0.7);
  g.strokeRect(1, 1, bw - 2, bh - 2);
  // Star glow center
  g.fillStyle(0xffcc00, 0.15);
  g.fillRect(bw / 4, bh / 4, bw / 2, bh / 2);
  g.generateTexture('block_star', bw, bh);
  g.destroy();

  // RED_ENEMY block (dark with red neon glow)
  g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(0x2a0a0a);
  g.fillRect(0, 0, bw, bh);
  g.lineStyle(2, 0xff2244, 0.8);
  g.strokeRect(1, 1, bw - 2, bh - 2);
  // Neon eyes
  g.fillStyle(0xff0000, 0.9);
  g.fillRect(10, 18, 8, 8);
  g.fillRect(bw - 18, 18, 8, 8);
  g.fillStyle(0xffffff);
  g.fillRect(12, 20, 4, 4);
  g.fillRect(bw - 16, 20, 4, 4);
  // Angry eyebrows (neon red)
  g.lineStyle(2, 0xff4444);
  g.beginPath();
  g.moveTo(8, 12);
  g.lineTo(20, 18);
  g.strokePath();
  g.beginPath();
  g.moveTo(bw - 8, 12);
  g.lineTo(bw - 20, 18);
  g.strokePath();
  g.generateTexture('block_red_enemy', bw, bh);
  g.destroy();
}

function createPaddleTexture(scene: Phaser.Scene): void {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  // Dark metallic tray with neon edge
  g.fillStyle(0x1a1a2e);
  g.fillRect(0, 0, PADDLE_WIDTH, 10);
  g.fillStyle(0x2a2a4e);
  g.fillRect(4, 0, PADDLE_WIDTH - 8, 4);
  // Neon cyan highlight strip
  g.fillStyle(0x00ffff, 0.6);
  g.fillRect(PADDLE_WIDTH / 4, 1, PADDLE_WIDTH / 2, 2);
  // Border — neon glow
  g.lineStyle(2, 0x00ccff, 0.7);
  g.strokeRect(0, 0, PADDLE_WIDTH, 10);
  // Inner highlight
  g.lineStyle(1, 0x00ffff, 0.3);
  g.beginPath();
  g.moveTo(8, 3);
  g.lineTo(PADDLE_WIDTH - 8, 3);
  g.strokePath();
  g.generateTexture('paddle_tray', PADDLE_WIDTH, 10);
  g.destroy();
}

function createParticleTexture(scene: Phaser.Scene): void {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  g.fillStyle(0xffffff);
  g.fillRect(0, 0, 4, 4);
  g.generateTexture('particle', 4, 4);
  g.destroy();
}

function createMaidFallback(scene: Phaser.Scene): void {
  const g = scene.make.graphics({ x: 0, y: 0 }, false);
  const cx = 30;
  // Hair (silver)
  g.fillStyle(0xc0c0d0);
  g.fillCircle(cx, 14, 14);
  // Headband
  g.fillStyle(0xffffff);
  g.fillRect(cx - 16, 2, 32, 6);
  g.lineStyle(1, 0xffb0c0);
  g.strokeRect(cx - 16, 2, 32, 6);
  // Eyes
  g.fillStyle(0x000000);
  g.fillCircle(cx - 5, 12, 2);
  g.fillCircle(cx + 5, 12, 2);
  // Dress (blue)
  g.fillStyle(0x3730a3);
  g.fillTriangle(cx - 12, 26, cx + 12, 26, cx + 18, 58);
  g.fillTriangle(cx - 12, 26, cx - 18, 58, cx + 18, 58);
  // Apron (white)
  g.fillStyle(0xffffff);
  g.fillTriangle(cx - 8, 28, cx + 8, 28, cx + 12, 58);
  g.fillTriangle(cx - 8, 28, cx - 12, 58, cx + 12, 58);
  // Green ribbon
  g.fillStyle(0x10b981);
  g.fillTriangle(cx - 5, 26, cx, 30, cx + 5, 26);
  g.generateTexture('maid_fallback', 60, 64);
  g.destroy();
}
