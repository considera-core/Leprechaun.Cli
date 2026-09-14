/**
 * Reads a config toggle. The playground's switch fields write the strings `'true'` / `'false'` into the
 * toggle signals, so a plain truthiness check would treat an unchecked `'false'` as still on.
 */
export function IsSignalTrue(toggle: () => boolean): boolean {
  return String(toggle()) === 'true';
}
