---
name: venice-image
description: Generate images using Venice.ai API. Use this skill when the user asks for image generation, selfies, pictures, photos, or visual content creation.
homepage: https://docs.venice.ai
metadata:
  {
    "openclaw":
      { "emoji": "🎨", "requires": { "bins": ["curl", "jq"], "env": ["VENICE_API_KEY"] } },
  }
---

# Venice Image Generation

Generate images using Venice.ai's API.

## Quick Reference

- **Output folder:** `/Users/kamronahmed/Documents/code/openclaw/images/generated/`
- **Models:** `lustify-v7` (high quality, default), `lustify-sdxl` (fast), `venice-sd35` (SD 3.5), `hidream` (creative)
- **Quality settings:** Script now defaults to PNG format, 1024x1280 (vertical), cfg_scale=12.0 for sharp, high-quality images

## How to Generate Images

Use the helper script with `yieldMs: 60000` to avoid polling:

```bash
~/.openclaw/skills/venice-image/scripts/generate.sh OUTPUT_PATH PROMPT [MODEL] [WIDTH] [HEIGHT]
```

**Parameters:**

- `OUTPUT_PATH`: Full path to save the image
- `PROMPT`: Your image description
- `MODEL`: (optional) Default: `lustify-v7`. Available: `lustify-sdxl`, `venice-sd35`, `hidream`
- `WIDTH`: (optional) Default: 1024. Max: 1280
- `HEIGHT`: (optional) Default: 1280 (vertical format). Max: 1280

**IMPORTANT:** Always set `yieldMs: 60000` (60 seconds) - this prevents the command from backgrounding and avoids repeated polling. Image generation typically takes 20-30 seconds.

**Quality improvements applied automatically:**

- PNG format (higher quality than webp)
- cfg_scale: 12.0 (strong prompt adherence for sharp details)
- Watermark removal

## Filename Convention

Use descriptive, timestamped filenames:

- `lovotty_selfie_$(date +%s).png`
- `sunset_beach_1234567890.png`
- `product_shot_coffee_1234567890.png`

## Example Usage

Generate a vertical portrait (default 1024x1280):

```json
{
  "tool": "exec",
  "command": "~/.openclaw/skills/venice-image/scripts/generate.sh '/Users/kamronahmed/Documents/code/openclaw/images/generated/lovotty_selfie_'$(date +%s)'.png' 'beautiful woman with raven black hair taking a mirror selfie, wearing casual clothes, photorealistic, natural lighting' lustify-v7",
  "yieldMs": 60000
}
```

Generate square format (1024x1024):

```json
{
  "tool": "exec",
  "command": "~/.openclaw/skills/venice-image/scripts/generate.sh '/Users/kamronahmed/Documents/code/openclaw/images/generated/lovotty_portrait_'$(date +%s)'.png' 'beautiful woman with raven black hair and blue eyes, wearing a deep plunge cocktail dress, photorealistic, professional photography' lustify-v7 1024 1024",
  "yieldMs": 60000
}
```

Generate landscape format (1280x1024):

```json
{
  "tool": "exec",
  "command": "~/.openclaw/skills/venice-image/scripts/generate.sh '/Users/kamronahmed/Documents/code/openclaw/images/generated/beach_scene_'$(date +%s)'.png' 'sunset over ocean, dramatic clouds, photorealistic, golden hour lighting' lustify-v7 1280 1024",
  "yieldMs": 60000
}
```

## Prompt Tips

For best results, include:

- **Subject:** What/who is in the image
- **Style:** "photorealistic", "digital art", "watercolor", "3D render"
- **Lighting:** "soft lighting", "dramatic shadows", "golden hour", "studio lighting"
- **Quality:** "4k", "highly detailed", "professional photography"

## After Generation

Once the image is generated, include the file path in your response so it can be sent to the user. The gateway will automatically attach local image files.

## Troubleshooting

If generation fails, the script will output an error message. Common issues:

- **HTTP 404**: Model ID is invalid/deprecated. Use one of: `lustify-v7`, `lustify-sdxl`, `venice-sd35`, `hidream`
- **API key not set or invalid**: Check `VENICE_API_KEY` in `~/.openclaw/.env`
- **Rate limiting**: Wait and retry
- **Invalid prompt**: Too long or blocked content
- **No image data**: Venice API returns images in `.images[]` array (the script handles both `.images[]` and `.data[].b64_json` formats)
