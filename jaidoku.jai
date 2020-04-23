#import "Basic";
#import "SDL";
#import "String";

padding      : u16 : 10;
cell_size    : u16 : 50;
between_box  : u16 : 1;
full_size    : u16 : cell_size*9 + between_box*2 + padding*2 + 1;
cells        : [100] Cell;
cursor_x     : u8;
cursor_y     : u8;
multi_select : bool;
centre_mode  : bool;
click_held   : bool;

Cell :: struct {
    rect     : SDL_Rect;
    selected : bool;
    x        : u8;
    y        : u8;
    num      : u8;
    centre   : [10] bool;
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

    renderer := SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

    SetupCells();
    Select(1, 1);

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
                    if mods & KMOD_LCTRL && k == SDLK_a    SelectAll();
                    else if k == SDLK_w || k == SDLK_UP    Select(cursor_x,   cursor_y-1);
                    else if k == SDLK_a || k == SDLK_LEFT  Select(cursor_x-1, cursor_y  );
                    else if k == SDLK_s || k == SDLK_DOWN  Select(cursor_x,   cursor_y+1);
                    else if k == SDLK_d || k == SDLK_RIGHT Select(cursor_x+1, cursor_y  );
                    else if k == SDLK_LSHIFT               multi_select = true;
                    else if k == SDLK_SPACE                centre_mode = true;
                    else if k == SDLK_1                    SetNumber(1);
                    else if k == SDLK_2                    SetNumber(2);
                    else if k == SDLK_3                    SetNumber(3);
                    else if k == SDLK_4                    SetNumber(4);
                    else if k == SDLK_5                    SetNumber(5);
                    else if k == SDLK_6                    SetNumber(6);
                    else if k == SDLK_7                    SetNumber(7);
                    else if k == SDLK_8                    SetNumber(8);
                    else if k == SDLK_9                    SetNumber(9);
                    else if k == SDLK_DELETE               SetNumber(0);
            }
        }

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        SDL_RenderClear(renderer);

        DrawGrid(renderer);

        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
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
    SDL_RenderDrawRect(renderer, *rect);
}

SetNumber :: (n : u8) {
    for * cells {
        if !it.selected  continue;
        if centre_mode  it.centre[n] = !it.centre[n];
        else            it.num = n;
    }
}

DrawCellDetails :: (renderer : *SDL_Renderer, cell : *Cell) {

    if cell.num == 0 return;

    rect := cell.rect;
    rect.x += 14;
    rect.y += 12;
    rect.w -= 28;
    rect.h -= 24;

    /* the following sets up a bunch of rects
       representing a 7-seg display type thing

        -----
        | | |
        -----
        | | |
        -----
    */

    thickness :: 5;

    top := rect;
    top.h = thickness;

    bottom := rect;
    bottom.y = bottom.y + bottom.h - thickness;
    bottom.h = thickness;

    left_top := rect;
    left_top.w = thickness;
    left_top.h = left_top.h/2;

    left_bot := rect;
    left_bot.w = thickness;
    left_bot.h = left_bot.h/2;
    left_bot.y += left_bot.h;

    right_top := rect;
    right_top.x = right_top.x + right_top.w - thickness;
    right_top.w = thickness;
    right_top.h = right_top.h/2;

    right_bot := rect;
    right_bot.x = right_bot.x + right_bot.w - thickness;
    right_bot.w = thickness;
    right_bot.h = right_bot.h/2;
    right_bot.y += right_bot.h;

    horizontal := rect;
    horizontal.y += horizontal.h/2 - thickness/2;
    horizontal.h = thickness;

    vertical := rect;
    vertical.x += vertical.w/2 - thickness/2;
    vertical.w = thickness;

    if cell.num == {
        case 1;
            SDL_RenderFillRect(renderer, *vertical);
        case 2;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *bottom);
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *right_top);
            SDL_RenderFillRect(renderer, *left_bot);
        case 3;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *bottom);
            SDL_RenderFillRect(renderer, *right_top);
            SDL_RenderFillRect(renderer, *right_bot);
        case 4;
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *left_top);
            SDL_RenderFillRect(renderer, *right_top);
            SDL_RenderFillRect(renderer, *right_bot);
        case 5;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *bottom);
            SDL_RenderFillRect(renderer, *right_bot);
            SDL_RenderFillRect(renderer, *left_top);
        case 6;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *bottom);
            SDL_RenderFillRect(renderer, *right_bot);
            SDL_RenderFillRect(renderer, *left_top);
            SDL_RenderFillRect(renderer, *left_bot);
        case 7;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *right_top);
            SDL_RenderFillRect(renderer, *right_bot);
        case 8;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *bottom);
            SDL_RenderFillRect(renderer, *right_top);
            SDL_RenderFillRect(renderer, *right_bot);
            SDL_RenderFillRect(renderer, *left_top);
            SDL_RenderFillRect(renderer, *left_bot);
        case 9;
            SDL_RenderFillRect(renderer, *top);
            SDL_RenderFillRect(renderer, *horizontal);
            SDL_RenderFillRect(renderer, *bottom);
            SDL_RenderFillRect(renderer, *right_top);
            SDL_RenderFillRect(renderer, *right_bot);
            SDL_RenderFillRect(renderer, *left_top);
    }
}