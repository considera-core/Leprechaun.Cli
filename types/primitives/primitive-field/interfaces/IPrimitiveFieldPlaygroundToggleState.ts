import type { WritableSignal } from '@angular/core';
import { PrimitiveFieldStateType } from '@consideracore/angular-extensions';

export interface IPrimitiveFieldPlaygroundToggleState extends PrimitiveFieldStateType<boolean> {
  idSuffix: WritableSignal<boolean>;
  description: WritableSignal<boolean>;
  label: WritableSignal<boolean>;
  code: WritableSignal<boolean>;
  disabled: WritableSignal<boolean>;
  invalid: WritableSignal<boolean>;
  italic: WritableSignal<boolean>;
  loading: WritableSignal<boolean>;
  required: WritableSignal<boolean>;
  showEmpty: WritableSignal<boolean>;
  strong: WritableSignal<boolean>;
  numberDecimals: WritableSignal<boolean>;
  density: WritableSignal<boolean>;
  fieldType: WritableSignal<boolean>;
  fieldOperation: WritableSignal<boolean>;
  selectOptions: WritableSignal<boolean>;
  value: WritableSignal<boolean>;
}
