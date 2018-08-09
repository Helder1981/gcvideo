/* GCVideo DVI Firmware

   Copyright (C) 2015-2017, Ingo Korb <ingo@akana.de>
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
   THE POSSIBILITY OF SUCH DAMAGE.


   menu.h: Text mode menus

*/

#ifndef MENU_H
#define MENU_H

#include <stdbool.h>

typedef enum {
  VALTYPE_BOOL,
  VALTYPE_EVENODD,
  VALTYPE_RGBMODE,
  VALTYPE_BYTE,
  VALTYPE_SBYTE_99,  // -99 to 99
  VALTYPE_SBYTE_127, // -128 to 127
  VALTYPE_UPSAMPLING,
} valuetype_t;

typedef struct {
  int  (*get)(void);
  bool (*set)(int value);
  valuetype_t type;
} valueitem_t;

typedef struct {
  char         *text;
  valueitem_t  *value;
  unsigned char line;
  unsigned char flags;
} menuitem_t;

struct menu_s;

typedef void (*draw_callback_t)(struct menu_s *menu);

typedef struct menu_s {
  unsigned char   xpos, ypos;
  unsigned char   xsize, ysize;
  draw_callback_t drawcallback;
  unsigned int    entries;
  menuitem_t     *items;
} menu_t;

#define MENU_FLAG_DISABLED (1 << 0)

#define MENU_ABORT       -1
#define MENU_VIDEOCHANGE -2

void menu_draw(menu_t *menu);
int  menu_exec(menu_t *menu, unsigned int initial_item);

#endif
