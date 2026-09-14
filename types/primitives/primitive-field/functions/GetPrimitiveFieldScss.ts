/**
 * Generates the styles for the component hosting the configured primitive field.
 */
export function GetPrimitiveFieldScss(): string {
  return [
    ':host {',
    '  display: block;',
    '}',
  ].join('\n');
}
