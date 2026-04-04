import Phaser from 'phaser';
import { generateTextures } from '../helpers/TextureFactory';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'Boot' });
  }

  preload(): void {
    // Try loading maid sprites; fallback texture is generated regardless
    this.load.image('maid_idle', 'assets/maid_idle.png');
    this.load.image('maid_throw', 'assets/maid_throw.png');

    // Suppress errors if maid sprites don't exist
    this.load.on('loaderror', (file: Phaser.Loader.File) => {
      if (file.key === 'maid_idle' || file.key === 'maid_throw') {
        // Will use fallback
      }
    });
  }

  create(): void {
    generateTextures(this);
    this.scene.start('Title');
  }
}
