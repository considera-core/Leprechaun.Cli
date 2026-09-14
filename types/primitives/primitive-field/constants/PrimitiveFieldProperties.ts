import { PropertyStateDescriptorType } from '../../../core/PropertyStateDescriptorType';
import { PrimitiveFieldDensityEnum } from '../enums/PrimitiveFieldDensityEnum';
import { PrimitiveFieldOperationEnum } from '../enums/PrimitiveFieldOperationEnum';
import { PrimitiveFieldTypeEnum } from '../enums/PrimitiveFieldTypeEnum';

/**
 * Every configurable input in template order. `text` inputs are the only ones that support localization.
 */
export const PrimitiveFieldProperties: PropertyStateDescriptorType[] = [
  { key: 'idSuffix', kind: 'text' },
  { key: 'description', kind: 'text' },
  { key: 'label', kind: 'text' },
  { key: 'code', kind: 'boolean' },
  { key: 'disabled', kind: 'boolean' },
  { key: 'invalid', kind: 'boolean' },
  { key: 'italic', kind: 'boolean' },
  { key: 'loading', kind: 'boolean' },
  { key: 'required', kind: 'boolean' },
  { key: 'showEmpty', kind: 'boolean' },
  { key: 'strong', kind: 'boolean' },
  { key: 'numberDecimals', kind: 'number' },
  { key: 'density', kind: 'enum', enumObject: PrimitiveFieldDensityEnum, enumName: 'PrimitiveFieldDensityEnum' },
  { key: 'fieldType', kind: 'enum', enumObject: PrimitiveFieldTypeEnum, enumName: 'PrimitiveFieldTypeEnum' },
  { key: 'fieldOperation', kind: 'enum', enumObject: PrimitiveFieldOperationEnum, enumName: 'PrimitiveFieldOperationEnum' },
  { key: 'selectOptions', kind: 'selectOptions' },
  { key: 'value', kind: 'text' },
];
