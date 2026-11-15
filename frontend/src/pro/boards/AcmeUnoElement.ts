/**
 * AcmeUnoElement — a Velxio board Web Component written from scratch.
 *
 * Contract it must satisfy (see frontend/src/simulation/boardPads.ts):
 *   - publish `pinInfo: ElementPin[]` on the DOM node — the canvas draws its
 *     pin overlays and resolves wire endpoints from exactly this list;
 *   - draw itself at the size the ProBoardDef declares, so selection boxes and
 *     rotated pin math line up.
 *
 * Deliberately plain HTMLElement (not Lit): this file is the smallest possible
 * example of "here is how you add your own board art", and pulling Lit in would
 * hide the fact that a board is just an element with an array of pins.
 */

/** Shape copied from @wokwi/elements' ElementPin (kept structural, not imported,
 *  so the overlay does not depend on the library's internal module paths). */
export interface ElementPin {
  name: string;
  x: number;
  y: number;
  signals: Array<
    | { type: 'power'; signal: 'GND' | 'VCC'; voltage?: number }
    | { type: 'analog'; channel?: number }
    | { type: 'pwm' }
    | { type: 'i2c'; signal: 'SDA' | 'SCL'; bus: number }
    | { type: 'spi'; signal: 'SCK' | 'MOSI' | 'MISO' | 'SS'; bus: number }
    | { type: 'usart'; signal: 'RX' | 'TX'; bus: number }
  >;
}

export const ACME_UNO_W = 270;
export const ACME_UNO_H = 160;

const GND = (): ElementPin['signals'][number] => ({ type: 'power', signal: 'GND' });
const VCC = (v: number): ElementPin['signals'][number] => ({
  type: 'power',
  signal: 'VCC',
  voltage: v,
});
const PWM = (): ElementPin['signals'][number] => ({ type: 'pwm' });
const ADC = (ch: number): ElementPin['signals'][number] => ({ type: 'analog', channel: ch });

/** Digital header: D0..D13, left to right along the top edge. */
const DIGI_X0 = 24;
const DIGI_STEP = 15.5;
const DIGI_Y = 16;
const DIGI_PWM = new Set([3, 5, 6, 9, 10, 11]);

/** Bottom edge: A0..A5 then the supply pads, same pitch. */
const ANALOG_Y = 144;

function buildPinInfo(): ElementPin[] {
  const pins: ElementPin[] = [];
  for (let d = 0; d <= 13; d++) {
    pins.push({
      name: `D${d}`,
      x: DIGI_X0 + d * DIGI_STEP,
      y: DIGI_Y,
      signals: DIGI_PWM.has(d) ? [PWM()] : [],
    });
  }
  for (let a = 0; a <= 5; a++) {
    pins.push({ name: `A${a}`, x: DIGI_X0 + a * DIGI_STEP, y: ANALOG_Y, signals: [ADC(a)] });
  }
  const supply: Array<[string, ElementPin['signals']]> = [
    ['GND.1', [GND()]],
    ['GND.2', [GND()]],
    ['5V', [VCC(5)]],
    ['3V3', [VCC(3.3)]],
    ['VIN', []],
    ['AREF', []],
  ];
  supply.forEach(([name, signals], i) => {
    pins.push({ name, x: DIGI_X0 + (6 + i) * DIGI_STEP, y: ANALOG_Y, signals });
  });
  return pins;
}

const PIN_INFO = buildPinInfo();

function pad(x: number, y: number): string {
  return `<rect x="${x - 3.2}" y="${y - 3.2}" width="6.4" height="6.4" rx="1" fill="#d4a548"/>`;
}

function art(): string {
  const digitalPads = PIN_INFO.filter((p) => p.name.startsWith('D')).map((p) => pad(p.x, p.y));
  const lowerPads = PIN_INFO.filter((p) => !p.name.startsWith('D')).map((p) => pad(p.x, p.y));
  return `
<svg xmlns="http://www.w3.org/2000/svg" width="${ACME_UNO_W}" height="${ACME_UNO_H}" viewBox="0 0 ${ACME_UNO_W} ${ACME_UNO_H}">
  <rect x="0.5" y="0.5" width="${ACME_UNO_W - 1}" height="${ACME_UNO_H - 1}" rx="8"
        fill="#0f7a5a" stroke="#0a5c44" stroke-width="1"/>
  <!-- silkscreen -->
  <text x="135" y="40" text-anchor="middle" font-family="monospace" font-size="13"
        fill="#d8f5ea" letter-spacing="3">ACME UNO R3</text>
  <text x="135" y="50" text-anchor="middle" font-family="monospace" font-size="7"
        fill="#9ed9c4" letter-spacing="1.5">ATmega328P · 16 MHz</text>
  <!-- mounting holes -->
  <circle cx="10" cy="10" r="3.2" fill="#0a5c44"/>
  <circle cx="260" cy="10" r="3.2" fill="#0a5c44"/>
  <circle cx="10" cy="150" r="3.2" fill="#0a5c44"/>
  <circle cx="260" cy="150" r="3.2" fill="#0a5c44"/>
  <!-- USB-C -->
  <rect x="3" y="62" width="26" height="26" rx="4" fill="#b8bcc4" stroke="#8b9099"/>
  <rect x="6" y="70" width="18" height="10" rx="3" fill="#6f757e"/>
  <!-- barrel jack -->
  <circle cx="20" cy="118" r="13" fill="#2a2f36" stroke="#4c545e"/>
  <circle cx="20" cy="118" r="6" fill="#12161a"/>
  <!-- MCU -->
  <rect x="104" y="56" width="62" height="46" rx="3" fill="#1b1f24" stroke="#0a0d10"/>
  <text x="135" y="83" text-anchor="middle" font-family="monospace" font-size="7" fill="#7f8b96">ATMEGA</text>
  <!-- crystals + regulator -->
  <rect x="86" y="120" width="18" height="8" rx="2.5" fill="#c9ced6"/>
  <rect x="176" y="62" width="12" height="14" rx="2" fill="#2b3036"/>
  <!-- header strips -->
  <rect x="${DIGI_X0 - 6}" y="${DIGI_Y - 7}" width="${13 * DIGI_STEP + 12}" height="14" rx="2" fill="#0b1915"/>
  <rect x="${DIGI_X0 - 6}" y="${ANALOG_Y - 7}" width="${11 * DIGI_STEP + 12}" height="14" rx="2" fill="#0b1915"/>
  ${digitalPads.join('')}
  ${lowerPads.join('')}
  <!-- on-board LEDs: L (pin 13), TX, RX -->
  <circle id="led-l" cx="243" cy="72" r="4.5" fill="#3a2f12" stroke="#1d1608"/>
  <circle id="led-tx" cx="243" cy="90" r="4.5" fill="#3a2f12" stroke="#1d1608"/>
  <circle id="led-rx" cx="243" cy="108" r="4.5" fill="#3a2f12" stroke="#1d1608"/>
  <text x="243" y="124" text-anchor="middle" font-family="monospace" font-size="6" fill="#9ed9c4">L TX RX</text>
</svg>`.trim();
}

const TEMPLATE = art();

export class AcmeUnoElement extends HTMLElement {
  /** Same property name the Uno's wokwi element exposes, so any code that
   *  drives a board's "L" LED can drive this one too. */
  private _led13 = false;
  private _unwatch: (() => void) | null = null;

  /**
   * How the element learns what the emulated pin is doing.
   *
   * The canvas hands `onboardLeds` to the boards it knows by name (Uno, Nano,
   * Mega, ESP32), and `getProBoard(kind).render` is not given that prop — so an
   * overlay board has no official channel for its own LED. mountPro() therefore
   * injects the store's pin subscription here, and the element stays free of
   * store imports. Null means no animation; the board still runs.
   */
  static watchPin: ((pin: number, cb: (state: boolean) => void) => () => void) | null = null;

  connectedCallback(): void {
    if (this._unwatch || !AcmeUnoElement.watchPin) return;
    try {
      this._unwatch = AcmeUnoElement.watchPin(13, (state) => {
        this.led13 = state;
        if (state) this.pulseTx();
      });
    } catch {
      /* no store yet (picker thumbnail) — the board renders, just no LED */
    }
  }

  disconnectedCallback(): void {
    this._unwatch?.();
    this._unwatch = null;
  }

  private pulseTx(): void {
    const led = this.shadowRoot?.getElementById('led-tx');
    if (!led) return;
    led.setAttribute('fill', '#ffd23f');
    window.setTimeout(() => led.setAttribute('fill', '#3a2f12'), 60);
  }

  constructor() {
    super();
    this.attachShadow({ mode: 'open' });
    this.shadowRoot!.innerHTML =
      `<style>:host{display:block;width:${ACME_UNO_W}px;height:${ACME_UNO_H}px;}` +
      `svg{display:block;user-select:none}</style>${TEMPLATE}`;
  }

  get pinInfo(): ElementPin[] {
    return PIN_INFO;
  }

  get led13(): boolean {
    return this._led13;
  }

  set led13(on: boolean) {
    this._led13 = !!on;
    const led = this.shadowRoot?.getElementById('led-l');
    if (led) led.setAttribute('fill', this._led13 ? '#ff5533' : '#3a2f12');
  }

  /** Header LEDs follow the UART activity the runtime reports, if it does. */
  set serialActivity(on: boolean) {
    const led = this.shadowRoot?.getElementById('led-tx');
    if (led) led.setAttribute('fill', on ? '#ffd23f' : '#3a2f12');
  }
}
