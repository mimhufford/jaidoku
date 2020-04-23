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
                case SDL_KEYUP;
                    k := event.key.keysym.sym;
                    if      k == SDLK_ESCAPE exit = true;
                    else if k == SDLK_LSHIFT multi_select = false;
                    else if k == SDLK_SPACE  centre_mode = false;
                case SDL_KEYDOWN;
                    k := event.key.keysym.sym;
                    if      k == SDLK_w || k == SDLK_UP    Select(cursor_x,   cursor_y-1);
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

Select :: (x: u8, y: u8) {
    if x < 1 || x > 9 || y < 1 || y > 9 return;

    if !multi_select for * cells  it.selected = false;
    cursor_x = x;
    cursor_y = y;
    cells[x*10+y].selected = true;
}

SetupCells :: () {
    for box_x: 0..2 {
        for box_y: 0..2 {
            for x: box_x*3..box_x*3+2 {
                for y: box_y*3..box_y*3+2 {
                    index := (x+1)*10+y+1;
                    cells[index].rect.x = xx(padding + box_x*between_box + x*cell_size);
                    cells[index].rect.y = xx(padding + box_y*between_box + y*cell_size);
                    cells[index].rect.w = cell_size+1;
                    cells[index].rect.h = cell_size+1;
                    cells[index].x = xx(x+1);
                    cells[index].y = xx(y+1);
                }
            }
        }
    }
}

DrawGrid :: (renderer : *SDL_Renderer) {
    for * cells {
        if it.selected {
            if it.x == cursor_x && it.y == cursor_y
                SDL_SetRenderDrawColor(renderer, 220, 180, 180, 255);
            else
                SDL_SetRenderDrawColor(renderer, 230, 200, 200, 255);
            SDL_RenderFillRect(renderer, *it.rect);
        }

        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderDrawRect(renderer, *it.rect);

        if it.num > 0 {
            // @TODO: draw actual numbers, just a rect for now
            rect := it.rect;
            rect.x += 2;
            rect.y += 2;
            rect.w -= 4;
            rect.h -= 4;
            SDL_RenderDrawRect(renderer, *rect);
        }
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