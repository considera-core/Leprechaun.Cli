import { BaseValuesStateType } from '../primitives/primitive-field/interfaces/PrimitiveFieldStateType';

export type PropertyStateDescriptorType = {
  key: string;
  kind: 'text' | 'boolean' | 'number' | 'enum' | 'selectOptions';
  enumObject?: object;
  enumName?: string;
}
