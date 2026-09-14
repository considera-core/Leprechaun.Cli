import { signal } from '@angular/core';
import { PrimitiveFieldDensityEnum } from '../primitives/primitive-field/enums/PrimitiveFieldDensityEnum';
import { PrimitiveFieldOperationEnum } from '../primitives/primitive-field/enums/PrimitiveFieldOperationEnum';
import { PrimitiveFieldTypeEnum } from '../primitives/primitive-field/enums/PrimitiveFieldTypeEnum';
import { PrimitiveFieldStateType } from '../primitives/primitive-field/interfaces/PrimitiveFieldStateType';

export const DefaultPrimitiveFieldState: PrimitiveFieldStateType<string> = {
  idSuffix: signal<string>('default'),
  description: signal<string>('Just a demo field in a small card world'),
  label: signal<string>('Primitive label'),
  code: signal<string>('false'),
  disabled: signal<string>('false'),
  invalid: signal<string>('false'),
  italic: signal<string>('true'),
  loading: signal<string>('false'),
  required: signal<string>('false'),
  showEmpty: signal<string>('true'),
  strong: signal<string>('true'),
  numberDecimals: signal<string>('0'),
  density: signal<string>(PrimitiveFieldDensityEnum.Default.toString()),
  fieldType: signal<string>(PrimitiveFieldTypeEnum.StringText.toString()),
  fieldOperation: signal<string>(PrimitiveFieldOperationEnum.View.toString()),
  selectOptions: signal<string>('Option 1,Option 2,Option 3'),
  value: signal<string>('Value'),
} satisfies PrimitiveFieldStateType<string>;

