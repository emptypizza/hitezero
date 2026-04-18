import Phaser from 'phaser';

const fragShader = `
precision mediump float;

uniform sampler2D uMainSampler;
uniform vec2 uResolution;
uniform float uIntensity;

varying vec2 outTexCoord;

void main() {
  vec2 uv = outTexCoord;
  vec2 pixelSize = vec2(1.0) / uResolution;
  vec4 color = texture2D(uMainSampler, uv);

  // Simple 5-tap bloom: sample neighbors and add bright parts
  vec4 bloom = vec4(0.0);
  float offsets[5];
  offsets[0] = -2.0;
  offsets[1] = -1.0;
  offsets[2] = 0.0;
  offsets[3] = 1.0;
  offsets[4] = 2.0;

  float weights[5];
  weights[0] = 0.06;
  weights[1] = 0.24;
  weights[2] = 0.40;
  weights[3] = 0.24;
  weights[4] = 0.06;

  for (int i = 0; i < 5; i++) {
    for (int j = 0; j < 5; j++) {
      vec2 offset = vec2(offsets[i], offsets[j]) * pixelSize * 2.0;
      vec4 sample = texture2D(uMainSampler, uv + offset);
      // Only bloom bright pixels
      float brightness = dot(sample.rgb, vec3(0.2126, 0.7152, 0.0722));
      float contribution = smoothstep(0.45, 0.9, brightness);
      bloom += sample * contribution * weights[i] * weights[j];
    }
  }

  gl_FragColor = color + bloom * uIntensity;
}
`;

export class GlowPostFX extends Phaser.Renderer.WebGL.Pipelines.PostFXPipeline {
  private _intensity = 0.6;

  constructor(game: Phaser.Types.Core.GameConfig | Phaser.Game) {
    super({
      game: game as Phaser.Game,
      name: 'GlowPostFX',
      fragShader,
    });
  }

  set intensity(value: number) {
    this._intensity = value;
  }

  onPreRender(): void {
    this.set2f('uResolution', this.renderer.width, this.renderer.height);
    this.set1f('uIntensity', this._intensity);
  }
}
