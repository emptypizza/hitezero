import Phaser from 'phaser';
import { CANVAS_W, CANVAS_H } from '../constants';

export class TitleScene extends Phaser.Scene {
  constructor() {
    super({ key: 'Title' });
  }

  create(): void {
    // Background gradient
    const bg = this.add.graphics();
    bg.fillGradientStyle(0x166534, 0x166534, 0x064e3b, 0x14532d);
    bg.fillRect(0, 0, CANVAS_W, CANVAS_H);

    // Vignette overlay
    const vignette = this.add.graphics();
    vignette.fillStyle(0x000000, 0.5);
    vignette.fillRect(0, 0, CANVAS_W, CANVAS_H);

    // Floating particles
    if (this.textures.exists('particle')) {
      const emitter = this.add.particles(0, 0, 'particle', {
        x: { min: 0, max: CANVAS_W },
        y: { min: 0, max: CANVAS_H },
        scale: { min: 0.3, max: 0.8 },
        alpha: { start: 0.4, end: 0 },
        lifespan: 3000,
        frequency: 200,
        tint: 0xfde68a,
        blendMode: 'ADD',
      });
      emitter.setDepth(1);
    }

    // Subtitle
    this.add.text(CANVAS_W / 2, 180, '\ucf69\ud37c\uc2a4\uc758', {
      fontFamily: 'sans-serif',
      fontSize: '24px',
      fontStyle: 'bold',
      color: '#fb923c',
      stroke: '#000000',
      strokeThickness: 3,
    }).setOrigin(0.5).setDepth(2);

    // Title
    const title = this.add.text(CANVAS_W / 2, 230, '\uc720\uc131\ub9c9\uae30', {
      fontFamily: 'sans-serif',
      fontSize: '56px',
      fontStyle: 'bold',
      color: '#ffffff',
      stroke: '#b45309',
      strokeThickness: 6,
    }).setOrigin(0.5).setDepth(2);

    // Title pulse
    this.tweens.add({
      targets: title,
      alpha: 0.7,
      duration: 1000,
      yoyo: true,
      repeat: -1,
    });

    // Tagline
    this.add.text(CANVAS_W / 2, 290, '\ud83c\udf20 \uc3df\uc544\uc9c0\ub294 \uc720\uc131\uc744 \ub9c9\uc544\ub0b4\uba70 \ucd5c\uace0 \uc810\uc218\uc5d0 \ub3c4\uc804\ud558\uc138\uc694!', {
      fontFamily: 'sans-serif',
      fontSize: '13px',
      color: '#d1fae5',
      backgroundColor: '#00000066',
      padding: { x: 12, y: 6 },
    }).setOrigin(0.5).setDepth(2);

    // Maid character on title screen — uses high-quality PNG
    if (this.textures.exists('maid_idle')) {
      const maidChar = this.add.image(CANVAS_W / 2, 360, 'maid_idle')
        .setDisplaySize(120, 120).setDepth(2);

      // Gentle float
      this.tweens.add({
        targets: maidChar, y: '+=8', duration: 1800,
        yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
      });

      // Breathing scale
      this.tweens.add({
        targets: maidChar, scaleY: maidChar.scaleY * 1.02,
        duration: 1400, yoyo: true, repeat: -1, ease: 'Sine.easeInOut',
      });
    }

    // Knife decorations
    if (this.textures.exists('knife')) {
      const leftKnife = this.add.image(50, 190, 'knife').setScale(3).setAngle(-30).setDepth(2);
      const rightKnife = this.add.image(CANVAS_W - 50, 180, 'knife').setScale(3).setAngle(30).setDepth(2);
      this.tweens.add({ targets: leftKnife, y: '+=10', duration: 2000, yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
      this.tweens.add({ targets: rightKnife, y: '+=10', duration: 1800, yoyo: true, repeat: -1, ease: 'Sine.easeInOut', delay: 400 });
    }

    // Play button
    const btnBg = this.add.graphics();
    btnBg.fillStyle(0x22c55e);
    btnBg.fillRoundedRect(CANVAS_W / 2 - 140, 400, 280, 70, 16);
    btnBg.lineStyle(4, 0x166534);
    btnBg.strokeRoundedRect(CANVAS_W / 2 - 140, 400, 280, 70, 16);
    btnBg.setDepth(2);

    const btnText = this.add.text(CANVAS_W / 2, 435, '\u25b6  \uac8c\uc784 \uc2dc\uc791', {
      fontFamily: 'sans-serif',
      fontSize: '26px',
      fontStyle: 'bold',
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 2,
    }).setOrigin(0.5).setDepth(3);

    const btnZone = this.add.zone(CANVAS_W / 2, 435, 280, 70).setInteractive({ useHandCursor: true }).setDepth(4);
    btnZone.on('pointerdown', () => {
      this.scene.start('Game');
    });

    // Hover effect
    btnZone.on('pointerover', () => btnText.setScale(1.05));
    btnZone.on('pointerout', () => btnText.setScale(1));

    // How to play button
    const howToPlay = this.add.text(CANVAS_W / 2, 510, '\u2139  \uc5b4\ub5bb\uac8c \ud50c\ub808\uc774\ud558\ub098\uc694?', {
      fontFamily: 'sans-serif',
      fontSize: '14px',
      color: '#cbd5e1',
      backgroundColor: '#00000033',
      padding: { x: 12, y: 6 },
    }).setOrigin(0.5).setDepth(2).setInteractive({ useHandCursor: true });

    // Modal container (hidden by default)
    const modal = this.add.container(0, 0).setDepth(10).setVisible(false);

    const modalBg = this.add.graphics();
    modalBg.fillStyle(0x000000, 0.8);
    modalBg.fillRect(0, 0, CANVAS_W, CANVAS_H);
    modal.add(modalBg);

    const panelBg = this.add.graphics();
    panelBg.fillStyle(0x1e293b);
    panelBg.fillRoundedRect(30, 200, CANVAS_W - 60, 300, 16);
    panelBg.lineStyle(2, 0x475569);
    panelBg.strokeRoundedRect(30, 200, CANVAS_W - 60, 300, 16);
    modal.add(panelBg);

    modal.add(this.add.text(CANVAS_W / 2, 225, '\ud50c\ub808\uc774 \ubc29\ubc95', {
      fontFamily: 'sans-serif', fontSize: '20px', fontStyle: 'bold', color: '#ffffff',
    }).setOrigin(0.5));

    const instructions = [
      ['\ud83d\udd2a', '\ud654\uba74\uc744 \uc88c\uc6b0\ub85c \ud130\uce58\ud558\uc5ec \uba54\uc774\ub4dc\ub97c \uc6c0\uc9c1\uc774\uc138\uc694.'],
      ['\u2b50', '\uc2a4\ud14c\uc774\uc9c0\uc758 \ubcc4 \ube14\ub85d\uc744 \ubaa8\ub450 \uc5c6\uc560\uba74 \ud074\ub9ac\uc5b4!'],
      ['\u2604\ufe0f', '\ube68\uac04 \uc545\ub2f9 \uc720\uc131\uc774 \ubc14\ub2e5\uc5d0 \ub2ff\uc73c\uba74 \ud558\ud2b8\uac00 \uae4e\uc785\ub2c8\ub2e4.'],
    ];

    instructions.forEach(([icon, text], i) => {
      modal.add(this.add.text(70, 265 + i * 50, icon!, { fontSize: '24px' }));
      modal.add(this.add.text(110, 265 + i * 50, text!, {
        fontFamily: 'sans-serif', fontSize: '13px', color: '#cbd5e1', wordWrap: { width: 220 },
      }));
    });

    const closeBtn = this.add.text(CANVAS_W / 2, 460, '\ud655\uc778', {
      fontFamily: 'sans-serif', fontSize: '18px', fontStyle: 'bold', color: '#ffffff',
      backgroundColor: '#334155', padding: { x: 40, y: 10 },
    }).setOrigin(0.5).setInteractive({ useHandCursor: true });
    closeBtn.on('pointerdown', () => modal.setVisible(false));
    modal.add(closeBtn);

    howToPlay.on('pointerdown', () => modal.setVisible(true));

    // Bottom info
    this.add.text(15, CANVAS_H - 45, 'DEV v0.1', {
      fontFamily: 'sans-serif', fontSize: '10px', fontStyle: 'bold', color: '#ffffff',
      backgroundColor: '#2563eb', padding: { x: 4, y: 2 },
    }).setDepth(2);

    this.add.text(15, CANVAS_H - 25, 'unknown373', {
      fontFamily: 'sans-serif', fontSize: '12px', color: '#94a3b8',
    }).setDepth(2);

    this.add.text(CANVAS_W - 15, CANVAS_H - 25, '\ucd5c\uace0 \uc810\uc218: 0', {
      fontFamily: 'sans-serif', fontSize: '12px', color: '#fde68a',
    }).setOrigin(1, 0.5).setDepth(2);

    // Controls hint
    this.add.text(CANVAS_W / 2, CANVAS_H - 60, 'WASD / Arrows \uc774\ub3d9  |  \ud130\uce58/\ub4dc\ub798\uadf8 \uc870\uc900', {
      fontFamily: 'sans-serif', fontSize: '11px', color: '#64748b',
    }).setOrigin(0.5).setDepth(2);
  }
}
