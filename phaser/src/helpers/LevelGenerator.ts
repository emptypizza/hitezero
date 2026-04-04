import { BLOCK_COLS, BLOCK_W, BLOCK_H } from '../constants';
import { BlockType } from '../types';
import type { GameScene } from '../scenes/GameScene';

export function initLevel(scene: GameScene, level: number): void {
  scene.blocks.clear(true, true);
  scene.movingBlocks.clear(true, true);
  scene.knives.clear(true, true);
  scene.pendingStars = 0;
  scene.knivesToShoot = 0;

  // Clear leftover labels
  scene.children.list
    .filter((c) => c.getData?.('isBlockLabel'))
    .forEach((c) => c.destroy());

  const rows = 3 + Math.floor(level / 2);
  for (let r = 0; r < rows; r++) {
    generateRow(scene, 60 + r * BLOCK_H, level, true);
  }

  const hasStars = scene.blocks.getChildren().some(
    (b) => (b as Phaser.GameObjects.Sprite).getData('blockType') === BlockType.STAR
  );
  if (!hasStars) {
    addBlock(scene, 3, 60, 1, 1, BlockType.STAR);
  }
}

function generateRow(
  scene: GameScene,
  yPos: number,
  level: number,
  isInit: boolean,
): void {
  for (let i = 0; i < BLOCK_COLS; i++) {
    if (Math.random() > 0.4) {
      let type: BlockType = BlockType.NORMAL;
      let hp = level;
      const rand = Math.random();

      if (rand < 0.1) {
        type = BlockType.POW;
        hp = 1;
      } else if (isInit && rand < 0.25) {
        type = BlockType.STAR;
        hp = 1;
      } else if (rand < 0.35) {
        type = BlockType.RED_ENEMY;
      }

      addBlock(scene, i, yPos, hp, hp, type);
    }
  }
}

function addBlock(
  scene: GameScene,
  col: number,
  yPos: number,
  hp: number,
  maxHp: number,
  type: BlockType,
): void {
  const bw = Math.floor(BLOCK_W - 4);
  const bh = Math.floor(BLOCK_H - 4);
  const x = col * BLOCK_W + 2 + bw / 2;
  const y = yPos + 2 + bh / 2;

  const isMoving = type === BlockType.RED_ENEMY;
  const group = isMoving ? scene.movingBlocks : scene.blocks;

  // Pick texture: dedicated webp sprites > atlas > fallback
  let textureKey: string;
  let atlasFrame: string | undefined;

  switch (type) {
    case BlockType.RED_ENEMY:
      textureKey = scene.textures.exists('block_enemy') ? 'block_enemy' : 'block_red_enemy';
      break;
    case BlockType.STAR:
      textureKey = scene.textures.exists('block_star') ? 'block_star' : 'block_star';
      break;
    case BlockType.POW:
      textureKey = scene.textures.exists('block_pow') ? 'block_pow' : 'block_pow';
      break;
    default:
      // NORMAL: use atlas if available
      if (scene.textures.exists('atlas')) {
        textureKey = 'atlas';
        atlasFrame = 'block_normal';
      } else {
        textureKey = 'block_normal';
      }
      break;
  }

  let block: Phaser.Physics.Arcade.Sprite;
  if (atlasFrame) {
    block = group.create(x, y, textureKey, atlasFrame) as Phaser.Physics.Arcade.Sprite;
  } else {
    block = group.create(x, y, textureKey) as Phaser.Physics.Arcade.Sprite;
  }
  block.setDisplaySize(bw, bh);

  block.setData('hp', hp);
  block.setData('maxHp', maxHp);
  block.setData('blockType', type);
  block.setImmovable(!isMoving);

  if (isMoving) {
    block.setVelocityY(30);
  }

  // Add HP text label for NORMAL and RED_ENEMY
  if (type === BlockType.NORMAL || type === BlockType.RED_ENEMY) {
    const label = scene.add.text(x, y, String(hp), {
      fontFamily: 'monospace',
      fontSize: '18px',
      fontStyle: 'bold',
      color: type === BlockType.RED_ENEMY ? '#ffffff' : '#000000',
      stroke: type === BlockType.RED_ENEMY ? '#000000' : undefined,
      strokeThickness: type === BlockType.RED_ENEMY ? 2 : 0,
    }).setOrigin(0.5).setDepth(3);
    label.setData('isBlockLabel', true);
    block.setData('label', label);
  }
}
