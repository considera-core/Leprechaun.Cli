import { PrimitiveCodeLanguageEnum } from '../../primitives/primitive-code/PrimitiveCodeLanguageEnum';

export function GetCodeLanguageLabel(language: PrimitiveCodeLanguageEnum): string {
  switch (language) {
    case PrimitiveCodeLanguageEnum.Html:
      return 'HTML';
    case PrimitiveCodeLanguageEnum.Scss:
      return 'SCSS';
    case PrimitiveCodeLanguageEnum.TypeScript:
      return 'TypeScript';
    default:
      return 'Plain text';
  }
}
