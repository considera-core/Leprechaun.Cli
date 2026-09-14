import type { PrimitiveCodeTokenTypeEnum } from './PrimitiveCodeTokenTypeEnum';

export interface IPrimitiveCodeToken {
  type: PrimitiveCodeTokenTypeEnum;
  text: string;
}
