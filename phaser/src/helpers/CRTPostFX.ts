import Phaser from 'phaser';

const fragShader = `
precision mediump float;

uniform sampler2D uMainSampler;
uniform float uTime;
uniform vec2 uResolution;

varying vec2 outTexCoord;

void main() {
  vec2 uv = outTexCoord;
  vec4 color = texture2D(uMainSampler, uv);

  // --- Scanlines ---
  float scanline = sin(uv.y * uResolution.y * 1.5) * 0.04;
  color.rgb -= scanline;

  // --- Subtle vignette ---
  float dist = distance(uv, vec2(0.5, 0.5));
  color.rgb *= 1.0 - dist * 0.4;

  // --- Slight color aberration ---
  float shift = 0.001;
  float r = texture2D(uMainSampler, uv + vec2(shift, 0.0)).r;
  float b = texture2D(uMainSampler, uv - vec2(shift, 0.0)).b;
  color.r = mix(color.r, r, 0.3);
  color.b = mix(color.b, b, 0.3);

  gl_FragColor = color;
}
`;

export class CRTPostFX extends Phaser.Renderer.WebGL.Pipelines.PostFXPipeline {
  constructor(game: Phaser.Types.Core.GameConfig | Phaser.Game) {
    super({
      game: game as Phaser.Game,
      name: 'CRTPostFX',
      fragShader,
    });
  }

  onPreRender(): void {
    this.set1f('uTime', this.game.loop.time / 1000);
    this.set2f('uResolution', this.renderer.width, this.renderer.height);
  }
}
