package nucoib

import "core:fmt"
import rl "vendor:raylib"

Context :: struct {
    font: rl.Font,
    font_size: f32,

    windows: map[string]Window,
    window_row: int,
    active_window: ^Window,

    windows_stack: [256]Window_Commands,
    windows_stack_count: int,
    windows_text_stack: [256]string,
    windows_text_stack_count: int,
    windows_text_stack_last: int,

    window_default_pos: rl.Vector2,
    window_default_layer: int,

    mouse_offset: rl.Vector2,
}

Window :: struct {
    title: string,
    pos: rl.Vector2,
    size: rl.Vector2,
    layer: int,
}

Window_Commands :: struct {
    window: ^Window,
    commands: []string,
}

@(private="file") ctx: Context

ui_init :: proc() {
    ctx.font = rl.LoadFontEx("./Menlo-Regular.ttf", 96, nil, 0)
    rl.GenTextureMipmaps(&ctx.font.texture)
    rl.SetTextureFilter(ctx.font.texture, .BILINEAR)

    ctx.windows = make(map[string]Window)

    ctx.font_size = f32(22)
}

ui_finish :: proc() {
     rl.UnloadFont(ctx.font)
     delete(ctx.windows)
}

ui_text :: proc(pos: rl.Vector2, text: string) {
    rl.DrawTextEx(ctx.font, fmt.ctprint(text), pos, ctx.font_size, 0, rl.WHITE)
}

ui_measure_text :: proc(text: string) -> rl.Vector2 {
    return rl.MeasureTextEx(ctx.font, fmt.ctprint(text), ctx.font_size, 0)
}

ui_new_rect :: proc(pos, size: rl.Vector2) -> rl.Rectangle {
    return {pos.x, pos.y, size.x, size.y}
}

ui_window_begin :: proc(title: string) {
    window, ok := &ctx.windows[title]
    if !ok {
        ctx.windows[title] = {}
        window = &ctx.windows[title]
        window.title = title

        window.pos = ctx.window_default_pos
        ctx.window_default_pos += 10

        window.size = {300, 200}

        window.layer = ctx.window_default_layer
        ctx.window_default_layer += 1
    }
    assert(ctx.windows_stack_count < len(ctx.windows_stack))
    ctx.windows_stack[ctx.windows_stack_count].window = window
    ctx.windows_stack_count += 1
    ctx.windows_text_stack_last = ctx.windows_text_stack_count
}

ui_window_end :: proc() {
    ctx.windows_stack[ctx.windows_stack_count - 1].commands = ctx.windows_text_stack[ctx.windows_text_stack_last:ctx.windows_text_stack_count]
}

ui_window_text :: proc(text: string) {
    assert(ctx.windows_text_stack_count < len(ctx.windows_text_stack))
    ctx.windows_text_stack[ctx.windows_text_stack_count] = text
    ctx.windows_text_stack_count += 1
}

ui_render :: proc() {
    // Bubble sort cringe
    for i in 0..<ctx.windows_stack_count - 1 {
        for j in 0..<ctx.windows_stack_count - 1 {
            if ctx.windows_stack[j].window.layer > ctx.windows_stack[j + 1].window.layer {
                ctx.windows_stack[j], ctx.windows_stack[j + 1] = ctx.windows_stack[j + 1], ctx.windows_stack[j]
            }
        }
    }

    for i in 0..<ctx.windows_stack_count {
        if ctx.windows_stack[i].window == ctx.active_window {
            active := ctx.windows_stack[i]
            for j in (i + 1)..<ctx.windows_stack_count {
                ctx.windows_stack[j - 1] = ctx.windows_stack[j]
                ctx.windows_stack[j - 1].window.layer -= 1
            }
            ctx.windows_stack[ctx.windows_stack_count - 1] = active
            ctx.windows_stack[ctx.windows_stack_count - 1].window.layer = ctx.window_default_layer - 1
            break
        }
    }

    window_background := rl.GetColor(0x303030FF)
    header_color := rl.GetColor(0x2050AAFF)
    window_safe_zone := f32(25)
    font_spacing := f32(0)
    text_idx := 0

    for i := ctx.windows_stack_count - 1; i >= 0; i -= 1 {
        window := ctx.windows_stack[i].window

        mouse_pos := rl.GetMousePosition()
        if ctx.active_window == nil && rl.CheckCollisionPointRec(mouse_pos, ui_new_rect(window.pos, window.size)) {
            if rl.IsMouseButtonPressed(.LEFT) {
                ctx.mouse_offset = window.pos - mouse_pos
                ctx.active_window = window
            }
        }

        if rl.IsMouseButtonReleased(.LEFT) {
            ctx.active_window = nil
        }

        if ctx.active_window == window {
            window.pos = ctx.mouse_offset + mouse_pos

            screen_width := cast(f32)rl.GetScreenWidth()
            screen_height := cast(f32)rl.GetScreenHeight()

            if window.pos.x + window.size.x < window_safe_zone {
                window.pos.x = window_safe_zone - window.size.x
            }
            if window.pos.x > screen_width - window_safe_zone {
                window.pos.x = screen_width - window_safe_zone
            }
            if window.pos.y + window.size.y < window_safe_zone {
                window.pos.y = window_safe_zone - window.size.y
            }
            if window.pos.y > screen_height - window_safe_zone {
                window.pos.y = screen_height - window_safe_zone
            }
        }
    }

    for window_commands in ctx.windows_stack[:ctx.windows_stack_count] {
        window := window_commands.window

        rl.DrawRectangleV(window.pos - 1, window.size + 2, rl.GetColor(0x505050FF))
        rl.DrawRectangleV(window.pos, window.size, window_background)
        title := fmt.ctprint(window.title)
        header_size := rl.Vector2{
            window.size.x,
            rl.MeasureTextEx(ctx.font, title, ctx.font_size, font_spacing).y,
        }
        rl.DrawRectangleV(window.pos, header_size, header_color)
        rl.DrawTextEx(ctx.font, title, window.pos + {5, 0}, ctx.font_size, font_spacing, rl.WHITE)

        for i := 0; i < len(window_commands.commands); i += 1 {
            text := fmt.ctprint(window_commands.commands[i])
            text_pos := rl.Vector2{
                2,
                rl.MeasureTextEx(ctx.font, text, ctx.font_size, 0).y * f32(i + 1),
            }
            rl.BeginScissorMode(
                i32(window.pos.x),
                i32(window.pos.y),
                i32(window.size.x),
                i32(window.size.y),
            )
            rl.DrawTextEx(ctx.font, text, text_pos + window.pos, ctx.font_size, 0, rl.WHITE)
            rl.EndScissorMode()
        }
    }

    ctx.windows_stack_count = 0
    ctx.windows_text_stack_count = 0
}