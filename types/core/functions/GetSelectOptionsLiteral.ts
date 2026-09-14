import { ISelectOption } from '@tylertech/forge';
import { GetStringLiteral } from './GetStringLiteral';
import { GetValueLiteral } from './GetValueLiteral';

export function GetSelectOptionsLiteral(options: ISelectOption[]): string {
  if (options.length === 0) {
    return '[]';
  }

  const entries = options.map(option => `    { label: ${GetStringLiteral(option.label)}, value: ${GetValueLiteral(option.value)} }`);
  return `[\n${entries.join(',\n')}\n  ]`;
}
