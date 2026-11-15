/**
 * Desktop entry for the overlay (main.tsx imports '@pro/desktop_index' when
 * VITE_DESKTOP is also set). We do not ship a Tauri build, but Vite's
 * import-analysis resolves BOTH branches of the if/else at transform time, so
 * the module has to exist or the whole app fails to load.
 */
import { mountPro } from './index';

export function mountProDesktop(): void {
  mountPro();
}
