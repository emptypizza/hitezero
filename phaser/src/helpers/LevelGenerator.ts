import { BLOCK_COLS, BLOCK_W, BLOCK_H } from '../constants';
import { BlockType } from '../types';
import type { GameScene } from '../scenes/GameScene';

export function initLevel(scene: GameScene, level: number): void {
  scene.blocks.clear(true, true);
  scene.movingBlocks.clear(true, true);
  scene.knives.clear(true, true);
  scene.pendingStars = 0;
  scene.knivesToShoot = 0;

  const rows = 3 + Math.floor(level / 2);
  for (let r = 0; r < rows; r++) {
    generateRow(scene, 60 + r * BLOCK_H, level, true);
  }

  // Ensure at least one STAR exists
  const hasStars = scene.blocks.getChildren().some(
    (b) => (b as Phaser.GameObjects.Sprite).getData('blockType') === BlockType.STAR
  );
  if (!hasStars) {
    addBlock(scene, 3, 0, 60, 1, 1, BlockType.STAR);
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

      addBlock(scene, i, 0, yPos, hp, hp, type);
    }
  }
}

function addBlock(
  scene: GameScene,
  col: number,
  _row: number,
  yPos: number,
  hp: number,
  maxHp: number,
  type: BlockType,
): void {
  const bw = Math.floor(BLOCK_W - 4);
  const bh = Math.floor(BLOCK_H - 4);
  const x = col * BLOCK_W + 2 + bw / 2;
  const y = yPos + 2 + bh / 2;

  let textureKey: string;
  switch (type) {
    case BlockType.POW:
      textureKey = 'block_pow';
      break;
    case BlockType.STAR:
      textureKey = 'block_star';
      break;
    case BlockType.RED_ENEMY:
      textureKey = 'block_red_enemy';
      break;
    default:
      textureKey = 'block_normal';
  }

  const isMoving = type === BlockType.RED_ENEMY;
  const group = isMoving ? scene.movingBlocks : scene.blocks;

  const block = group.create(x, y, textureKey) as Phaser.Physics.Arcade.Sprite;
  block.setData('hp', hp);
  block.setData('maxHp', maxHp);
  block.setData('blockType', type);
  block.setImmovable(!isMoving);

  if (isMoving) {
    block.setVelocityY(30);
  }

  // Add text overlay for blocks that show HP or labels
  if (type === BlockType.NORMAL || type === BlockType.RED_ENEMY) {
    const label = scene.add.text(x, y, String(hp), {
      fontFamily: 'sans-serif',
      fontSize: '20px',
      fontStyle: 'bold',
      color: type === BlockType.RED_ENEMY ? '#ffffff' : '#000000',
    }).setOrigin(0.5);
    block.setData('label', label);
  } else if (type === BlockType.POW) {
    const label = scene.add.text(x, y, 'POW', {
      fontFamily: 'sans-serif',
      fontSize: '16px',
      fontStyle: 'bold',
      color: '#FBBF24',
    }).setOrigin(0.5);
    block.setData('label', label);
  } else if (type === BlockType.STAR) {
    const label = scene.add.text(x, y, '\u2605', {
      fontFamily: 'sans-serif',
      fontSize: '24px',
      color: '#FBBF24',
    }).setOrigin(0.5);
    block.setData('label', label);
  }
}
