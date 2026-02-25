# SPDX-License-Identifier: MIT

# Only compile on central side for split keyboards, or on unibody keyboards
if ((NOT CONFIG_ZMK_SPLIT) OR CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
  if(CONFIG_ZMK_HUD)
    target_sources(app PRIVATE ${CMAKE_CURRENT_LIST_DIR}/firmware/src/hud_broadcaster.c)
  endif()
endif()
