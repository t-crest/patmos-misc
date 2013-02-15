/*  Copyright (C) 2002     Manuel Novoa III
 *  From my (incomplete) stdlib library for linux and (soon) elks.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Library General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Library General Public License for more details.
 *
 *  You should have received a copy of the GNU Library General Public
 *  License along with this library; if not, write to the Free
 *  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#include "sortexample.h"

/* This code is derived from a public domain shell sort routine by
 * Ray Gardner and found in Bob Stout's snippets collection.  The
 * original code is included below in an #if 0/#endif block.
 *
 * I modified it to avoid the possibility of overflow in the wgap
 * calculation, as well as to reduce the generated code size with
 * bcc and gcc. */

void shellsort(void  *base,
           size_t nel)
{
	size_t wgap, i, j, k;
    const size_t width = sizeof(Element);
	char tmp;

	if ((nel > 1) && (width > 0)) {
		assert(nel <= ((size_t)(-1)) / width); /* check for overflow */
		wgap = 0;
		do {
			wgap = 3 * wgap + 1;
		} while (wgap < (nel-1)/3);
		/* From the above, we know that either wgap == 1 < nel or */
		/* ((wgap-1)/3 < (int) ((nel-1)/3) <= (nel-1)/3 ==> wgap <  nel. */
		wgap *= width;			/* So this can not overflow if wnel doesn't. */
		nel *= width;			/* Convert nel to 'wnel' */
		do {
			i = wgap;
			do {
				j = i;
				do {
					register char *a;
					register char *b;

					j -= wgap;
					a = j + ((char *)base);
					b = a + wgap;
					if (sort_comparator(a, b) <= 0) {
						break;
					}
					k = width;
					do {
						tmp = *a;
						*a++ = *b;
						*b++ = tmp;
					} while (--k);
				} while (j >= wgap);
				i += width;
			} while (i < nel);
			wgap = (wgap - width)/3;
		} while (wgap);
	}
}

/* ---------- original snippets version below ---------- */

#if 0
/*
**  ssort()  --  Fast, small, qsort()-compatible Shell sort
**
**  by Ray Gardner,  public domain   5/90
*/

#include <stddef.h>

void ssort(void  *base,
           size_t nel,
           size_t width,
           int (*comp)(const void *, const void *))
{
	size_t wnel, gap, wgap, i, j, k;
	char *a, *b, tmp;

	wnel = width * nel;
	for (gap = 0; ++gap < nel;)
		gap *= 3;
	while ((gap /= 3) != 0) {
		wgap = width * gap;
		for (i = wgap; i < wnel; i += width) {
			for (j = i - wgap; ;j -= wgap) {
				a = j + (char *)base;
				b = a + wgap;
				if ((*comp)(a, b) <= 0)
					break;
				k = width;
				do {
					tmp = *a;
					*a++ = *b;
					*b++ = tmp;
				} while (--k);
				if (j < wgap)
					break;
			}
		}
	}
}
#endif

