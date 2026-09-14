import { WritableSignal } from '@angular/core';
import { ISelectOption } from '@tylertech/forge';
import { PrimitiveFieldTypeEnum } from '../primitives/primitive-field/enums/PrimitiveFieldTypeEnum';
import { PrimitiveValueType } from '../core/PrimitiveValueType';

export interface IPlaygroundConfigState<T extends PrimitiveValueType> {
  label: string,
  description: string,
  disabled: boolean,
  value: WritableSignal<T>,
  selectOptions?: ISelectOption[],
  fieldType?: PrimitiveFieldTypeEnum,
  /** Explanation shown beneath the field when it is locked (disabled), telling the user why it cannot be changed. */
  hint?: string
}
