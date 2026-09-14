import { ISelectOption } from '@tylertech/forge';

export function ConvertStringToSelectOptions(selectOptions: string): ISelectOption[] {
  return selectOptions.split(',').map(option => ({
    label: option,
    value: option,
  }));
}
