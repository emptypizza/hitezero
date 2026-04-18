import Phaser from 'phaser';
import {
  CANVAS_W, CANVAS_H, BOTTOM_Y, BALL_SPEED,
  PADDLE_SPEED, PADDLE_WIDTH, PADDLE_Y_OFFSET,
  TOP_BAR_HEIGHT, SPAWN_INTERVAL, HEARTS_MAX, KNIFE_RADIUS,
} from '../constants';
import { GameState, BlockType } from '../types';
import { initLevel } from '../helpers/LevelGenerator';

export class GameScene extends Phaser.Scene {
  // Groups
  blocks!: Phaser.Physics.Arcade.StaticGroup;
  movingBlocks!: Phaser.Physics.Arcade.Group;
  knives!: Phaser.Physics.Arcade.Group;

  // State
  state: GameState = GameState.AIMING;
  level = 1;
  knifeCount = 3;
  knivesToShoot = 0;
  pendingStars = 0;
  hearts = HEARTS_MAX;
  score = 0;
  aimAngle = -Math.PI / 2;
  dragging = false;
  paddleDragging = false;

  // Objects
  private paddleX = CANVAS_W / 2;
  private paddleY = BOTTOM_Y;
  private fireX = CANVAS_W / 2;
  private paddleContainer!: Phaser.GameObjects.Container;
  private maidSprite!: Phaser.GameObjects.Sprite;
  private traySprite!: Phaser.GameObjects.Image;
  private currentMaidAnim = '';
  maidBreathTween?: Phaser.Tweens.Tween;
  private aimLine!: Phaser.GameObjects.Graphics;
  private bgGraphics!: Phaser.GameObjects.Graphics;
  private waitingKnivesContainer!: Phaser.GameObjects.Container;

  // Input
  private keys!: {
    left: Phaser.Input.Keyboard.Key;
    right: Phaser.Input.Keyboard.Key;
    a: Phaser.Input.Keyboard.Key;
    d: Phaser.Input.Keyboard.Key;
  };

  // Timers
  private spawnTimer?: Phaser.Time.TimerEvent;
  // Stored so it can be cancelled if needed
  clearTimer?: Phaser.Time.TimerEvent;

  // Particles
  private particleEmitter!: Phaser.GameObjects.Particles.ParticleEmitter;

  // Tutorial
  private tutorialText!: Phaser.GameObjects.Text;

  // Post-processing
  private crtApplied = false;

  constructor() {
    super({ key: 'Game' });
  }

  create(): void {
    this.state = GameState.AIMING;
    this.level = 1;
    this.knifeCount = 3;
    this.hearts = HEARTS_MAX;
    this.score = 0;
    this.paddleX = CANVAS_W / 2;
    this.paddleY = BOTTOM_Y;
    this.dragging = false;
    this.paddleDragging = false;

    // Background image
    if (this.textures.exists('bg')) {
      this.add.image(CANVAS_W / 2, CANVAS_H / 2, 'bg')
        .setDisplaySize(CANVAS_W, CANVAS_H)
        .setDepth(-1);
    }
    this.bgGraphics = this.add.graphics();
    this.drawBackground();
    this.cameras.main.setBackgroundColor('#0a0a0f');

    // Physics groups
    this.blocks = this.physics.add.staticGroup();
    this.movingBlocks = this.physics.add.group();
    this.knives = this.physics.add.group();

    // Paddle setup — use individual PNG sprites
    const hasIdlePng = this.textures.exists('maid_idle');
    if (hasIdlePng) {
      this.maidSprite = this.add.sprite(0, -42, 'maid_idle').setDisplaySize(70, 70);
    } else {
      this.maidSprite = this.add.sprite(0, -32, 'maid_fallback').setDisplaySize(60, 64);
    }
    this.currentMaidAnim = 'idle';

    // Breathing tween — gentle scale pulse
    this.maidBreathTween = this.tweens.add({
      targets: this.maidSprite,
      scaleY: this.maidSprite.scaleY * 1.03,
      duration: 1200,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });

    // Paddle tray — from atlas if available
    const hasAtlas = this.textures.exists('atlas');
    if (hasAtlas) {
      this.traySprite = this.add.image(0, -PADDLE_Y_OFFSET, 'atlas', 'paddle_tray')
        .setDisplaySize(PADDLE_WIDTH, 12);
    } else {
      this.traySprite = this.add.image(0, -PADDLE_Y_OFFSET, 'paddle_tray');
    }
    this.paddleContainer = this.add.container(this.paddleX, this.paddleY, [
      this.maidSprite,
      this.traySprite,
    ]);

    // Aim line
    this.aimLine = this.add.graphics();

    // Waiting knives display
    this.waitingKnivesContainer = this.add.container(0, 0);
    this.updateWaitingKnives();

    // Particle emitter — use atlas particle if available
    const particleKey = hasAtlas ? 'atlas' : 'particle';
    const particleFrame = hasAtlas ? 'particle_orange' : undefined;
    this.particleEmitter = this.add.particles(0, 0, particleKey, {
      frame: particleFrame,
      speed: { min: 60, max: 240 },
      lifespan: 400,
      alpha: { start: 1, end: 0 },
      scale: { start: 1.5, end: 0.5 },
      emitting: false,
    });
    this.particleEmitter.setDepth(5);

    // Tutorial text
    this.tutorialText = this.add.text(
      CANVAS_W / 2, CANVAS_H / 2 + 100,
      '\uc88c\uc6b0(\ubc29\ud5a5\ud0a4, A/D)\ub85c \ub098\uc774\ud504\ub97c \ud295\uaca8\ub0b4\uc138\uc694!',
      { fontFamily: 'sans-serif', fontSize: '16px', fontStyle: 'bold', color: '#4ADE80' },
    ).setOrigin(0.5).setVisible(false).setDepth(6);

    // Input
    this.keys = this.input.keyboard!.addKeys({
      left: Phaser.Input.Keyboard.KeyCodes.LEFT,
      right: Phaser.Input.Keyboard.KeyCodes.RIGHT,
      a: Phaser.Input.Keyboard.KeyCodes.A,
      d: Phaser.Input.Keyboard.KeyCodes.D,
    }) as typeof this.keys;

    this.input.on('pointerdown', this.onPointerDown, this);
    this.input.on('pointermove', this.onPointerMove, this);
    this.input.on('pointerup', this.onPointerUp, this);

    // Launch UI overlay
    this.scene.launch('UI', { gameScene: this });

    // Generate level
    initLevel(this, this.level);
    this.emitUIUpdate();

    // Apply CRT scanline + glow post-processing (WebGL only)
    if (!this.crtApplied && this.renderer.type === Phaser.WEBGL) {
      this.cameras.main.setPostPipeline(['CRTPostFX', 'GlowPostFX']);
      this.crtApplied = true;
    }
  }

  update(_time: number, _delta: number): void {
    if (this.state === GameState.STAGE_CLEAR || this.state === GameState.GAME_OVER) return;

    // Paddle keyboard movement
    const dt = _delta / 1000;
    if (this.keys.left.isDown || this.keys.a.isDown) {
      this.paddleX -= PADDLE_SPEED * dt;
    }
    if (this.keys.right.isDown || this.keys.d.isDown) {
      this.paddleX += PADDLE_SPEED * dt;
    }
    this.paddleX = Phaser.Math.Clamp(this.paddleX, 20, CANVAS_W - 20);
    this.paddleContainer.setPosition(this.paddleX, this.paddleY);

    // Aim line
    this.aimLine.clear();
    if (this.state === GameState.AIMING && this.dragging) {
      this.aimLine.lineStyle(3, 0xfbbf24);
      const startX = this.paddleX;
      const startY = this.paddleY - PADDLE_Y_OFFSET;
      const len = CANVAS_H;
      // Draw dashed line
      const segLen = 8;
      const dx = Math.cos(this.aimAngle) * segLen;
      const dy = Math.sin(this.aimAngle) * segLen;
      let cx = startX;
      let cy = startY;
      for (let i = 0; i < len / segLen; i += 2) {
        this.aimLine.beginPath();
        this.aimLine.moveTo(cx, cy);
        this.aimLine.lineTo(cx + dx, cy + dy);
        this.aimLine.strokePath();
        cx += dx * 2;
        cy += dy * 2;
        if (cy < 0 || cx < 0 || cx > CANVAS_W) break;
      }
    }

    // Update maid texture based on game state
    if (this.textures.exists('maid_idle') && this.currentMaidAnim !== 'hit') {
      const targetTex = this.state === GameState.SHOOTING ? 'maid_throw' : 'maid_idle';
      if (this.maidSprite.texture.key !== targetTex) {
        this.maidSprite.setTexture(targetTex);
        this.currentMaidAnim = this.state === GameState.SHOOTING ? 'throw' : 'idle';
      }
    }

    // Waiting knives visibility
    this.waitingKnivesContainer.setVisible(this.state === GameState.AIMING);
    if (this.state === GameState.AIMING) {
      this.waitingKnivesContainer.setPosition(this.paddleX, this.paddleY + 2);
    }

    // Tutorial text
    if (this.state === GameState.SHOOTING && this.level <= 2) {
      this.tutorialText.setVisible(Math.floor(this.time.now / 500) % 2 === 0);
    } else {
      this.tutorialText.setVisible(false);
    }

    // SHOOTING: update knives and check collisions
    if (this.state === GameState.SHOOTING) {
      this.updateKnives();
      this.updateRedEnemies();
      this.checkWinLose();
    }

    // Sync block label positions (for moving blocks)
    this.movingBlocks.getChildren().forEach((child) => {
      const block = child as Phaser.Physics.Arcade.Sprite;
      const label = block.getData('label') as Phaser.GameObjects.Text | undefined;
      if (label) label.setPosition(block.x, block.y);
    });
  }

  // --- Input handlers ---

  private onPointerDown(pointer: Phaser.Input.Pointer): void {
    if (this.state === GameState.GAME_OVER) {
      this.restartLevel();
      return;
    }
    if (this.state === GameState.AIMING) {
      this.dragging = true;
      this.updateAimAngle(pointer);
    } else if (this.state === GameState.SHOOTING) {
      this.paddleDragging = true;
      this.paddleX = Phaser.Math.Clamp(pointer.x, 20, CANVAS_W - 20);
    }
  }

  private onPointerMove(pointer: Phaser.Input.Pointer): void {
    if (this.state === GameState.AIMING && this.dragging) {
      this.updateAimAngle(pointer);
    } else if (this.state === GameState.SHOOTING && this.paddleDragging) {
      this.paddleX = Phaser.Math.Clamp(pointer.x, 20, CANVAS_W - 20);
    }
  }

  private onPointerUp(): void {
    if (this.state === GameState.AIMING && this.dragging) {
      this.dragging = false;
      this.startShooting();
    }
    this.paddleDragging = false;
  }

  private updateAimAngle(pointer: Phaser.Input.Pointer): void {
    const dx = pointer.x - this.paddleX;
    const dy = pointer.y - this.paddleY;
    let angle = Math.atan2(dy, dx);
    if (angle > -0.1) angle = -0.1;
    if (angle < -Math.PI + 0.1) angle = -Math.PI + 0.1;
    this.aimAngle = angle;
  }

  // --- Shooting ---

  private startShooting(): void {
    this.state = GameState.SHOOTING;
    this.knivesToShoot = this.knifeCount;
    this.fireX = this.paddleX;

    // Switch to throw sprite with punch animation
    if (this.textures.exists('maid_throw')) {
      this.maidSprite.setTexture('maid_throw');
      this.currentMaidAnim = 'throw';

      // Throw lunge forward effect
      const origY = this.maidSprite.y;
      this.tweens.add({
        targets: this.maidSprite,
        y: origY - 8,
        scaleX: this.maidSprite.scaleX * 1.1,
        scaleY: this.maidSprite.scaleY * 1.1,
        duration: 150,
        yoyo: true,
        ease: 'Back.easeOut',
      });
    }

    this.spawnTimer = this.time.addEvent({
      delay: SPAWN_INTERVAL,
      repeat: this.knivesToShoot - 1,
      callback: () => this.spawnKnife(),
    });

    this.emitUIUpdate();
  }

  private spawnKnife(): void {
    const x = this.fireX;
    const y = this.paddleY - PADDLE_Y_OFFSET;
    const hasAtlas = this.textures.exists('atlas');
    const knife = hasAtlas
      ? this.knives.create(x, y, 'atlas', 'knife_big') as Phaser.Physics.Arcade.Sprite
      : this.knives.create(x, y, 'knife') as Phaser.Physics.Arcade.Sprite;
    if (hasAtlas) knife.setDisplaySize(12, 24);
    knife.setData('isSmall', false);
    knife.setData('active', true);
    (knife.body as Phaser.Physics.Arcade.Body).setAllowGravity(false);
    (knife.body as Phaser.Physics.Arcade.Body).setCircle(KNIFE_RADIUS);
    knife.setVelocity(
      Math.cos(this.aimAngle) * BALL_SPEED * 60,
      Math.sin(this.aimAngle) * BALL_SPEED * 60,
    );
    this.knivesToShoot--;
  }

  private spawnMiniKnife(x: number, y: number, angle: number): void {
    const hasAtlas = this.textures.exists('atlas');
    const knife = hasAtlas
      ? this.knives.create(x, y, 'atlas', 'knife_small') as Phaser.Physics.Arcade.Sprite
      : this.knives.create(x, y, 'mini_knife') as Phaser.Physics.Arcade.Sprite;
    if (hasAtlas) knife.setDisplaySize(8, 16);
    knife.setData('isSmall', true);
    knife.setData('active', true);
    (knife.body as Phaser.Physics.Arcade.Body).setAllowGravity(false);
    (knife.body as Phaser.Physics.Arcade.Body).setCircle(KNIFE_RADIUS);
    knife.setVelocity(
      Math.cos(angle) * BALL_SPEED * 0.6 * 60,
      Math.sin(angle) * BALL_SPEED * 0.6 * 60,
    );
  }

  // --- Knife physics ---

  private updateKnives(): void {
    this.knives.getChildren().forEach((child) => {
      const knife = child as Phaser.Physics.Arcade.Sprite;
      if (!knife.getData('active')) return;

      const body = knife.body as Phaser.Physics.Arcade.Body;
      const kx = knife.x;
      const ky = knife.y;
      const r = KNIFE_RADIUS;

      // Wall bounces
      if (kx < r) { knife.setX(r); body.setVelocityX(Math.abs(body.velocity.x)); }
      if (kx > CANVAS_W - r) { knife.setX(CANVAS_W - r); body.setVelocityX(-Math.abs(body.velocity.x)); }
      if (ky < TOP_BAR_HEIGHT + r) { knife.setY(TOP_BAR_HEIGHT + r); body.setVelocityY(Math.abs(body.velocity.y)); }

      // Prevent near-horizontal velocity
      if (Math.abs(body.velocity.y) < 18) {
        body.setVelocityY(body.velocity.y >= 0 ? 18 : -18);
      }

      // Paddle bounce
      if (body.velocity.y > 0) {
        const py = this.paddleY - PADDLE_Y_OFFSET;
        if (ky + r >= py && ky - r <= py + 10) {
          if (kx >= this.paddleX - PADDLE_WIDTH / 2 && kx <= this.paddleX + PADDLE_WIDTH / 2) {
            const hitPoint = kx - this.paddleX;
            const normalizedHit = hitPoint / (PADDLE_WIDTH / 2);
            const maxBounceAngle = Math.PI / 2.5;
            const bounceAngle = normalizedHit * maxBounceAngle;
            const speed = body.velocity.length();
            body.setVelocity(
              Math.sin(bounceAngle) * speed,
              -Math.cos(bounceAngle) * speed,
            );
            knife.setY(py - r);
            this.burstParticles(kx, ky, 0x4ade80);
          }
        }
      }

      // Bottom deactivation
      if (ky >= BOTTOM_Y) {
        knife.setData('active', false);
        knife.setVisible(false);
        body.setVelocity(0, 0);
      }

      // Rotate knife to face velocity direction
      knife.setRotation(Math.atan2(body.velocity.y, body.velocity.x) + Math.PI / 2);

      // Block collisions
      this.checkBlockCollision(knife, this.blocks);
      this.checkBlockCollision(knife, this.movingBlocks);
    });
  }

  private checkBlockCollision(
    knife: Phaser.Physics.Arcade.Sprite,
    group: Phaser.Physics.Arcade.StaticGroup | Phaser.Physics.Arcade.Group,
  ): void {
    if (!knife.getData('active')) return;

    group.getChildren().forEach((child) => {
      const block = child as Phaser.Physics.Arcade.Sprite;
      if ((block.getData('hp') as number) <= 0) return;

      const body = knife.body as Phaser.Physics.Arcade.Body;
      const bx = block.x - block.displayWidth / 2;
      const by = block.y - block.displayHeight / 2;
      const bw = block.displayWidth;
      const bh = block.displayHeight;

      // Circle-vs-rect collision (ported from original resolveCollision)
      let testX = knife.x;
      let testY = knife.y;

      if (knife.x < bx) testX = bx;
      else if (knife.x > bx + bw) testX = bx + bw;
      if (knife.y < by) testY = by;
      else if (knife.y > by + bh) testY = by + bh;

      let distX = knife.x - testX;
      let distY = knife.y - testY;
      let distance = Math.sqrt(distX * distX + distY * distY);

      if (distance <= KNIFE_RADIUS) {
        const overlap = KNIFE_RADIUS - distance;
        if (distance === 0) {
          distX = body.velocity.x > 0 ? -1 : 1;
          distY = body.velocity.y > 0 ? -1 : 1;
          distance = 1.414;
        }
        const nx = distX / distance;
        const ny = distY / distance;

        knife.setX(knife.x + nx * overlap);
        knife.setY(knife.y + ny * overlap);

        if (Math.abs(nx) > Math.abs(ny)) {
          body.setVelocityX(-body.velocity.x);
        } else {
          body.setVelocityY(-body.velocity.y);
        }

        this.hitBlock(block);
      }
    });
  }

  private hitBlock(block: Phaser.Physics.Arcade.Sprite): void {
    let hp = block.getData('hp') as number;
    hp--;
    block.setData('hp', hp);

    const type = block.getData('blockType') as BlockType;
    const color = (type === BlockType.NORMAL) ? 0x000000 : 0xfbbf24;
    this.burstParticles(block.x, block.y, color);

    // Update label
    const label = block.getData('label') as Phaser.GameObjects.Text | undefined;
    if (label && (type === BlockType.NORMAL || type === BlockType.RED_ENEMY)) {
      label.setText(String(hp));
    }

    if (hp <= 0) {
      this.destroyBlock(block, type);
    }
  }

  private destroyBlock(block: Phaser.Physics.Arcade.Sprite, type: BlockType): void {
    const label = block.getData('label') as Phaser.GameObjects.Text | undefined;
    if (label) label.destroy();

    if (type === BlockType.STAR) {
      this.pendingStars++;
    } else if (type === BlockType.POW) {
      for (let k = 0; k < 8; k++) {
        const angle = (k / 8) * Math.PI * 2;
        this.spawnMiniKnife(block.x, block.y, angle);
      }
    }

    if (type === BlockType.RED_ENEMY) {
      this.movingBlocks.remove(block, true, true);
    } else {
      this.blocks.remove(block, true, true);
    }

    this.score += 100;
    this.emitUIUpdate();
  }

  // --- Red enemies ---

  private updateRedEnemies(): void {
    this.movingBlocks.getChildren().forEach((child) => {
      const block = child as Phaser.Physics.Arcade.Sprite;
      if (block.getData('blockType') !== BlockType.RED_ENEMY) return;
      if ((block.getData('hp') as number) <= 0) return;

      if (block.y + block.displayHeight / 2 > BOTTOM_Y - 20) {
        block.setData('hp', 0);
        this.hearts--;
        this.burstParticles(block.x, block.y, 0xef4444);
        this.playHitReaction();
        const label = block.getData('label') as Phaser.GameObjects.Text | undefined;
        if (label) label.destroy();
        this.movingBlocks.remove(block, true, true);
        this.emitUIUpdate();

        if (this.hearts <= 0) {
          this.triggerGameOver();
        }
      }
    });
  }

  // --- Win/Lose ---

  private checkWinLose(): void {
    const starsLeft = [
      ...this.blocks.getChildren(),
      ...this.movingBlocks.getChildren(),
    ].filter((c) => {
      const s = c as Phaser.Physics.Arcade.Sprite;
      return s.getData('blockType') === BlockType.STAR && (s.getData('hp') as number) > 0;
    }).length;

    if (starsLeft === 0) {
      this.triggerStageClear();
      return;
    }

    // Check all knives inactive
    const allInactive = this.knives.getChildren().every(
      (c) => !(c as Phaser.Physics.Arcade.Sprite).getData('active'),
    );
    const spawnDone = !this.spawnTimer || this.spawnTimer.getRemaining() <= 0;

    if (allInactive && spawnDone && this.knivesToShoot <= 0) {
      this.triggerGameOver();
    }
  }

  private triggerStageClear(): void {
    this.state = GameState.STAGE_CLEAR;
    this.knives.clear(true, true);
    this.knifeCount += this.pendingStars;
    this.pendingStars = 0;
    if (this.spawnTimer) this.spawnTimer.destroy();
    this.emitUIUpdate();

    // Celebratory bounce with throw pose
    this.maidSprite.setTexture('maid_throw');
    this.currentMaidAnim = 'clear';
    this.tweens.add({
      targets: this.maidSprite,
      y: this.maidSprite.y - 12,
      duration: 300,
      yoyo: true,
      repeat: 2,
      ease: 'Bounce.easeOut',
    });

    this.events.emit('stageClear', this.level);

    this.clearTimer = this.time.delayedCall(1200, () => {
      this.level++;
      initLevel(this, this.level);
      this.state = GameState.AIMING;
      this.paddleX = CANVAS_W / 2;
      this.currentMaidAnim = '';
      this.updateWaitingKnives();
      this.emitUIUpdate();
    });
  }

  private triggerGameOver(): void {
    this.state = GameState.GAME_OVER;
    if (this.spawnTimer) this.spawnTimer.destroy();
    this.knives.clear(true, true);
    this.emitUIUpdate();

    // Sad idle pose + shake
    this.maidSprite.setTexture('maid_idle');
    this.currentMaidAnim = 'gameover';
    this.maidSprite.setTint(0x888888);
    this.tweens.add({
      targets: this.maidSprite,
      x: this.maidSprite.x - 3,
      duration: 80,
      yoyo: true,
      repeat: 5,
    });

    this.events.emit('gameOver', this.score, this.level, this.hearts);
  }

  restartLevel(): void {
    this.hearts = HEARTS_MAX;
    this.state = GameState.AIMING;
    this.paddleX = CANVAS_W / 2;
    this.currentMaidAnim = 'idle';
    this.maidSprite.clearTint();
    this.maidSprite.setAlpha(1);
    if (this.textures.exists('maid_idle')) this.maidSprite.setTexture('maid_idle');
    initLevel(this, this.level);
    this.updateWaitingKnives();
    this.emitUIUpdate();
    this.events.emit('restart');
  }

  private playHitReaction(): void {
    this.currentMaidAnim = 'hit';

    // Flash red tint
    this.maidSprite.setTint(0xff4444);

    // Screen shake
    this.cameras.main.shake(150, 0.01);

    // Flash between throw and idle rapidly
    let flashCount = 0;
    const flashTimer = this.time.addEvent({
      delay: 100,
      repeat: 5,
      callback: () => {
        flashCount++;
        if (flashCount % 2 === 0) {
          this.maidSprite.setTexture('maid_idle');
          this.maidSprite.setAlpha(0.5);
        } else {
          this.maidSprite.setTexture('maid_throw');
          this.maidSprite.setAlpha(1);
        }
      },
    });

    // Restore after flash
    this.time.delayedCall(600, () => {
      flashTimer.destroy();
      this.maidSprite.clearTint();
      this.maidSprite.setAlpha(1);
      this.maidSprite.setTexture('maid_idle');
      this.currentMaidAnim = 'idle';
    });
  }

  // --- Helpers ---

  private drawBackground(): void {
    // Dim overlay — slightly more transparent so bg shows through
    this.bgGraphics.fillStyle(0x050510, 0.25);
    this.bgGraphics.fillRect(0, 0, CANVAS_W, CANVAS_H);
    this.bgGraphics.setDepth(0);

    // Neon arena border (cyan glow, double stroke for glow feel)
    this.bgGraphics.lineStyle(4, 0x00ffff, 0.15);
    this.bgGraphics.strokeRect(3, 3, CANVAS_W - 6, CANVAS_H - 6);
    this.bgGraphics.lineStyle(2, 0x00ffff, 0.4);
    this.bgGraphics.strokeRect(1, 1, CANVAS_W - 2, CANVAS_H - 2);

    // Subtle grid lines for arena feel
    this.bgGraphics.lineStyle(1, 0x1a1a3a, 0.3);
    for (let y = TOP_BAR_HEIGHT; y < CANVAS_H; y += 40) {
      this.bgGraphics.beginPath();
      this.bgGraphics.moveTo(0, y);
      this.bgGraphics.lineTo(CANVAS_W, y);
      this.bgGraphics.strokePath();
    }
    for (let x = 0; x < CANVAS_W; x += 40) {
      this.bgGraphics.beginPath();
      this.bgGraphics.moveTo(x, TOP_BAR_HEIGHT);
      this.bgGraphics.lineTo(x, CANVAS_H);
      this.bgGraphics.strokePath();
    }
  }

  private burstParticles(x: number, y: number, tint: number): void {
    this.particleEmitter.setParticleTint(tint);
    this.particleEmitter.emitParticleAt(x, y, 8);
  }

  private updateWaitingKnives(): void {
    this.waitingKnivesContainer.removeAll(true);
    const count = Math.min(this.knifeCount, 12);
    const spacing = 6;
    const offsetX = -((count - 1) * spacing) / 2;
    const hasAtlas = this.textures.exists('atlas');
    for (let i = 0; i < count; i++) {
      const knifeImg = hasAtlas
        ? this.add.image(offsetX + i * spacing, 0, 'atlas', 'knife_small').setDisplaySize(6, 12)
        : this.add.image(offsetX + i * spacing, 0, 'knife').setScale(0.6);
      this.waitingKnivesContainer.add(knifeImg);
    }
  }

  private emitUIUpdate(): void {
    this.events.emit('uiUpdate', {
      hearts: this.hearts,
      knifeCount: this.knifeCount,
      score: this.score,
      level: this.level,
      state: this.state,
      starsLeft: this.getStarsLeft(),
    });
  }

  private getStarsLeft(): number {
    return [
      ...this.blocks.getChildren(),
      ...this.movingBlocks.getChildren(),
    ].filter((c) => {
      const s = c as Phaser.Physics.Arcade.Sprite;
      return s.getData('blockType') === BlockType.STAR && (s.getData('hp') as number) > 0;
    }).length;
  }
}
