import Phaser from 'phaser';
import './style.css';
import { CANVAS_W, CANVAS_H } from './constants';
import { BootScene } from './scenes/BootScene';
import { TitleScene } from './scenes/TitleScene';
import { GameScene } from './scenes/GameScene';
import { UIScene } from './scenes/UIScene';
import { CRTPostFX } from './helpers/CRTPostFX';
import { GlowPostFX } from './helpers/GlowPostFX';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.WEBGL,
  parent: 'app',
  backgroundColor: '#ffffff',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: CANVAS_W,
    height: CANVAS_H,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: false,
    },
  },
  input: {
    activePointers: 2,
  },
  pipeline: {
    CRTPostFX,
    GlowPostFX,
  },
  scene: [BootScene, TitleScene, GameScene, UIScene],
};

new Phaser.Game(config);
