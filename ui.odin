package nucoib

import "core:fmt"
import rl "vendor:raylib"

Context :: struct {
    font: rl.Font,
    font_size: f32,
    font_padding: f32,

    window_background: rl.Color,
    window_pos: rl.Vector2,
    window_size: rl.Vector2,
    window_row: int,

    button_color: rl.Color,
    button_hover_color: rl.Color,
    button_active_color: rl.Color,
}

@(private="file") ctx: Context

ui_init :: proc() {
    ctx.font_size = f32(22)
    ctx.font_padding = f32(0)

    ctx.font = rl.LoadFontEx("./Menlo-Regular.ttf", i32(ctx.font_size), nil, i32(ctx.font_padding))
    rl.GenTextureMipmaps(&ctx.font.texture)
    rl.SetTextureFilter(ctx.font.texture, .BILINEAR)

    ctx.window_background = rl.GetColor(0x404040EE)
    ctx.button_color = rl.GetColor(0x404040FF)
    ctx.button_hover_color = rl.GetColor(0x606060FF)
    ctx.button_active_color = rl.GetColor(0x608060FF)
}

ui_finish :: proc() {
     rl.UnloadFont(ctx.font)
}

ui_text :: proc(pos: rl.Vector2, text: string) {
    rl.DrawTextEx(ctx.font, fmt.ctprint(text), pos, ctx.font_size, ctx.font_padding, rl.WHITE)
}

ui_measure_text :: proc(text: string) -> rl.Vector2 {
    return rl.MeasureTextEx(ctx.font, fmt.ctprint(text), ctx.font_size, ctx.font_padding)
}

ui_new_rect :: proc(pos, size: rl.Vector2) -> rl.Rectangle {
    return {pos.x, pos.y, size.x, size.y}
}

ui_window_begin :: proc(pos, size: rl.Vector2) {
    ctx.window_pos = pos
    ctx.window_size = size
    rl.DrawRectangleV(pos, size, ctx.window_background)
}

ui_window_end :: proc() {
    ctx.window_row = 0
}

ui_window_text :: proc(text: string) {
    text := fmt.ctprint(text)
    pos := rl.Vector2 {
        ctx.window_pos.x,
        ctx.window_pos.y + f32(ctx.window_row) * rl.MeasureTextEx(ctx.font, text, ctx.font_size, ctx.font_padding).y
    }

    rl.BeginScissorMode(i32(ctx.window_pos.x), i32(ctx.window_pos.y), i32(ctx.window_size.x), i32(ctx.window_size.y))
    rl.DrawTextEx(ctx.font, text, pos, ctx.font_size, ctx.font_padding, rl.WHITE)
    rl.EndScissorMode()

    ctx.window_row += 1
}

ui_window_button :: proc(text: string) -> bool {
    text := fmt.ctprint(text)
    text_size := rl.MeasureTextEx(ctx.font, text, ctx.font_size, ctx.font_padding)
    pos := rl.Vector2 {
        ctx.window_pos.x,
        ctx.window_pos.y + f32(ctx.window_row) * text_size.y
    }
    size := rl.Vector2 {
        ctx.window_size.x,
        text_size.y,
    }

    hover := rl.CheckCollisionPointRec(rl.GetMousePosition(), ui_new_rect(pos, size))

    rl.BeginScissorMode(i32(ctx.window_pos.x), i32(ctx.window_pos.y), i32(ctx.window_size.x), i32(ctx.window_size.y))
    if hover {
        if rl.IsMouseButtonDown(.LEFT) {
            rl.DrawRectangleV(pos, size, ctx.button_active_color)
        } else {
            rl.DrawRectangleV(pos, size, ctx.button_hover_color)
        }
    } else {
        rl.DrawRectangleV(pos, size, ctx.button_color)
    }
    rl.DrawTextEx(ctx.font, text, pos, ctx.font_size, ctx.font_padding, rl.WHITE)
    rl.EndScissorMode()

    ctx.window_row += 1

    return hover && rl.IsMouseButtonReleased(.LEFT)
}