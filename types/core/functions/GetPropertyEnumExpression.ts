import { WritableSignal } from '@angular/core';
import { PropertyStateDescriptorType } from '../PropertyStateDescriptorType';
import { GetEnumKey } from './GetEnumKey';

/**
 * Resolves an enum input to its qualified member reference (ex: `PrimitiveFieldDensityEnum.Default`). Reads the
 * raw state value because it holds the enum value (`'default'`), not the member name.
 */
export function GetPropertyEnumExpression<TInterface extends object>(
  property: PropertyStateDescriptorType,
  valuesState: TInterface & Record<string, WritableSignal<string>>
): string {
  return `${property.enumName}.${GetEnumKey(property.enumObject ?? {}, valuesState[property.key]())}`;
}


export function GetEnumExpression(
  enumName: string,
  enumObject: object,
  enumValue: string | number
): string {
  return `${enumName}.${GetEnumKey(enumObject ?? {}, enumValue)}`;
}
