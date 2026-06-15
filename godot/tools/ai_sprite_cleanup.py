#!/usr/bin/env python3
"""
ai_sprite_cleanup.py — AI 2K 생성물 → 게임용 도트 스프라이트 변환 파이프라인.

Higgsfield(또는 임의 AI) 출력은 (1) 자체 배경이 그려져 있고 (2) 안티앨리어싱이
섞인 고해상이라 hitezero의 NEAREST 픽셀 블록과 충돌한다. 이 스크립트가:
  배경제거(선택) → 서브젝트 크롭 → 목표 높이로 다운스케일 → 팔레트 양자화(선택)
  → 알파 정리 → 바닥(발) 피벗 앵커 정렬 → 투명 PNG 저장.
까지 자동화해 repo 투입(assets/textures/player/maid/) 직전 상태로 만든다.

의존: pillow, numpy, (opencv-python: --remove-bg 사용 시).

예:
  python3 ai_sprite_cleanup.py cel_rim_A.png maid_clean.png --height 249 --remove-bg --colors 48
  python3 ai_sprite_cleanup.py raw.png out.png --height 249           # 알파 이미 있을 때

주의: --remove-bg의 grabcut은 단색/단순 배경에서 잘 되고, 복잡한 네온 배경은
완벽치 않다(증명용엔 충분). 프로덕션 매트가 필요하면 Higgsfield remove_background
또는 수동 정리 권장.
"""
import argparse, sys
import numpy as np
from PIL import Image


def remove_bg_grabcut(img_rgb, margin=(0.08, 0.04, 0.08, 0.03)):
    """opencv grabcut으로 중앙 서브젝트 추출 → alpha 반환(uint8)."""
    import cv2
    h, w = img_rgb.shape[:2]
    mx0, my0, mx1, my1 = margin
    rect = (int(w * mx0), int(h * my0),
            int(w * (1 - mx0 - mx1)), int(h * (1 - my0 - my1)))
    mask = np.zeros((h, w), np.uint8)
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    cv2.grabCut(cv2.cvtColor(img_rgb, cv2.COLOR_RGB2BGR), mask, rect,
                bgd, fgd, 5, cv2.GC_INIT_WITH_RECT)
    fg = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
    # 모폴로지 정리 + 큰 덩어리만 유지
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
    fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, k)
    fg = cv2.morphologyEx(fg, cv2.MORPH_CLOSE, k)
    n, lab, stats, _ = cv2.connectedComponentsWithStats(fg, 8)
    if n > 1:
        biggest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        fg = np.where(lab == biggest, 255, 0).astype(np.uint8)
    fg = cv2.GaussianBlur(fg, (3, 3), 0)  # 살짝 페더
    return fg


def crop_to_alpha(im):
    a = np.array(im.split()[-1])
    ys, xs = np.where(a > 8)
    if len(xs) == 0:
        return im
    return im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))


def quantize_keep_alpha(im, colors):
    a = im.split()[-1]
    rgb = im.convert("RGB").quantize(colors=colors, method=Image.MEDIANCUT).convert("RGB")
    out = rgb.convert("RGBA")
    out.putalpha(a)
    # 알파 임계화(반투명 가장자리 제거 → 도트 크리스프)
    na = np.array(out.split()[-1]); na = np.where(na > 110, 255, 0).astype(np.uint8)
    out.putalpha(Image.fromarray(na))
    return out


def main():
    ap = argparse.ArgumentParser(description="AI 2K → 게임 도트 스프라이트 정리")
    ap.add_argument("input"); ap.add_argument("output")
    ap.add_argument("--height", type=int, default=249, help="목표 높이(px). 기본 combat_idle=249")
    ap.add_argument("--remove-bg", action="store_true", help="grabcut 배경 제거")
    ap.add_argument("--colors", type=int, default=0, help=">0이면 팔레트 양자화 색 수")
    ap.add_argument("--canvas-w", type=int, default=0, help=">0이면 이 폭의 캔버스 중앙下단 정렬(피벗 고정)")
    args = ap.parse_args()

    im = Image.open(args.input).convert("RGBA")
    if args.remove_bg:
        try:
            alpha = remove_bg_grabcut(np.array(im.convert("RGB")))
            im.putalpha(Image.fromarray(alpha))
        except Exception as e:
            print(f"[warn] grabcut 실패({e}) → 기존 알파 사용", file=sys.stderr)

    im = crop_to_alpha(im)
    # 목표 높이로 다운스케일(LANCZOS) — 도트 느낌은 quantize+알파임계화로
    w = max(1, round(im.width * args.height / im.height))
    im = im.resize((w, args.height), Image.LANCZOS)
    if args.colors > 0:
        im = quantize_keep_alpha(im, args.colors)

    if args.canvas_w > 0:  # 발 피벗 = 캔버스 하단 중앙
        canvas = Image.new("RGBA", (args.canvas_w, args.height), (0, 0, 0, 0))
        canvas.alpha_composite(im, ((args.canvas_w - im.width) // 2, args.height - im.height))
        im = canvas

    im.save(args.output)
    print(f"saved {args.output} {im.size}")


if __name__ == "__main__":
    main()
