import type { WritableSignal } from '@angular/core';
import { PrimitiveStringValueType } from '../../../core/PrimitiveStringValueType';

export type PrimitiveFieldStateType<T extends PrimitiveStringValueType> = {
  idSuffix: WritableSignal<T>;
  description: WritableSignal<T>;
  label: WritableSignal<T>;
  code: WritableSignal<T>;
  disabled: WritableSignal<T>;
  invalid: WritableSignal<T>;
  italic: WritableSignal<T>;
  loading: WritableSignal<T>;
  required: WritableSignal<T>;
  showEmpty: WritableSignal<T>;
  strong: WritableSignal<T>;
  numberDecimals: WritableSignal<T>;
  density: WritableSignal<T>;
  fieldType: WritableSignal<T>;
  fieldOperation: WritableSignal<T>;
  selectOptions: WritableSignal<T>;
  value: WritableSignal<T>;
} & BaseValuesStateType<T>;

export type BaseValuesStateType<T extends PrimitiveStringValueType> = Record<string, WritableSignal<T>>;

export type BaseValuesDataType = Record<string, any>;
