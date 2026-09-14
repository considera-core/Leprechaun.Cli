import { GetEscapeAttribute } from './GetEscapeAttribute';

export function GetBindingAttributeHtml(name: string, expression: string): string {
  return `[${name}]="${GetEscapeAttribute(expression)}"`;
}
