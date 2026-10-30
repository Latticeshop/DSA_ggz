#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将图片转换为 RA3LuaBridge 可用的 Lua 代码片段。

背景：
地图自定义图片（如 huohuo.webp）的插入方式是：
  1. 准备一张 webp 图片（嵌入按钮图标时建议正方形小图，如 126x126）
  2. 将图片文件 base64 编码
  3. 在 Lua 中用 exTextureCreateFromBase64(base64, "DXT5") 创建纹理
  4. 用 exPackedTextureImageCreate({...}) 创建可复用的图片 ID
  5. 把图片 ID 赋给按钮的 IconId（顶部按钮）或用于其它 UI 引用

用法示例：
  python img_to_lua.py input.png --size 126 --var-name g_MyIconId --output out.lua
  python img_to_lua.py input.webp --size 64 --embed-name my_rune

参数：
  input      输入图片路径（支持 png/webp/jpg/bmp 等 Pillow 可读格式）
  --size N   输出正方形边长（默认 126）；非正方形会自动居中裁剪为正方形
  --var-name 生成的全局图片 ID 变量名（默认 g_CustomImageId）
  --embed-name 生成的 base64 表变量名（默认自定义值，避免与已有变量冲突）
  --output   输出 Lua 文件路径（默认打印到 stdout）

依赖：
  pip install Pillow
"""
import argparse
import base64
import io
import os
import sys

def resize_to_square_webp(data: bytes, size: int) -> bytes:
    """读取图片数据，居中裁剪为正方形并缩放到 size，转成 webp 字节流。"""
    from PIL import Image
    img = Image.open(io.BytesIO(data))
    img = img.convert("RGBA")
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    img = img.resize((size, size), Image.LANCZOS)
    out = io.BytesIO()
    img.save(out, format="WEBP", quality=90)
    return out.getvalue()

def build_lua(var_name: str, embed_name: str, base64_str: str, size: int) -> str:
    """生成与 CenterTopBtnFunc.lua 中 huohuo 一致的 Lua 代码片段。"""
    # base64 每 76 字符换行，便于阅读（长字符串 [[ ]] 保留换行）
    lines = []
    for i in range(0, len(base64_str), 76):
        lines.append(base64_str[i:i+76])
    wrapped = "\n".join(lines)
    return f"""-- 自定义图片嵌入（由 analysis/img_to_lua.py 自动生成，尺寸 {size}x{size}）
local {embed_name} = {{
    size = {{{size}, {size}}},
    base64 = [[
{wrapped}
]]
}}
local _textureId = exTextureCreateFromBase64({embed_name}.base64, "DXT5")
{var_name} = exPackedTextureImageCreate({{
    Texture = _textureId,
    -- 贴图在纹理中的位置
    CoordsX = 0, CoordsY = 0,
    -- 贴图的尺寸
    DimensionsX = {embed_name}.size[1], DimensionsY = {embed_name}.size[2],
    -- 源纹理的尺寸
    TextureDimensionsX = {embed_name}.size[1], TextureDimensionsY = {embed_name}.size[2],
    -- 旋转角度
    Rotated = 0
}})
"""

def main():
    parser = argparse.ArgumentParser(description="Convert image to RA3LuaBridge embeddable Lua snippet")
    parser.add_argument("input", help="input image path (png/webp/jpg/bmp...)")
    parser.add_argument("--size", type=int, default=126, help="output square side in pixels (default 126)")
    parser.add_argument("--var-name", default="g_CustomImageId", help="global image id variable name")
    parser.add_argument("--embed-name", default=None, help="local base64 table variable name")
    parser.add_argument("--output", default=None, help="output lua file path (default print to stdout)")
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"error: input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    embed_name = args.embed_name or ("EmbeddedImage_" + os.path.splitext(os.path.basename(args.input))[0])

    with open(args.input, "rb") as f:
        raw = f.read()

    webp_bytes = resize_to_square_webp(raw, args.size)
    base64_str = base64.b64encode(webp_bytes).decode("ascii")

    lua = build_lua(args.var_name, embed_name, base64_str, args.size)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(lua)
        print(f"written: {args.output} ({len(lua)} chars, {len(webp_bytes)} bytes webp)")
    else:
        print(lua)

if __name__ == "__main__":
    main()
