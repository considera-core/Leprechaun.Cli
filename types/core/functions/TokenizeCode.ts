import { PrimitiveCodeLanguageEnum } from '../../primitives/primitive-code/PrimitiveCodeLanguageEnum';
import { PrimitiveCodeTokenTypeEnum } from '../../primitives/primitive-code/PrimitiveCodeTokenTypeEnum';
import { IPrimitiveCodeToken } from '../../primitives/primitive-code/IPrimitiveCodeToken';

interface ICodeRule {
  pattern: RegExp;
  type: PrimitiveCodeTokenTypeEnum;
  // Skips the rule for member access (ex: `signal.set(...)` is not the `set` keyword).
  notAfterDot?: boolean;
}

const WHITESPACE_PATTERN = /\s+/y;

const COMMENT_PATTERN = /\/\/[^\n]*|\/\*[\s\S]*?(?:\*\/|$)/y;

const QUOTED_STRING_PATTERN = /'(?:\\.|[^\\'\n])*'?|"(?:\\.|[^\\"\n])*"?/y;

const TYPESCRIPT_KEYWORDS = [
  'abstract', 'as', 'async', 'await', 'break', 'case', 'catch', 'class', 'const', 'continue', 'declare',
  'default', 'delete', 'do', 'else', 'enum', 'export', 'extends', 'finally', 'for', 'from', 'function',
  'get', 'if', 'implements', 'import', 'in', 'infer', 'instanceof', 'interface', 'is', 'keyof', 'let',
  'namespace', 'new', 'of', 'override', 'private', 'protected', 'public', 'readonly', 'return',
  'satisfies', 'set', 'static', 'super', 'switch', 'throw', 'try', 'type', 'typeof', 'var', 'void',
  'while', 'yield',
];

const TYPESCRIPT_RULES: readonly ICodeRule[] = [
  { pattern: COMMENT_PATTERN, type: PrimitiveCodeTokenTypeEnum.Comment },
  { pattern: /`(?:\\[\s\S]|[^\\`])*`?/y, type: PrimitiveCodeTokenTypeEnum.String },
  { pattern: QUOTED_STRING_PATTERN, type: PrimitiveCodeTokenTypeEnum.String },
  { pattern: /@[A-Za-z_$][\w$]*/y, type: PrimitiveCodeTokenTypeEnum.Meta },
  { pattern: /(?:0[xXbBoO][\da-fA-F_]+|\d[\d_]*(?:\.\d[\d_]*)?(?:[eE][+-]?\d+)?)n?/y, type: PrimitiveCodeTokenTypeEnum.Number },
  { pattern: new RegExp(`(?:${TYPESCRIPT_KEYWORDS.join('|')})(?![\\w$])`, 'y'), type: PrimitiveCodeTokenTypeEnum.Keyword, notAfterDot: true },
  { pattern: /(?:true|false|null|undefined|this|NaN|Infinity)(?![\w$])/y, type: PrimitiveCodeTokenTypeEnum.Constant, notAfterDot: true },
  { pattern: /[A-Za-z_$][\w$]*(?=\s*(?:<[^<>()]*>)?\s*\()/y, type: PrimitiveCodeTokenTypeEnum.Function },
  { pattern: /[A-Z][\w$]*/y, type: PrimitiveCodeTokenTypeEnum.Type },
  { pattern: /[A-Za-z_$][\w$]*/y, type: PrimitiveCodeTokenTypeEnum.Plain },
  { pattern: /[{}()[\];,.]/y, type: PrimitiveCodeTokenTypeEnum.Punctuation },
  { pattern: /[=+\-*\/%!&|^~?:<>]+/y, type: PrimitiveCodeTokenTypeEnum.Operator },
  { pattern: WHITESPACE_PATTERN, type: PrimitiveCodeTokenTypeEnum.Plain },
];

const HTML_TAG_OPEN_PATTERN = /(<\/?)([A-Za-z][\w:.-]*)/y;

const HTML_TAG_CLOSE_PATTERN = /\/?>/y;

const HTML_ATTRIBUTE_NAME_PATTERN = /[^\s"'<>\/=]+/y;

const HTML_ATTRIBUTE_VALUE_PATTERN = /(["'])([\s\S]*?)(\1|$)/y;

// Angular control flow and @let blocks (ex: `@if (...) {`, `@else if (...) {`, `@let value = ...;`).
const HTML_BLOCK_PATTERN = /@(?:else\s+if|[A-Za-z]+)/y;

// Attributes whose values are Angular expressions rather than plain strings.
const HTML_BINDING_ATTRIBUTE_PATTERN = /^(?:\[|\(|\*|bind-|on-)/;

const HTML_TEXT_RULES: readonly ICodeRule[] = [
  { pattern: /&(?:#\d+|#x[\da-fA-F]+|[A-Za-z]+);/y, type: PrimitiveCodeTokenTypeEnum.Constant },
  { pattern: /[{}]/y, type: PrimitiveCodeTokenTypeEnum.Punctuation },
  { pattern: /[^<@{}&]+/y, type: PrimitiveCodeTokenTypeEnum.Plain },
];

const SCSS_SHARED_RULES: readonly ICodeRule[] = [
  { pattern: COMMENT_PATTERN, type: PrimitiveCodeTokenTypeEnum.Comment },
  { pattern: QUOTED_STRING_PATTERN, type: PrimitiveCodeTokenTypeEnum.String },
  { pattern: WHITESPACE_PATTERN, type: PrimitiveCodeTokenTypeEnum.Plain },
];

// A declaration name is followed by a colon and ends in `;` or `}` before any `{`, which separates
// `color: red;` from selectors such as `a:hover {`.
const SCSS_PROPERTY_PATTERN = /(?:--|\$|-)?[A-Za-z_][\w-]*(?=\s*:[^{};]*(?:[;}]|$))/y;

const SCSS_AT_RULE_PATTERN = /@[\w-]+/y;

const SCSS_NUMBER_PATTERN = /-?(?:\d*\.)?\d+(?:[A-Za-z%]+)?/y;

const SCSS_SELECTOR_RULES: readonly ICodeRule[] = [
  { pattern: /[.#%][A-Za-z_-][\w-]*/y, type: PrimitiveCodeTokenTypeEnum.Selector },
  { pattern: /::?[A-Za-z-]+/y, type: PrimitiveCodeTokenTypeEnum.Selector },
  { pattern: /\[[^\]\n]*\]?/y, type: PrimitiveCodeTokenTypeEnum.Attribute },
  { pattern: /&/y, type: PrimitiveCodeTokenTypeEnum.Operator },
  { pattern: SCSS_NUMBER_PATTERN, type: PrimitiveCodeTokenTypeEnum.Number },
  { pattern: /[A-Za-z][\w-]*/y, type: PrimitiveCodeTokenTypeEnum.Tag },
  { pattern: /[(),>+~*]/y, type: PrimitiveCodeTokenTypeEnum.Punctuation },
];

const SCSS_VALUE_RULES: readonly ICodeRule[] = [
  { pattern: /\$[\w-]+|--[\w-]+/y, type: PrimitiveCodeTokenTypeEnum.Variable },
  { pattern: /#[\da-fA-F]{3,8}(?![\w-])/y, type: PrimitiveCodeTokenTypeEnum.Number },
  { pattern: /!(?:important|default|global|optional)/y, type: PrimitiveCodeTokenTypeEnum.Keyword },
  { pattern: SCSS_NUMBER_PATTERN, type: PrimitiveCodeTokenTypeEnum.Number },
  { pattern: /-*[A-Za-z_][\w.-]*(?=\()/y, type: PrimitiveCodeTokenTypeEnum.Function },
  { pattern: /-*[A-Za-z_][\w.-]*/y, type: PrimitiveCodeTokenTypeEnum.Constant },
  { pattern: /[(),:]/y, type: PrimitiveCodeTokenTypeEnum.Punctuation },
  { pattern: /[+*\/%=<>!-]+/y, type: PrimitiveCodeTokenTypeEnum.Operator },
];

/**
 * Splits code into highlight tokens. Joining every token's text returns the original value (with line endings
 * normalized to `\n`).
 */
export function TokenizeCode(value: string, language: PrimitiveCodeLanguageEnum): IPrimitiveCodeToken[] {
  const normalizedValue = `${value ?? ''}`.replace(/\r\n?/g, '\n');

  switch (language) {
    case PrimitiveCodeLanguageEnum.Html:
      return tokenizeHtml(normalizedValue);
    case PrimitiveCodeLanguageEnum.Scss:
      return tokenizeScss(normalizedValue);
    case PrimitiveCodeLanguageEnum.TypeScript:
      return scan(normalizedValue, TYPESCRIPT_RULES);
    default:
      return normalizedValue ? [{ type: PrimitiveCodeTokenTypeEnum.Plain, text: normalizedValue }] : [];
  }
}

/**
 * Tokenizes code and splits the tokens into lines. Always returns at least one (possibly empty) line.
 */
export function TokenizeCodeLines(value: string, language: PrimitiveCodeLanguageEnum): IPrimitiveCodeToken[][] {
  const lines: IPrimitiveCodeToken[][] = [[]];

  for (const token of TokenizeCode(value, language)) {
    token.text.split('\n').forEach((text, index) => {
      if (index > 0) {
        lines.push([]);
      }

      if (text) {
        lines[lines.length - 1].push({ type: token.type, text });
      }
    });
  }

  return lines;
}

function tokenizeHtml(value: string): IPrimitiveCodeToken[] {
  const tokens: IPrimitiveCodeToken[] = [];
  let index = 0;

  while (index < value.length) {
    if (value.startsWith('<!--', index)) {
      const end = value.indexOf('-->', index + 4);
      const stop = end < 0 ? value.length : end + 3;
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Comment, value.slice(index, stop));
      index = stop;
      continue;
    }

    const tag = execAt(HTML_TAG_OPEN_PATTERN, value, index);
    if (tag) {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Punctuation, tag[1]);
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Tag, tag[2]);
      index = tokenizeHtmlTagBody(value, index + tag[0].length, tokens);
      continue;
    }

    if (value.startsWith('{{', index)) {
      const end = value.indexOf('}}', index + 2);
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Punctuation, '{{');
      pushTokens(tokens, scan(value.slice(index + 2, end < 0 ? value.length : end), TYPESCRIPT_RULES));
      if (end >= 0) {
        pushToken(tokens, PrimitiveCodeTokenTypeEnum.Punctuation, '}}');
      }
      index = end < 0 ? value.length : end + 2;
      continue;
    }

    const block = execAt(HTML_BLOCK_PATTERN, value, index);
    if (block) {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Keyword, block[0]);
      index = tokenizeHtmlBlockParameters(value, index + block[0].length, tokens, block[0]);
      continue;
    }

    const token = matchRule(value, index, HTML_TEXT_RULES);
    pushToken(tokens, token.type, token.text);
    index += token.text.length;
  }

  return tokens;
}

/**
 * Tokenizes the attributes of an opened tag and returns the index after the closing `>`.
 */
function tokenizeHtmlTagBody(value: string, index: number, tokens: IPrimitiveCodeToken[]): number {
  let attributeName = '';

  while (index < value.length) {
    const close = execAt(HTML_TAG_CLOSE_PATTERN, value, index);
    if (close) {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Punctuation, close[0]);
      return index + close[0].length;
    }

    const whitespace = execAt(WHITESPACE_PATTERN, value, index);
    if (whitespace) {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Plain, whitespace[0]);
      index += whitespace[0].length;
      continue;
    }

    const name = execAt(HTML_ATTRIBUTE_NAME_PATTERN, value, index);
    if (name) {
      attributeName = name[0];
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Attribute, name[0]);
      index += name[0].length;
      continue;
    }

    if (value[index] === '=') {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Operator, '=');
      index++;
      continue;
    }

    const attributeValue = execAt(HTML_ATTRIBUTE_VALUE_PATTERN, value, index);
    if (attributeValue) {
      if (HTML_BINDING_ATTRIBUTE_PATTERN.test(attributeName)) {
        pushToken(tokens, PrimitiveCodeTokenTypeEnum.String, attributeValue[1]);
        pushTokens(tokens, scan(attributeValue[2], TYPESCRIPT_RULES));
        pushToken(tokens, PrimitiveCodeTokenTypeEnum.String, attributeValue[3]);
      } else {
        pushToken(tokens, PrimitiveCodeTokenTypeEnum.String, attributeValue[0]);
      }
      index += attributeValue[0].length;
      continue;
    }

    pushToken(tokens, PrimitiveCodeTokenTypeEnum.Plain, value[index]);
    index++;
  }

  return index;
}

/**
 * Tokenizes the expression that follows a control flow block keyword and returns the index after it.
 */
function tokenizeHtmlBlockParameters(value: string, index: number, tokens: IPrimitiveCodeToken[], keyword: string): number {
  if (keyword === '@let') {
    const end = value.indexOf(';', index);
    const stop = end < 0 ? value.length : end + 1;
    pushTokens(tokens, scan(value.slice(index, stop), TYPESCRIPT_RULES));
    return stop;
  }

  const whitespace = execAt(WHITESPACE_PATTERN, value, index);
  const start = index + (whitespace ? whitespace[0].length : 0);

  if (value[start] !== '(') {
    return index;
  }

  const stop = findClosingParenthesis(value, start);
  pushTokens(tokens, scan(value.slice(index, stop), TYPESCRIPT_RULES));
  return stop;
}

function findClosingParenthesis(value: string, start: number): number {
  let depth = 0;

  for (let index = start; index < value.length; index++) {
    if (value[index] === '(') {
      depth++;
    } else if (value[index] === ')') {
      depth--;
      if (depth === 0) {
        return index + 1;
      }
    }
  }

  return value.length;
}

function tokenizeScss(value: string): IPrimitiveCodeToken[] {
  const tokens: IPrimitiveCodeToken[] = [];
  let index = 0;
  let inValue = false;
  let expectColon = false;

  while (index < value.length) {
    const character = value[index];

    const shared = findRule(value, index, SCSS_SHARED_RULES);
    if (shared) {
      pushToken(tokens, shared.type, shared.text);
      index += shared.text.length;
      continue;
    }

    if (character === '{' || character === '}' || character === ';') {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Punctuation, character);
      inValue = false;
      expectColon = false;
      index++;
      continue;
    }

    if (expectColon && character === ':') {
      pushToken(tokens, PrimitiveCodeTokenTypeEnum.Punctuation, character);
      inValue = true;
      expectColon = false;
      index++;
      continue;
    }

    let token: IPrimitiveCodeToken;

    if (inValue) {
      token = matchRule(value, index, SCSS_VALUE_RULES);
    } else {
      const property = execAt(SCSS_PROPERTY_PATTERN, value, index);
      const atRule = execAt(SCSS_AT_RULE_PATTERN, value, index);

      if (property) {
        const isVariable = property[0].startsWith('$') || property[0].startsWith('--');
        token = { type: isVariable ? PrimitiveCodeTokenTypeEnum.Variable : PrimitiveCodeTokenTypeEnum.Property, text: property[0] };
        expectColon = true;
      } else if (atRule) {
        // Everything after an at-rule up to `{` or `;` reads like a value (ex: `@include name;`, `@media (...)`).
        token = { type: PrimitiveCodeTokenTypeEnum.Meta, text: atRule[0] };
        inValue = true;
      } else {
        token = matchRule(value, index, SCSS_SELECTOR_RULES);
      }
    }

    pushToken(tokens, token.type, token.text);
    index += token.text.length;
  }

  return tokens;
}

function scan(value: string, rules: readonly ICodeRule[]): IPrimitiveCodeToken[] {
  const tokens: IPrimitiveCodeToken[] = [];
  let index = 0;

  while (index < value.length) {
    const token = matchRule(value, index, rules);
    pushToken(tokens, token.type, token.text);
    index += token.text.length;
  }

  return tokens;
}

/**
 * Returns the first rule match at the index, falling back to a single plain character so scanning always advances.
 */
function matchRule(value: string, index: number, rules: readonly ICodeRule[]): IPrimitiveCodeToken {
  return findRule(value, index, rules) ?? { type: PrimitiveCodeTokenTypeEnum.Plain, text: value[index] };
}

function findRule(value: string, index: number, rules: readonly ICodeRule[]): IPrimitiveCodeToken | undefined {
  for (const rule of rules) {
    if (rule.notAfterDot && value[index - 1] === '.') {
      continue;
    }

    const match = execAt(rule.pattern, value, index);
    if (match && match[0].length > 0) {
      return { type: rule.type, text: match[0] };
    }
  }

  return undefined;
}

function execAt(pattern: RegExp, value: string, index: number): RegExpExecArray | null {
  pattern.lastIndex = index;
  return pattern.exec(value);
}

/**
 * Appends a token, merging it into the previous token when both share a type to keep the rendered span count low.
 */
function pushToken(tokens: IPrimitiveCodeToken[], type: PrimitiveCodeTokenTypeEnum, text: string): void {
  if (!text) {
    return;
  }

  const last = tokens[tokens.length - 1];
  if (last && last.type === type) {
    tokens[tokens.length - 1] = { type, text: last.text + text };
    return;
  }

  tokens.push({ type, text });
}

function pushTokens(tokens: IPrimitiveCodeToken[], additions: IPrimitiveCodeToken[]): void {
  additions.forEach(token => pushToken(tokens, token.type, token.text));
}
