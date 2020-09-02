#import "Basic";
#import "SDL";
#import "String";

padding      : u16 : 20;
cell_size    : u16 : 66;
between_box  : u16 : 1;
full_size    : u16 : cell_size*9 + between_box*2 + padding*2 + 1;
cells        : [100] Cell;
cursor_x     : u8;
cursor_y     : u8;
multi_select : bool;
centre_mode  : bool;
click_held   : bool;
num_textures : [10] *SDL_Texture;
sml_textures : [10] *SDL_Texture;

Cell :: struct {
    rect     : SDL_Rect;
    selected : bool;
    x        : u8;
    y        : u8;
    num      : u8;
    centre   : [10] bool;
    given    : bool;
}

main :: () {
    SDL_Init(SDL_INIT_VIDEO);

    window := SDL_CreateWindow("Jaidoku",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        full_size, full_size,
        SDL_WINDOW_OPENGL);

    if window == null {
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    renderer := SDL_CreateRenderer(window, -1, 0);

    for 1..9 {
        num_textures[it] = LoadPNG(renderer, tprint("img/%.png", it));
        sml_textures[it] = LoadPNG(renderer, tprint("img/%s.png", it));
        SDL_SetTextureColorMod(sml_textures[it], 70, 70, 90);
    }

    SetupCells();
    Select(5, 5);
    SetGiven(11, 5);
    SetGiven(12, 3);
    SetGiven(15, 7);
    SetGiven(21, 6);
    SetGiven(24, 1);
    SetGiven(25, 9);
    SetGiven(26, 5);
    SetGiven(32, 9);
    SetGiven(33, 8);
    SetGiven(38, 6);
    SetGiven(41, 8);
    SetGiven(45, 6);
    SetGiven(49, 3);
    SetGiven(51, 4);
    SetGiven(54, 8);
    SetGiven(56, 3);
    SetGiven(59, 1);
    SetGiven(61, 7);
    SetGiven(65, 2);
    SetGiven(69, 6);
    SetGiven(72, 6);
    SetGiven(77, 2);
    SetGiven(78, 8);
    SetGiven(84, 4);
    SetGiven(85, 1);
    SetGiven(86, 9);
    SetGiven(89, 5);
    SetGiven(95, 8);
    SetGiven(98, 7);
    SetGiven(99, 9);

    exit := false;
    while !exit {
        event : SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_QUIT;
                    exit = true;
                case SDL_MOUSEBUTTONDOWN;
                    if event.button.button == SDL_BUTTON_LEFT {
                        click_held = true;
                        SelectMouse(event.button.x, event.button.y);
                    }
                    if event.button.button == SDL_BUTTON_RIGHT {
                        HighlightSame(event.button.x, event.button.y);
                    }
                case SDL_MOUSEBUTTONUP;
                    if event.button.button == SDL_BUTTON_LEFT  click_held = false;
                case SDL_MOUSEMOTION;
                    if click_held  SelectMouse(event.button.x, event.button.y);
                case SDL_KEYUP;
                    k := event.key.keysym.sym;
                    if      k == SDLK_ESCAPE exit = true;
                    else if k == SDLK_LSHIFT multi_select = false;
                    else if k == SDLK_SPACE  centre_mode = false;
                case SDL_KEYDOWN;
                    k := event.key.keysym.sym;
                    mods := SDL_GetModState();
                    if mods & KMOD_LCTRL && k == SDLK_a              SelectAll();
                    else if k == SDLK_w || k == SDLK_UP              Select(cursor_x,   cursor_y-1);
                    else if k == SDLK_a || k == SDLK_LEFT            Select(cursor_x-1, cursor_y  );
                    else if k == SDLK_s || k == SDLK_DOWN            Select(cursor_x,   cursor_y+1);
                    else if k == SDLK_d || k == SDLK_RIGHT           Select(cursor_x+1, cursor_y  );
                    else if k == SDLK_LSHIFT                         multi_select = true;
                    else if k == SDLK_SPACE                          centre_mode = true;
                    else if k == SDLK_1 || k == SDLK_KP_1            SetNumber(1);
                    else if k == SDLK_2 || k == SDLK_KP_2            SetNumber(2);
                    else if k == SDLK_3 || k == SDLK_KP_3            SetNumber(3);
                    else if k == SDLK_4 || k == SDLK_KP_4            SetNumber(4);
                    else if k == SDLK_5 || k == SDLK_KP_5            SetNumber(5);
                    else if k == SDLK_6 || k == SDLK_KP_6            SetNumber(6);
                    else if k == SDLK_7 || k == SDLK_KP_7            SetNumber(7);
                    else if k == SDLK_8 || k == SDLK_KP_8            SetNumber(8);
                    else if k == SDLK_9 || k == SDLK_KP_9            SetNumber(9);
                    else if k == SDLK_DELETE || k == SDLK_BACKSPACE  Clear();
                    else if k == SDLK_RETURN                         Check();
            }
        }

        SDL_SetRenderDrawColor(renderer, 247, 247, 250, 255);
        SDL_RenderClear(renderer);

        DrawGrid(renderer);

        SDL_RenderPresent(renderer);
    }

    for num_textures SDL_DestroyTexture(it);
    for sml_textures SDL_DestroyTexture(it);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}

LoadPNG :: (renderer: *SDL_Renderer, path: string) -> *SDL_Texture {
    #import "stb_image";
    w, h, c : s32;
    data := stbi_load(path.data, *w, *h, *c, 4);
    surf := SDL_CreateRGBSurfaceWithFormatFrom(data, w, h, 32, 4*w, 376840196);
    text := SDL_CreateTextureFromSurface(renderer, surf);
    SDL_FreeSurface(surf);
    stbi_image_free(data);
    return text;
}

LoadBMP :: (renderer: *SDL_Renderer, path: string) -> *SDL_Texture {
    surf := SDL_LoadBMP(path.data);
    text := SDL_CreateTextureFromSurface(renderer, surf);
    SDL_SetTextureBlendMode(text, SDL_BLENDMODE_MOD);
    SDL_FreeSurface(surf);
    return text;
}

SelectAll :: () {
    all_selected := true;

    for * cells {
        if it.x == 0 || it.y == 0 continue;
        if !it.selected {
            all_selected = false;
            break;
        }
    }

    for * cells  it.selected = !all_selected;

    cells[cursor_y*10 + cursor_x].selected = true;
}

HighlightSame :: (x: int, y: int) {
    num := 0;

    for * cells {
        if x <= it.rect.x            continue;
        if x > it.rect.x + it.rect.w continue;
        if y <= it.rect.y            continue;
        if y > it.rect.y + it.rect.h continue;

        cursor_x = it.x;
        cursor_y = it.y;
        num = it.num;
    }

    for * cells {
             if num == 0      it.selected = false;
        else if num == it.num it.selected = true;
        else                  it.selected = false;
    }
}

SelectMouse :: (x: int, y: int) {
    for * cells {
        if x <= it.rect.x            continue;
        if x > it.rect.x + it.rect.w continue;
        if y <= it.rect.y            continue;
        if y > it.rect.y + it.rect.h continue;

        if !multi_select for * cells it.selected = false;

        cursor_x = it.x;
        cursor_y = it.y;
        it.selected = true;
    }
}

Select :: (x: u8, y: u8) {
    if x < 1 || x > 9 || y < 1 || y > 9 return;

    if !multi_select for * cells  it.selected = false;
    cursor_x = x;
    cursor_y = y;
    cells[y*10+x].selected = true;
}

SetupCells :: () {
    for box_x: 0..2 {
        for box_y: 0..2 {
            for _x: box_x*3..box_x*3+2 {
                for _y: box_y*3..box_y*3+2 {
                    using cells[(_y+1)*10+_x+1];
                    rect.x = xx(padding + box_x*between_box + _x*cell_size);
                    rect.y = xx(padding + box_y*between_box + _y*cell_size);
                    rect.w = cell_size+1;
                    rect.h = cell_size+1;
                    x = xx(_x+1);
                    y = xx(_y+1);
                }
            }
        }
    }
}

DrawGrid :: (renderer : *SDL_Renderer) {
    for * cells {
        if it.x == 0 || it.y == 0 continue;

        if it.selected {
            if it.x == cursor_x && it.y == cursor_y
                SDL_SetRenderDrawColor(renderer, 220, 180, 180, 255);
            else
                SDL_SetRenderDrawColor(renderer, 230, 200, 200, 255);
            SDL_RenderFillRect(renderer, *it.rect);
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderDrawRect(renderer, *it.rect);

        DrawCellDetails(renderer, it);
    }

    rect : SDL_Rect;
    rect.x = padding-1;
    rect.y = padding-1;
    rect.w = full_size - padding*2 + 2;
    rect.h = full_size - padding*2 + 2;
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderDrawRect(renderer, *rect);
}

SetNumber :: (n : u8) {
    all_have_centre_num := true;
    for * c: cells {
        if c.selected && !c.given && !c.num && !c.centre[n] {
            all_have_centre_num = false; break; 
        }
    }

    for * cells {
        if !it.selected  continue;
        if it.given      continue;

        if centre_mode {
            if it.num    continue;
            it.centre[n] = !all_have_centre_num;
        } else {
            it.num = n;
        }
    }
}

Clear :: () {
    for * cells {
        if !it.selected  continue;
        if it.given      continue;

        if it.num {
            it.num = 0;
        } else {
            for * c: it.centre {
                <<c = false;;
            }
        }
    }
}

Check :: () {

    for row : 1..9 for col : 1..9 if !cells[row*10 + col].num return;

    CheckRows :: () -> bool {
        for row : 1..9 {
            found : [10] bool;
            for col : 1..9 {
                index := row*10 + col;
                num := cells[index].num;
                if found[num] return false;
                found[num] = true;
            }
        }

        return true;
    }

    CheckCols :: () -> bool {
        for col : 1..9 {
            found : [10] bool;
            for row : 1..9 {
                index := row*10 + col;
                num := cells[index].num;
                if found[num] return false;
                found[num] = true;
            }
        }

        return true;
    }

    CheckBoxes :: () -> bool {
        for box_row : 0..2 {
            for box_col : 0..2 {
                for row : box_row*3+1..box_row*3+3 {
                    found : [10] bool;
                    for col : box_col*3+1..box_col*3+3 {
                        index := row*10 + col;
                        print("%\n", index);
                        num := cells[index].num;
                        if found[num] return false;
                        found[num] = true;
                    }
                }
            }
        }

        return true;
    }

    if CheckCols() && CheckRows() && CheckBoxes() {
        SDL_ShowSimpleMessageBox(0, "Congratulations", "Looks good!", null);
    } else {
        SDL_ShowSimpleMessageBox(0, "Nope", "Something isn't right!", null);
    }
}

SetGiven :: (cell : u8, n : u8) {
    cells[cell].num = n;
    cells[cell].given = true;
}

DrawCellDetails :: (renderer : *SDL_Renderer, cell : *Cell) {
    if cell.given {
        SDL_SetTextureColorMod(num_textures[cell.num], 0, 0, 0);
    } else if cell.num {
        SDL_SetTextureColorMod(num_textures[cell.num], 70, 70, 90);
    }

    if cell.num {
        // draw main number
        SDL_RenderCopy(renderer, num_textures[cell.num], null, *cell.rect);
    } else {
        // draw centre number(s)
        count := 0; for cell.centre if it count += 1;
        if !count return;

        rows  := 0; if count rows = (count-1) / 3;

        dst := cell.rect;
        dst.w = 16;
        dst.h = 19;
        dst.y += 3;
        dst.y += xx ((2-rows)*0.5*dst.h);
        index := 1;

        for row: 0..rows {
            cols := count - row*3;
            cols = min(cols, 3);
            dst.x = cell.rect.x + 10;
            dst.x += xx ((3-cols)*0.5*dst.w);

            while cols {
                if cell.centre[index] {
                    width : s32;
                    SDL_RenderCopy(renderer, sml_textures[index], null, *dst);
                    dst.x += dst.w;
                    cols  -= 1;
                }
                index += 1;
            }

            dst.y += 21;
        }
    }
}