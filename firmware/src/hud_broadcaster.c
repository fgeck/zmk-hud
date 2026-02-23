/*
 * SPDX-License-Identifier: MIT
 *
 * ZMK HUD Broadcaster
 *
 * Broadcasts layer state and key press events via Raw HID reports
 * for consumption by desktop HUD applications.
 *
 * HID Report Format (32 bytes):
 *
 * Layer Change:
 *   [0] = 0x01 (MSG_LAYER_CHANGE)
 *   [1] = layer_index (0-31)
 *   [2] = is_active (0/1)
 *   [3] = layer_state bitmask (lower 8 bits)
 *   [4] = layer_state bitmask (upper 8 bits)
 *   [5-31] = reserved (0)
 *
 * Key Press:
 *   [0] = 0x02 (MSG_KEY_PRESS)
 *   [1] = key_position (0-255)
 *   [2] = is_pressed (0/1)
 *   [3] = modifier_flags (ctrl=1, shift=2, alt=4, gui=8)
 *   [4-31] = reserved (0)
 */

#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>

#include <zmk/event_manager.h>
#include <zmk/events/layer_state_changed.h>
#include <zmk/events/keycode_state_changed.h>
#include <zmk/keymap.h>
#include <zmk/hid.h>

#include <raw_hid/events.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

/* Message types */
#define MSG_LAYER_CHANGE 0x01
#define MSG_KEY_PRESS    0x02

/* Modifier flags */
#define MOD_CTRL  (1 << 0)
#define MOD_SHIFT (1 << 1)
#define MOD_ALT   (1 << 2)
#define MOD_GUI   (1 << 3)

/* Report size must match CONFIG_RAW_HID_REPORT_SIZE */
#define REPORT_SIZE 32

/**
 * Send a raw HID report
 */
static void send_hud_report(const uint8_t *data, uint8_t len) {
    struct raw_hid_sent_event ev = {
        .data = data,
        .length = len
    };
    raise_raw_hid_sent_event(ev);
}

/**
 * Handle layer state changes
 */
static int hud_layer_state_changed_listener(const zmk_event_t *eh) {
    const struct zmk_layer_state_changed *ev = as_zmk_layer_state_changed(eh);
    if (ev == NULL) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    uint8_t report[REPORT_SIZE] = {0};
    uint32_t layer_state = zmk_keymap_layer_state();

    report[0] = MSG_LAYER_CHANGE;
    report[1] = ev->layer;
    report[2] = ev->state ? 1 : 0;
    report[3] = (uint8_t)(layer_state & 0xFF);
    report[4] = (uint8_t)((layer_state >> 8) & 0xFF);

    LOG_DBG("HUD: Layer %d %s (state: 0x%04x)",
            ev->layer,
            ev->state ? "activated" : "deactivated",
            layer_state);

    send_hud_report(report, REPORT_SIZE);

    return ZMK_EV_EVENT_BUBBLE;
}

/**
 * Handle key press/release events
 */
static int hud_keycode_state_changed_listener(const zmk_event_t *eh) {
    const struct zmk_keycode_state_changed *ev = as_zmk_keycode_state_changed(eh);
    if (ev == NULL) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    /* Build modifier flags from current HID state */
    uint8_t mod_flags = 0;
    zmk_mod_flags_t mods = zmk_hid_get_explicit_mods();

    if (mods & (MOD_BIT(HID_USAGE_KEY_KEYBOARD_LEFTCONTROL) |
                MOD_BIT(HID_USAGE_KEY_KEYBOARD_RIGHTCONTROL))) {
        mod_flags |= MOD_CTRL;
    }
    if (mods & (MOD_BIT(HID_USAGE_KEY_KEYBOARD_LEFTSHIFT) |
                MOD_BIT(HID_USAGE_KEY_KEYBOARD_RIGHTSHIFT))) {
        mod_flags |= MOD_SHIFT;
    }
    if (mods & (MOD_BIT(HID_USAGE_KEY_KEYBOARD_LEFTALT) |
                MOD_BIT(HID_USAGE_KEY_KEYBOARD_RIGHTALT))) {
        mod_flags |= MOD_ALT;
    }
    if (mods & (MOD_BIT(HID_USAGE_KEY_KEYBOARD_LEFT_GUI) |
                MOD_BIT(HID_USAGE_KEY_KEYBOARD_RIGHT_GUI))) {
        mod_flags |= MOD_GUI;
    }

    uint8_t report[REPORT_SIZE] = {0};

    report[0] = MSG_KEY_PRESS;
    report[1] = (uint8_t)(ev->keycode & 0xFF);
    report[2] = ev->state ? 1 : 0;
    report[3] = mod_flags;

    LOG_DBG("HUD: Key 0x%02x %s (mods: 0x%02x)",
            ev->keycode,
            ev->state ? "pressed" : "released",
            mod_flags);

    send_hud_report(report, REPORT_SIZE);

    return ZMK_EV_EVENT_BUBBLE;
}

/* Register event listeners */
ZMK_LISTENER(hud_layer, hud_layer_state_changed_listener);
ZMK_SUBSCRIPTION(hud_layer, zmk_layer_state_changed);

ZMK_LISTENER(hud_keycode, hud_keycode_state_changed_listener);
ZMK_SUBSCRIPTION(hud_keycode, zmk_keycode_state_changed);
