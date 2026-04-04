import Phaser from 'phaser';
import { CANVAS_W, CANVAS_H, TOP_BAR_HEIGHT } from '../constants';
import { GameState } from '../types';
import type { GameScene } from './GameScene';

interface UIData {
  hearts: number;
  knifeCount: number;
  score: number;
  level: number;
  state: GameState;
  starsLeft: number;
}

export class UIScene extends Phaser.Scene {
  private heartsText!: Phaser.GameObjects.Text;
  private knifeCountText!: Phaser.GameObjects.Text;
  private starsText!: Phaser.GameObjects.Text;
  private overlay!: Phaser.GameObjects.Graphics;
  private overlayTitle!: Phaser.GameObjects.Text;
  private overlayInfo!: Phaser.GameObjects.Text;
  private overlaySubInfo!: Phaser.GameObjects.Text;
  private gameScene!: GameScene;

  constructor() {
    super({ key: 'UI' });
  }

  create(data: { gameScene: GameScene }): void {
    this.gameScene = data.gameScene;

    // Top bar background
    const topBar = this.add.graphics();
    topBar.fillStyle(0xffffff);
    topBar.fillRect(0, 0, CANVAS_W, TOP_BAR_HEIGHT);
    topBar.lineStyle(3, 0x000000);
    topBar.beginPath();
    topBar.moveTo(0, TOP_BAR_HEIGHT);
    topBar.lineTo(CANVAS_W, TOP_BAR_HEIGHT);
    topBar.strokePath();

    // Hearts
    this.heartsText = this.add.text(15, 25, '\u2665\u2665\u2665', {
      fontFamily: 'sans-serif',
      fontSize: '24px',
      color: '#EF4444',
    }).setOrigin(0, 0.5);

    // Knife count
    this.knifeCountText = this.add.text(CANVAS_W / 2, 25, '\ud83d\udde1\ufe0f03/99', {
      fontFamily: 'monospace',
      fontSize: '22px',
      fontStyle: 'bold',
      color: '#000000',
    }).setOrigin(0.5);

    // Stars left
    this.starsText = this.add.text(CANVAS_W - 15, 25, '\ubaa9\ud45c: \u2b50 0', {
      fontFamily: 'sans-serif',
      fontSize: '18px',
      fontStyle: 'bold',
      color: '#FBBF24',
    }).setOrigin(1, 0.5);

    // Overlay (stage clear / game over)
    this.overlay = this.add.graphics().setDepth(10).setVisible(false);
    this.overlayTitle = this.add.text(CANVAS_W / 2, CANVAS_H / 2 - 20, '', {
      fontFamily: 'sans-serif',
      fontSize: '36px',
      fontStyle: 'bold',
      color: '#ffffff',
    }).setOrigin(0.5).setDepth(11).setVisible(false);

    this.overlayInfo = this.add.text(CANVAS_W / 2, CANVAS_H / 2 + 20, '', {
      fontFamily: 'sans-serif',
      fontSize: '20px',
      color: '#ffffff',
    }).setOrigin(0.5).setDepth(11).setVisible(false);

    this.overlaySubInfo = this.add.text(CANVAS_W / 2, CANVAS_H / 2 + 55, '', {
      fontFamily: 'sans-serif',
      fontSize: '16px',
      color: '#ffffff',
    }).setOrigin(0.5).setDepth(11).setVisible(false);

    // Exit button
    const exitBtn = this.add.text(CANVAS_W - 10, 8, '\u2716', {
      fontFamily: 'sans-serif',
      fontSize: '20px',
      color: '#666666',
      backgroundColor: '#00000011',
      padding: { x: 6, y: 2 },
    }).setOrigin(1, 0).setInteractive({ useHandCursor: true }).setDepth(12);

    exitBtn.on('pointerdown', () => {
      this.gameScene.scene.stop();
      this.scene.stop();
      this.scene.start('Title');
    });

    // Listen to GameScene events
    this.gameScene.events.on('uiUpdate', this.onUIUpdate, this);
    this.gameScene.events.on('stageClear', this.onStageClear, this);
    this.gameScene.events.on('gameOver', this.onGameOver, this);
    this.gameScene.events.on('restart', this.onRestart, this);

    // Cleanup on shutdown
    this.events.on('shutdown', () => {
      this.gameScene.events.off('uiUpdate', this.onUIUpdate, this);
      this.gameScene.events.off('stageClear', this.onStageClear, this);
      this.gameScene.events.off('gameOver', this.onGameOver, this);
      this.gameScene.events.off('restart', this.onRestart, this);
    });
  }

  private onUIUpdate(data: UIData): void {
    // Hearts
    const heartStr = '\u2665'.repeat(Math.max(0, data.hearts));
    this.heartsText.setText(heartStr);

    // Knife count
    const kStr = data.knifeCount < 10 ? `0${data.knifeCount}` : String(data.knifeCount);
    this.knifeCountText.setText(`\ud83d\udde1\ufe0f${kStr}/99`);

    // Stars
    this.starsText.setText(`\ubaa9\ud45c: \u2b50 ${data.starsLeft}`);
  }

  private onStageClear(level: number): void {
    this.showOverlay(0x000000, 0.6);
    this.overlayTitle.setText('STAGE CLEAR!').setColor('#4ADE80').setVisible(true);
    this.overlayInfo.setText(`\ub2e4\uc74c \ub808\ubca8: ${level + 1}`).setVisible(true);
    this.overlaySubInfo.setVisible(false);

    this.time.delayedCall(1100, () => {
      this.hideOverlay();
    });
  }

  private onGameOver(): void {
    this.showOverlay(0x000000, 0.8);
    this.overlayTitle.setText('GAME OVER').setColor('#EF4444').setVisible(true);
    this.overlayInfo.setText('\ud130\uce58\ud558\uc5ec \ud604\uc7ac \ub808\ubca8 \uc7ac\uc2dc\uc791').setVisible(true);
    this.overlaySubInfo.setVisible(false);
  }

  private onRestart(): void {
    this.hideOverlay();
  }

  private showOverlay(color: number, alpha: number): void {
    this.overlay.clear();
    this.overlay.fillStyle(color, alpha);
    this.overlay.fillRect(0, 0, CANVAS_W, CANVAS_H);
    this.overlay.setVisible(true);
  }

  private hideOverlay(): void {
    this.overlay.setVisible(false);
    this.overlayTitle.setVisible(false);
    this.overlayInfo.setVisible(false);
    this.overlaySubInfo.setVisible(false);
  }
}
