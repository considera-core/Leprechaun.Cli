import { PropertyStateDescriptorType } from '../../../core/PropertyStateDescriptorType';
import { BaseValuesDataType, PrimitiveFieldStateType } from '../interfaces/PrimitiveFieldStateType';
import { IsSignalTrue } from '../../../core/functions/IsSignalTrue';
import { IPrimitiveFieldPlaygroundToggleState } from '../interfaces/IPrimitiveFieldPlaygroundToggleState';
import { GetStaticAttribute } from './GetPrimitiveFieldStaticAttribute';

export function GetPropertyAttributes(
  property: PropertyStateDescriptorType,
  valuesData: BaseValuesDataType,
  valuesState: PrimitiveFieldStateType<string>,
  includeState: PrimitiveFieldStateType<boolean>,
  dynamicState: PrimitiveFieldStateType<boolean>,
  localizationState: PrimitiveFieldStateType<boolean>,
): string[] {
  if (!IsSignalTrue(includeState[property.key as keyof IPrimitiveFieldPlaygroundToggleState])) {
    return [];
  }

  if (IsSignalTrue(dynamicState[property.key as keyof IPrimitiveFieldPlaygroundToggleState])) {
    return [`[${property.key}]="${property.key}()"`];
  }

  const parts: string[] = [];
  if (property.kind === 'text' && IsSignalTrue(localizationState[property.key as keyof IPrimitiveFieldPlaygroundToggleState])) {
    parts.push(`i18n-${property.key}`);
  }
  parts.push(GetStaticAttribute(property, valuesData, valuesState));
  return parts;
}
