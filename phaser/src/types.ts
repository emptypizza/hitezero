export const GameState = {
  AIMING: 0,
  SHOOTING: 1,
  STAGE_CLEAR: 2,
  GAME_OVER: 3,
} as const;
export type GameState = (typeof GameState)[keyof typeof GameState];

export const BlockType = {
  NORMAL: 'NORMAL',
  POW: 'POW',
  STAR: 'STAR',
  RED_ENEMY: 'RED_ENEMY',
} as const;
export type BlockType = (typeof BlockType)[keyof typeof BlockType];

export interface BlockConfig {
  col: number;
  row: number;
  hp: number;
  maxHp: number;
  type: BlockType;
}
