import Phaser from 'phaser';
import { generateTextures } from '../helpers/TextureFactory';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'Boot' });
  }

  preload(): void {
    // Main sprite atlas with all game assets
    this.load.atlas('atlas', 'assets/atlas.jpg', 'assets/atlas.json');

    // Background
    this.load.image('bg', 'assets/bg.png');

    // Block sprites
    this.load.image('block_enemy', 'assets/E1.webp');
    this.load.image('block_star', 'assets/S1.webp');
    this.load.image('block_pow', 'assets/P1.webp');

    // High-quality maid PNGs (transparent)
    this.load.image('maid_idle', 'assets/maid_idle.png');
    this.load.image('maid_throw', 'assets/maid_throw.png');

    // Chibi atlas for overlays
    this.load.atlas('maid_chibi', 'assets/PM39X.jpg', 'assets/maid_atlas.json');
  }

  create(): void {
    // Only generate textures that aren't in the atlas as fallback
    generateTextures(this);

    // Maid animations from big atlas frames
    if (this.textures.exists('atlas')) {
      this.anims.create({
        key: 'maid_atlas_idle',
        frames: [
          { key: 'atlas', frame: 'maid_big_1' },
          { key: 'atlas', frame: 'maid_big_2' },
        ],
        frameRate: 2,
        repeat: -1,
        yoyo: true,
      });

      this.anims.create({
        key: 'maid_atlas_throw',
        frames: [
          { key: 'atlas', frame: 'maid_big_3' },
          { key: 'atlas', frame: 'maid_big_4' },
        ],
        frameRate: 6,
        repeat: -1,
      });

      // Star block shimmer animation
      this.anims.create({
        key: 'star_shimmer',
        frames: [
          { key: 'atlas', frame: 'block_star_dim' },
          { key: 'atlas', frame: 'block_star_bright' },
          { key: 'atlas', frame: 'block_star_glow' },
          { key: 'atlas', frame: 'block_star_bright' },
        ],
        frameRate: 4,
        repeat: -1,
      });

      // POW block pulse animation
      this.anims.create({
        key: 'pow_pulse',
        frames: [
          { key: 'atlas', frame: 'block_pow_dark' },
          { key: 'atlas', frame: 'block_pow_lit' },
        ],
        frameRate: 3,
        repeat: -1,
      });

      // Red enemy angry animation
      this.anims.create({
        key: 'red_enemy_angry',
        frames: [
          { key: 'atlas', frame: 'block_red_enemy' },
          { key: 'atlas', frame: 'block_red_enemy_alt' },
        ],
        frameRate: 3,
        repeat: -1,
      });
    }

    // Chibi animations
    if (this.textures.exists('maid_chibi')) {
      this.anims.create({
        key: 'chibi_anim_clear',
        frames: [
          { key: 'maid_chibi', frame: 'chibi_1' },
          { key: 'maid_chibi', frame: 'chibi_2' },
        ],
        frameRate: 4,
        repeat: -1,
        yoyo: true,
      });

      this.anims.create({
        key: 'chibi_anim_gameover',
        frames: [{ key: 'maid_chibi', frame: 'chibi_5' }],
        frameRate: 1,
        repeat: 0,
      });
    }

    this.scene.start('Title');
  }
}
