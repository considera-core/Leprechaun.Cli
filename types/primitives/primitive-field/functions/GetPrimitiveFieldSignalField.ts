import { PropertyStateDescriptorType } from '../../../core/PropertyStateDescriptorType';
import { IPrimitiveFieldData } from '../interfaces/IPrimitiveFieldData';
import { GetStringLiteral } from '../../../core/functions/GetStringLiteral';
import { GetEnumExpression, GetPropertyEnumExpression } from '../../../core/functions/GetPropertyEnumExpression';
import { GetSelectOptionsLiteral } from '../../../core/functions/GetSelectOptionsLiteral';
import { ISelectOption } from '@tylertech/forge';
import { PrimitiveFieldStateType } from '../interfaces/PrimitiveFieldStateType';

/**
 * Writes the backing signal field for a dynamic input, initialized to its current value.
 */
export function GetPrimitiveFieldSignalField(property: PropertyStateDescriptorType, valuesData: IPrimitiveFieldData, valuesState: PrimitiveFieldStateType<string>): string {
  switch (property.kind) {
    case 'text':
      return `  protected readonly ${property.key} = signal<string>(${GetStringLiteral(valuesData[property.key] as string)});`;
    case 'boolean':
      return `  protected readonly ${property.key} = signal<boolean>(${valuesData[property.key]});`;
    case 'number':
      return `  protected readonly ${property.key} = signal<number>(${valuesData[property.key]});`;
    case 'enum':
      return property.enumName && property.enumObject ?
        `  protected readonly ${property.key} = signal<${property.enumName}>(${GetEnumExpression(property.enumName, property.enumObject, valuesData[property.key])});`
        : '';
    case 'selectOptions':
      return `  protected readonly ${property.key} = signal<ISelectOption[]>(${GetSelectOptionsLiteral(valuesData[property.key] as ISelectOption[])});`;
  }
}
