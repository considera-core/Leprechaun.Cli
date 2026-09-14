import type { Signal } from '@angular/core';
import type { ISelectOption } from '@tylertech/forge';
import type { PrimitiveFieldDensityEnum } from '../enums/PrimitiveFieldDensityEnum';
import type { PrimitiveFieldOperationEnum } from '../enums/PrimitiveFieldOperationEnum';
import type { PrimitiveFieldTypeEnum } from '../enums/PrimitiveFieldTypeEnum';

export interface IPrimitiveFieldState {
  idSuffix: Signal<string>;
  description: Signal<string>;
  label: Signal<string>;
  code: Signal<boolean>;
  disabled: Signal<boolean>;
  invalid: Signal<boolean>;
  italic: Signal<boolean>;
  loading: Signal<boolean>;
  required: Signal<boolean>;
  showEmpty: Signal<boolean>;
  strong: Signal<boolean>;
  numberDecimals: Signal<number>;
  density: Signal<PrimitiveFieldDensityEnum>;
  fieldType: Signal<PrimitiveFieldTypeEnum>;
  fieldOperation: Signal<PrimitiveFieldOperationEnum>;
  selectOptions: Signal<ISelectOption[]>;
  value: Signal<string>;
}
