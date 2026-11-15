/**
 * Our overlay — the entry point main.tsx dynamic-imports when
 * VITE_PRO_BUILD=true (vite.config.ts maps `@pro` to this directory instead of
 * src/__pro_stub__).
 *
 * Keeping our work here rather than editing the OSS tree is the whole point:
 * `git diff` against upstream stays empty, so pulling Velxio's next release is
 * a fast-forward instead of a merge.
 */
import { registerProBoards } from '@velxio/lib/proBoardRegistry';
import {
  ZHANSHENKX_UNO_DEF,
  attachZhanshenkxUnoPinWatch,
  defineZhanshenkxUnoElement,
} from './boards/zhanshenkxUno';

export function mountPro(): void {
  // 1. The custom element must exist before the picker draws a thumbnail.
  defineZhanshenkxUnoElement();
  // 2. Data registration: label, FQBN, pin map, seed sketch.
  registerProBoards([ZHANSHENKX_UNO_DEF]);
  // 3. Let the board's own LED follow the emulated pin.
  attachZhanshenkxUnoPinWatch();

  // eslint-disable-next-line no-console
  console.info('[overlay] registered board:', ZHANSHENKX_UNO_DEF.kind, '->', ZHANSHENKX_UNO_DEF.fqbn);
}
