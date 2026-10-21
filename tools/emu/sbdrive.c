/* sbdrive: a line protocol around SameBoy's core, so a script can drive it.
   stdin commands: frames N | key NAME 0|1 | peek ADDR LEN | poke ADDR V... |
   shot PATH | regs | quit. Replies one line each ("ok" or values). */
#include <Core/gb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static GB_gameboy_t gb;
static uint32_t bitmap[256 * 224];
static volatile unsigned vblanks;
static const char *bootdir;
static void vblank(GB_gameboy_t *g, GB_vblank_type_t t) { vblanks++; }
static uint32_t rgb(GB_gameboy_t *g, uint8_t r, uint8_t gg, uint8_t b) { return (b << 16) | (gg << 8) | r; }
static void logcb(GB_gameboy_t *g, const char *s, GB_log_attributes_t a) {}
static void bootcb(GB_gameboy_t *g, GB_boot_rom_t type) {
    static const char *names[] = {[GB_BOOT_ROM_DMG_0]="dmg_boot.bin",[GB_BOOT_ROM_DMG]="dmg_boot.bin",[GB_BOOT_ROM_MGB]="mgb_boot.bin",
        [GB_BOOT_ROM_SGB]="sgb_boot.bin",[GB_BOOT_ROM_SGB2]="sgb2_boot.bin",[GB_BOOT_ROM_CGB_0]="cgb0_boot.bin",[GB_BOOT_ROM_CGB]="cgb_boot.bin",
        [GB_BOOT_ROM_CGB_E]="cgb_boot.bin",[GB_BOOT_ROM_AGB_0]="agb_boot.bin",[GB_BOOT_ROM_AGB]="agb_boot.bin"};
    char path[1024]; snprintf(path, sizeof path, "%s/%s", bootdir, names[type]); GB_load_boot_rom(g, path);
}
static const struct { const char *n; GB_key_t k; } keys[] = {{"right",GB_KEY_RIGHT},{"left",GB_KEY_LEFT},{"up",GB_KEY_UP},{"down",GB_KEY_DOWN},
    {"a",GB_KEY_A},{"b",GB_KEY_B},{"select",GB_KEY_SELECT},{"start",GB_KEY_START}};
static unsigned stops;
/* The core's debugger reads its commands from stdin when the game stops it
   (ld b,b breakpoints, crashes); answer for it so it never eats ours. */
static char *dbg_input(GB_gameboy_t *g) { (void)g; stops++; return strdup("continue"); }
static char *dbg_async(GB_gameboy_t *g) { (void)g; return NULL; }
int main(int argc, char **argv) {
    if (argc < 4) { fprintf(stderr, "usage: sbdrive model(dmg|sgb|cgb) bootdir rom [sav]\n"); return 1; }
    GB_model_t model = !strcmp(argv[1],"dmg") ? GB_MODEL_DMG_B : !strcmp(argv[1],"sgb") ? GB_MODEL_SGB_NTSC : GB_MODEL_CGB_E;
    bootdir = argv[2];
    GB_init(&gb, model);
    GB_set_boot_rom_load_callback(&gb, bootcb);
    GB_set_vblank_callback(&gb, vblank);
    GB_set_pixels_output(&gb, bitmap);
    GB_set_rgb_encode_callback(&gb, rgb);
    GB_set_log_callback(&gb, logcb);
    GB_set_input_callback(&gb, dbg_input);
    GB_set_async_input_callback(&gb, dbg_async);
    GB_set_color_correction_mode(&gb, GB_COLOR_CORRECTION_DISABLED);
    GB_set_emulate_joypad_bouncing(&gb, false);
    if (GB_load_rom(&gb, argv[3])) { perror("rom"); return 1; }
    if (argc > 4) GB_load_battery(&gb, argv[4]);
    GB_set_turbo_mode(&gb, true, true); /* no real-time pacing; render every frame */
    GB_set_turbo_cap(&gb, 0);
    char line[4096];
    setvbuf(stdout, NULL, _IOLBF, 0);
    while (fgets(line, sizeof line, stdin)) {
        char cmd[32]; if (sscanf(line, "%31s", cmd) != 1) continue;
        if (!strcmp(cmd, "frames")) { unsigned n = 1; sscanf(line + 6, "%u", &n); unsigned target = vblanks + n;
            while (vblanks < target) GB_run(&gb); printf("ok\n"); }
        else if (!strcmp(cmd, "key")) { char k[16]; int v; sscanf(line + 3, "%15s %d", k, &v);
            for (unsigned i = 0; i < 8; i++) if (!strcmp(k, keys[i].n)) GB_set_key_state(&gb, keys[i].k, v); printf("ok\n"); }
        else if (!strcmp(cmd, "peek")) { unsigned a, n = 1; sscanf(line + 4, "%x %u", &a, &n);
            for (unsigned i = 0; i < n; i++) printf("%02x", GB_safe_read_memory(&gb, a + i)); printf("\n"); }
        else if (!strcmp(cmd, "poke")) { char *p = line + 4; unsigned a; int used; sscanf(p, "%x%n", &a, &used); p += used;
            unsigned v; while (sscanf(p, "%x%n", &v, &used) == 1) { GB_write_memory(&gb, a++, v); p += used; } printf("ok\n"); }
        else if (!strcmp(cmd, "shot")) { char path[1024]; sscanf(line + 4, "%1023s", path); FILE *f = fopen(path, "wb");
            unsigned w = GB_get_screen_width(&gb), h = GB_get_screen_height(&gb);
            fprintf(f, "P6\n%u %u\n255\n", w, h);
            for (unsigned i = 0; i < w * h; i++) { uint32_t c = bitmap[i]; fputc(c & 0xFF, f); fputc((c >> 8) & 0xFF, f); fputc((c >> 16) & 0xFF, f); }
            fclose(f); printf("ok\n"); }
        else if (!strcmp(cmd, "regs")) { GB_registers_t *r = GB_get_registers(&gb); printf("%04x %04x %u\n", r->pc, r->sp, stops); }
        else if (!strcmp(cmd, "battery")) { char path[1024]; sscanf(line + 7, "%1023s", path); GB_save_battery(&gb, path); printf("ok\n"); }
        else if (!strcmp(cmd, "quit")) break;
        else printf("?\n");
    }
    return 0;
}
