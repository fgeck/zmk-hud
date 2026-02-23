# SPDX-License-Identifier: MIT

if(CONFIG_ZMK_HUD)
  target_sources(app PRIVATE src/hud_broadcaster.c)
endif()
