import { ISelectOption } from '@tylertech/forge';

export function ConvertSelectOptionsToString(selectOptions: ISelectOption[]): string {
  return selectOptions.map(option => option.label).join(',');
}
