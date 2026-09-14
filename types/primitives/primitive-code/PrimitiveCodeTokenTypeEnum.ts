/**
 * The highlight category of a code token. Values are used as the `token-*` CSS class suffix.
 */
export enum PrimitiveCodeTokenTypeEnum {
  Plain = 'plain',
  Comment = 'comment',
  Keyword = 'keyword',
  Meta = 'meta',
  String = 'string',
  Number = 'number',
  Constant = 'constant',
  Variable = 'variable',
  Type = 'type',
  Function = 'function',
  Tag = 'tag',
  Selector = 'selector',
  Attribute = 'attribute',
  Property = 'property',
  Punctuation = 'punctuation',
  Operator = 'operator',
}
