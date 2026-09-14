import { PrimitiveValueType } from '../core/PrimitiveValueType';
import { IPlaygroundConfigState } from './IPlaygroundConfigState';

export interface IPlaygroundConfigData {
  states: IPlaygroundConfigState<PrimitiveValueType>[];
}
