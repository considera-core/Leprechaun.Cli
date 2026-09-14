import type { ISelectOption } from '@tylertech/forge';
import type { PrimitiveFieldDensityEnum } from '../enums/PrimitiveFieldDensityEnum';
import type { PrimitiveFieldOperationEnum } from '../enums/PrimitiveFieldOperationEnum';
import type { PrimitiveFieldTypeEnum } from '../enums/PrimitiveFieldTypeEnum';
import { BaseValuesDataType } from './PrimitiveFieldStateType';

export interface IPrimitiveFieldData extends BaseValuesDataType {
  idSuffix: string;
  description: string;
  label: string;
  code: boolean;
  disabled: boolean;
  invalid: boolean;
  italic: boolean;
  loading: boolean;
  required: boolean;
  showEmpty: boolean;
  strong: boolean;
  numberDecimals: number;
  density: PrimitiveFieldDensityEnum;
  fieldType: PrimitiveFieldTypeEnum;
  fieldOperation: PrimitiveFieldOperationEnum;
  selectOptions: ISelectOption[];
  value: string;
}

