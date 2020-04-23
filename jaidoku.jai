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

Cell :: struct {
    rect : SDL_Rect;
    selected : bool;
    x : u8;
    y : u8;
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
                case SDL_KEYDOWN;
                    k := event.key.keysym.sym;
                    if      k == SDLK_w || k == SDLK_UP    Select(cursor_x,   cursor_y-1);
                    else if k == SDLK_a || k == SDLK_LEFT  Select(cursor_x-1, cursor_y  );
                    else if k == SDLK_s || k == SDLK_DOWN  Select(cursor_x,   cursor_y+1);
                    else if k == SDLK_d || k == SDLK_RIGHT Select(cursor_x+1, cursor_y  );
                    else if k == SDLK_LSHIFT               multi_select = true;
            }
        }

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
        SDL_RenderClear(renderer);

        DrawEmptyGrid(renderer);

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

DrawEmptyGrid :: (renderer : *SDL_Renderer) {
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
    }

    rect : SDL_Rect;
    rect.x = padding-1;
    rect.y = padding-1;
    rect.w = full_size - padding*2 + 2;
    rect.h = full_size - padding*2 + 2;
    SDL_RenderDrawRect(renderer, *rect);
}