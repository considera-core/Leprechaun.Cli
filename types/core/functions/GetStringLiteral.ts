export function GetStringLiteral(value: string): string {
  const escaped = value
    .replace(/\\/g, '\\\\')
    .replace(/'/g, `\\'`)
    .replace(/\n/g, '\\n');
  return `'${escaped}'`;
}
