import { GetStringLiteral } from './GetStringLiteral';

export function GetValueLiteral(value: unknown): string {
  return typeof value === 'string'
    ? GetStringLiteral(value)
    : JSON.stringify(value) ?? 'undefined';
}
