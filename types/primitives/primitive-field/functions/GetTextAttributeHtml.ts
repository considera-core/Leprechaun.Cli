import { GetBindingAttributeHtml } from '../../../core/functions/GetBindingAttributeHtml';
import { GetStringLiteral } from '../../../core/functions/GetStringLiteral';
import { GetEscapeAttribute } from '../../../core/functions/GetEscapeAttribute';

export function GetTextAttributeHtml(name: string, value: string): string {
  return value.includes('{{')
    ? GetBindingAttributeHtml(name, GetStringLiteral(value))
    : `${name}="${GetEscapeAttribute(value)}"`;
}
