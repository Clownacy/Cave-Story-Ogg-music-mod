MOD_LOADER_VERSION = v1.4
COMMON_PATH = src/common

OGG_MUSIC_USE_SNDFILE = false
# Can be 'mini_al', 'SDL2', or 'Cubeb'
OGG_MUSIC_BACKEND = mini_al

CC = gcc
CFLAGS = -O3 -s -static -Wall -Wextra -std=c11 -fomit-frame-pointer -fno-ident
ALL_CFLAGS = $(CFLAGS) -I$(COMMON_PATH) -D'MOD_LOADER_VERSION="$(MOD_LOADER_VERSION)"'

SDL_CFLAGS = $(shell sdl2-config --cflags)
SDL_LDFLAGS = $(shell sdl2-config --static-libs)

MOD_LOADER_HELPER_OBJECT = bin/mod_loader_helper.o

MOD_LOADER_PATH = src/mod_loader
MOD_LOADER_SOURCES = \
	$(COMMON_PATH)/sprintfMalloc.c \
	$(MOD_LOADER_PATH)/fix_door_bug.c \
	$(MOD_LOADER_PATH)/log.c \
	$(MOD_LOADER_PATH)/main.c \
	$(MOD_LOADER_PATH)/mod_list.c \
	$(MOD_LOADER_PATH)/patch.c \
	$(MOD_LOADER_PATH)/hooks.c \
	$(MOD_LOADER_PATH)/redirect_org_files.c \
	$(MOD_LOADER_PATH)/settings.c \
	$(MOD_LOADER_PATH)/inih/ini.c

MODS_PATH = src/example_mods

GRAPHICS_ENHANCEMENT_PATH = $(MODS_PATH)/graphics_enhancement
GRAPHICS_ENHANCEMENT_FILES = \
	$(GRAPHICS_ENHANCEMENT_PATH)/common.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/main.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/60fps/60fps.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/fullscreen/fullscreen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/remove_sprite_alignment/remove_sprite_alignment.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/sprite_resolution/sprite_resolution.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/upscale_window/upscale_window.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/black_bars.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/drawsprite1_centred.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/fix_subforeground_bug.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_beetle_and_basu.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_boss_explosion.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_boss_health.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_bute.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_camera.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_credits.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_exit_screen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_fade.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_fps_counter.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_gaudi.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_inventory_screen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_island_crash.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_loading_screen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_map_screen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_room_name_print.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_screen_flash.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_scrolling_clouds.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_teleport_screen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_text_box.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_tile_drawers.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/patch_title_screen.c \
	$(GRAPHICS_ENHANCEMENT_PATH)/widescreen/widescreen.c

OGG_MUSIC_PATH = $(MODS_PATH)/ogg_music
OGG_MUSIC_SOURCES = \
	$(COMMON_PATH)/sprintfMalloc.c \
	$(OGG_MUSIC_PATH)/decoder.c \
	$(OGG_MUSIC_PATH)/dual_decoder.c \
	$(OGG_MUSIC_PATH)/main.c \
	$(OGG_MUSIC_PATH)/memory_file.c \
	$(OGG_MUSIC_PATH)/playlist.c

ifeq ($(OGG_MUSIC_USE_SNDFILE), true)
OGG_MUSIC_SOURCES += $(OGG_MUSIC_PATH)/decoder_sndfile.c
OGG_MUSIC_LIBS += -lsndfile -lspeex -lflac -lvorbisenc -lvorbis -logg
OGG_MUSIC_CFLAGS += -DUSE_SNDFILE
else
OGG_MUSIC_SOURCES += $(OGG_MUSIC_PATH)/decoder_vorbisfile.c
OGG_MUSIC_LIBS += -lvorbisfile -lvorbis -logg
endif

ifeq ($(OGG_MUSIC_BACKEND), mini_al)
OGG_MUSIC_SOURCES += $(OGG_MUSIC_PATH)/backend_mini_al.c
else ifeq ($(OGG_MUSIC_BACKEND), SDL2)
OGG_MUSIC_SOURCES += $(OGG_MUSIC_PATH)/backend_SDL2.c
OGG_MUSIC_CFLAGS += $(SDL_CFLAGS)
OGG_MUSIC_LIBS += $(SDL_LDFLAGS)
else ifeq ($(OGG_MUSIC_BACKEND), Cubeb)
OGG_MUSIC_SOURCES += $(OGG_MUSIC_PATH)/backend_cubeb.c
OGG_MUSIC_LIBS += -lcubeb -lole32 -lavrt -lwinmm -luuid -lstdc++
endif

all: $(MOD_LOADER_HELPER_OBJECT) bin/dsound.dll bin/mods/mod_loader.dll bin/mods/ogg_music/ogg_music.dll bin/mods/sdl_controller_input/sdl_controller_input.dll bin/mods/wasd_input/wasd_input.dll bin/mods/ikachan_cursor/ikachan_cursor.dll bin/mods/debug_save/debug_save.dll bin/mods/graphics_enhancement/graphics_enhancement.dll bin/mods/3ds_hud/3ds_hud.dll bin/mods/disable_image_protection/disable_image_protection.dll bin/mods/tsc_nonod/tsc_nonod.dll bin/mods/tsc_mbx/tsc_mbx.dll

$(MOD_LOADER_HELPER_OBJECT): $(COMMON_PATH)/mod_loader.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -c -o $@ $^ $(LDFLAGS)

bin/dsound.dll: src/mod_loader_bootstrapper/main.c $(COMMON_PATH)/sprintfMalloc.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/mod_loader.dll: $(MOD_LOADER_SOURCES)
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS) -DINI_ALLOW_MULTILINE=0 -DINI_USE_STACK=0

bin/mods/ogg_music/ogg_music.dll: $(MOD_LOADER_HELPER_OBJECT) $(OGG_MUSIC_SOURCES)
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) $(OGG_MUSIC_CFLAGS) -o $@ $^ $(OGG_MUSIC_LIBS) -shared $(LDFLAGS)

bin/mods/sdl_controller_input/sdl_controller_input.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/sdl_controller_input/main.c $(COMMON_PATH)/sprintfMalloc.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) $(SDL_CFLAGS) -o $@ $^ -shared $(LDFLAGS) $(SDL_LDFLAGS)

bin/mods/wasd_input/wasd_input.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/wasd_input/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/ikachan_cursor/ikachan_cursor.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/ikachan_cursor/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/debug_save/debug_save.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/debug_save/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/graphics_enhancement/graphics_enhancement.dll: $(MOD_LOADER_HELPER_OBJECT) $(GRAPHICS_ENHANCEMENT_FILES)
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/3ds_hud/3ds_hud.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/3ds_hud/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/disable_image_protection/disable_image_protection.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/disable_image_protection/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/tsc_mbx/tsc_mbx.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/tsc_mbx/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)

bin/mods/tsc_nonod/tsc_nonod.dll: $(MOD_LOADER_HELPER_OBJECT) src/example_mods/tsc_nonod/main.c
	mkdir -p $(@D)
	$(CC) $(ALL_CFLAGS) -o $@ $^ -shared $(LDFLAGS)
