/**
 * zhanshenkxUno — the custom board this build adds to Velxio, declared as data.
 *
 * Everything the rest of the app reads about a board goes through
 * `registerProBoards()` (frontend/src/lib/proBoardRegistry.ts): it patches
 * BOARD_KIND_LABELS / BOARD_KIND_FQBN so the picker lists the board, the
 * compiler resolves an FQBN for it, and — the part that matters here — the
 * simulator factory in useSimulatorStore picks avr8js purely because the FQBN
 * starts with `arduino:avr:`. No new engine, no new toolchain: the AVR core
 * arduino-cli already installed compiles it, avr8js executes it.
 */
import type { ProBoardDef } from '@velxio/lib/proBoardRegistry';
import { useSimulatorStore } from '@velxio/store/useSimulatorStore';
import { ZHANSHENKX_UNO_H, ZHANSHENKX_UNO_W, ZhanshenkxUnoElement } from './ZhanshenkxUnoElement';

export const ZHANSHENKX_UNO_KIND = 'zhanshenkx-uno';
export const ZHANSHENKX_UNO_TAG = 'zhanshenkx-uno';

/** D0..D13 -> 0..13, A0..A5 -> 14..19 (the AVR's own Arduino numbering).
 *  Supply pads return -1: they are not GPIOs and must not stamp a V source. */
function pinToNumber(pinName: string): number | null {
  const dig = /^D(\d+)$/.exec(pinName);
  if (dig) return Number(dig[1]);
  const ana = /^A(\d+)$/.exec(pinName);
  if (ana) return 14 + Number(ana[1]);
  return -1;
}

const SEED_SKETCH = `// Zhanshenkx Uno R3 — running on avr8js inside the browser.
// The board's "L" LED hangs off D13, same as the Uno it is compatible with.

const int LED = 13;

void setup() {
  Serial.begin(115200);
  pinMode(LED, OUTPUT);
  Serial.println("Zhanshenkx Uno R3 online");
  Serial.print("F_CPU = ");
  Serial.print(F_CPU);
  Serial.println(" Hz");
}

void loop() {
  static unsigned long n = 0;
  digitalWrite(LED, !digitalRead(LED));
  Serial.print("blink ");
  Serial.print(n++);
  Serial.print("  millis() = ");
  Serial.println(millis());
  delay(500);
}
`;

export const ZHANSHENKX_UNO_DEF: ProBoardDef = {
  kind: ZHANSHENKX_UNO_KIND,
  label: 'Zhanshenkx Uno R3',
  description: 'Custom ATmega328P board — AVR8 in the browser, Uno-compatible pinout',
  fqbn: 'arduino:avr:uno',
  tag: ZHANSHENKX_UNO_TAG,
  size: { w: ZHANSHENKX_UNO_W, h: ZHANSHENKX_UNO_H },
  pinToNumber,
  adcPins: [0, 1, 2, 3, 4, 5].map((ch) => ({ pinName: `A${ch}`, channel: ch })),
  power: {
    vcc: 5,
    gnd: ['GND.1', 'GND.2'],
    vcc_pins: ['5V'],
    aux: { volts: 3.3, pins: ['3V3'] },
  },
  defaultFiles: {
    arduino: [{ name: 'sketch.ino', content: SEED_SKETCH }],
  },
  icon: 'cpu',
  color: '#0f7a5a',
};

/** Defines the custom element. Must run before any board of this kind renders
 *  (the picker creates one for its thumbnail the moment the list is built). */
export function defineZhanshenkxUnoElement(): void {
  if (!customElements.get(ZHANSHENKX_UNO_TAG)) {
    customElements.define(ZHANSHENKX_UNO_TAG, ZhanshenkxUnoElement);
  }
}

/** Wires the on-board LED to the emulated pin. See ZhanshenkxUnoElement.watchPin. */
export function attachZhanshenkxUnoPinWatch(): void {
  try {
    const st = useSimulatorStore.getState() as unknown as {
      getBusBinding?: () => {
        pins?: { onPinChange?: (pin: number, cb: (p: number, s: boolean) => void) => () => void };
      };
    };
    const onPinChange = st.getBusBinding?.()?.pins?.onPinChange;
    if (typeof onPinChange === 'function') {
      ZhanshenkxUnoElement.watchPin = (pin, cb) => onPinChange(pin, (_p, s) => cb(s));
    }
  } catch {
    /* no store in this context: board runs, LED stays dark */
  }
}
