import { BaseValuesDataType, BaseValuesStateType } from '../../primitives/primitive-field/interfaces/PrimitiveFieldStateType';
import { PropertyStateDescriptorType } from '../PropertyStateDescriptorType';
import { ConvertStringToSelectOptions } from './ConvertStringToSelectOptions';

export function ConvertStateToData(
  state: BaseValuesStateType<string>,
  properties: PropertyStateDescriptorType[],
): BaseValuesDataType {
  return properties.reduce((acc, prop) => {
    const value = state[prop.key]();
    const enumObject = prop.enumObject;
    switch (prop.kind) {
      case 'enum':
        acc[prop.key] = value as typeof enumObject[keyof typeof enumObject];
        break;
      case 'number':
        acc[prop.key] = Number(value) || 0;
        break;
      case 'boolean':
        acc[prop.key] = value === 'true';
        break;
      case 'selectOptions':
        acc[prop.key] = ConvertStringToSelectOptions(value);
        break;
      default:
        acc[prop.key] = value;
    }
    return acc;
  }, {} as BaseValuesDataType);
}
