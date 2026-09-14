import { PropertyStateDescriptorType } from '../../../core/PropertyStateDescriptorType';
import { IPrimitiveFieldData } from '../interfaces/IPrimitiveFieldData';
import { BaseValuesDataType, BaseValuesStateType, PrimitiveFieldStateType } from '../interfaces/PrimitiveFieldStateType';
import { GetBooleanAttributeHtml } from './GetBooleanAttributeHtml';
import { GetNumberAttributeHtml } from './GetNumberAttributeHtml';
import { GetBindingAttributeHtml } from '../../../core/functions/GetBindingAttributeHtml';
import { GetEnumExpression, GetPropertyEnumExpression } from '../../../core/functions/GetPropertyEnumExpression';
import { GetSelectOptionsLiteral } from '../../../core/functions/GetSelectOptionsLiteral';
import { ISelectOption } from '@tylertech/forge';
import { GetTextAttributeHtml } from './GetTextAttributeHtml';

/**
 * Writes the literal template attribute for a static input based on its kind.
 */
export function GetPrimitiveFieldStaticAttribute(
  property: PropertyStateDescriptorType,
  valuesData: IPrimitiveFieldData,
  valuesState: PrimitiveFieldStateType<string>
): string {
  return GetStaticAttribute(property, valuesData as Record<string, any>, valuesState);
}

/**
 * Writes the literal template attribute for a static input based on its kind.
 */
export function GetStaticAttribute(
  property: PropertyStateDescriptorType,
  valuesData: BaseValuesDataType,
  valuesState: BaseValuesStateType<string>
): string {
  const value = valuesData[property.key];
  const valueType = typeof value;
  const enumName = property.enumName;
  const enumObject = property.enumObject;

  if (valueType === 'undefined') {
    throw new Error(`Value (${value} or ${valuesState[property.key]()}) for key "${property.key}" is undefined.`);
  }

  switch (property.kind) {
    case 'text':
      return GetTextAttributeHtml(property.key, value as string);
    case 'boolean':
      return valueType === 'boolean'
        ? GetBooleanAttributeHtml(property.key, value as boolean)
        : GetTextAttributeHtml(property.key, value as string);
    case 'number':
      return GetNumberAttributeHtml(property.key, value as number);
    case 'enum':
      return !!enumName && !!enumObject
        ? GetBindingAttributeHtml(property.key, GetEnumExpression(enumName, enumObject, value))
        : GetTextAttributeHtml(property.key, value as string);
    case 'selectOptions':
      return GetBindingAttributeHtml(property.key, GetSelectOptionsLiteral(valuesData[property.key] as ISelectOption[]));
  }
}
