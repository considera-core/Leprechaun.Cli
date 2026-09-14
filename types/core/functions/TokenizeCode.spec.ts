import { PrimitiveCodeLanguageEnum } from '../../primitives/primitive-code/PrimitiveCodeLanguageEnum';
import { PrimitiveCodeTokenTypeEnum } from '../../primitives/primitive-code/PrimitiveCodeTokenTypeEnum';
import { IPrimitiveCodeToken } from '../../primitives/primitive-code/IPrimitiveCodeToken';
import { TokenizeCode, TokenizeCodeLines } from './TokenizeCode';

const TYPESCRIPT_SAMPLE = `import { Component, signal } from '@angular/core';

// A comment
@Component({ selector: 'app-example' })
export class ExampleComponent {
  protected readonly count = signal<number>(1.5);
  /* block
     comment */
  protected increment(): void { this.count.set(this.count() + 1); }
}`;

const HTML_SAMPLE = `<!-- A comment -->
@if (loading()) {
  <forge-skeleton text />
} @else {
  <consideracore-primitive-field
    idSuffix="demo"
    [code]="false"
    (valueChange)="onChange($event)" />
}
@let Value = value();
<span>{{ Value }} &amp; more</span>`;

const SCSS_SAMPLE = `@use '@tylertech/forge/sass/theme/theme-dark';

// A comment
:host {
  display: block;
  --custom-size: 1rem;
}

.global-island forge-toolbar[no-border]:not([inverted]) {
  border: solid 0.0625rem var(--forge-theme-outline);
  color: #fff !important;
}`;

function textsOfType(tokens: IPrimitiveCodeToken[], type: PrimitiveCodeTokenTypeEnum): string[] {
  return tokens.filter(token => token.type === type).map(token => token.text);
}

describe('TokenizeCode', () => {
  it('should keep the original text for every language', () => {
    const samples: [string, PrimitiveCodeLanguageEnum][] = [
      [TYPESCRIPT_SAMPLE, PrimitiveCodeLanguageEnum.TypeScript],
      [HTML_SAMPLE, PrimitiveCodeLanguageEnum.Html],
      [SCSS_SAMPLE, PrimitiveCodeLanguageEnum.Scss],
      [TYPESCRIPT_SAMPLE, PrimitiveCodeLanguageEnum.PlainText],
    ];

    samples.forEach(([sample, language]) => {
      expect(TokenizeCode(sample, language).map(token => token.text).join('')).toBe(sample);
    });
  });

  it('should normalize line endings', () => {
    expect(TokenizeCode('a\r\nb\rc', PrimitiveCodeLanguageEnum.PlainText)[0].text).toBe('a\nb\nc');
  });

  it('should highlight typescript', () => {
    const tokens = TokenizeCode(TYPESCRIPT_SAMPLE, PrimitiveCodeLanguageEnum.TypeScript);

    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.String)).toContain(`'@angular/core'`);
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Meta)).toContain('@Component');
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Type)).toContain('ExampleComponent');
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Function)).toEqual(expect.arrayContaining(['signal', 'increment', 'count']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Number)).toEqual(expect.arrayContaining(['1.5', '1']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Comment).join('')).toContain('/* block\n     comment */');
    // `set` after a dot is a method call, not the keyword.
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Function)).toContain('set');
  });

  it('should highlight angular html', () => {
    const tokens = TokenizeCode(HTML_SAMPLE, PrimitiveCodeLanguageEnum.Html);

    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Comment)).toContain('<!-- A comment -->');
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Keyword)).toEqual(expect.arrayContaining(['@if', '@else', '@let']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Tag)).toEqual(expect.arrayContaining(['forge-skeleton', 'consideracore-primitive-field', 'span']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Attribute)).toEqual(expect.arrayContaining(['id', '[code]', '(valueChange)']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.String)).toContain('"demo"');
    // Binding values are highlighted as expressions.
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Constant)).toEqual(expect.arrayContaining(['false', '&amp;']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Function)).toEqual(expect.arrayContaining(['loading', 'onChange', 'value']));
  });

  it('should highlight scss', () => {
    const tokens = TokenizeCode(SCSS_SAMPLE, PrimitiveCodeLanguageEnum.Scss);

    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Meta)).toContain('@use');
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Property)).toEqual(expect.arrayContaining(['display', 'border', 'color']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Variable)).toEqual(expect.arrayContaining(['--custom-size', '--forge-theme-outline']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Selector)).toEqual(expect.arrayContaining([':host', '.global-island', ':not']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Tag)).toContain('forge-toolbar');
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Attribute)).toEqual(expect.arrayContaining(['[no-border]', '[inverted]']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Number)).toEqual(expect.arrayContaining(['1rem', '0.0625rem', '#fff']));
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Function)).toContain('var');
    expect(textsOfType(tokens, PrimitiveCodeTokenTypeEnum.Keyword)).toContain('!important');
  });
});

describe('TokenizeCodeLines', () => {
  it('should split multi-line tokens into lines', () => {
    const lines = TokenizeCodeLines('/* a\nb */\nconst c = 1;\n', PrimitiveCodeLanguageEnum.TypeScript);

    expect(lines.length).toBe(4);
    expect(lines[0]).toEqual([{ type: PrimitiveCodeTokenTypeEnum.Comment, text: '/* a' }]);
    expect(lines[1]).toEqual([{ type: PrimitiveCodeTokenTypeEnum.Comment, text: 'b */' }]);
    expect(lines[3]).toEqual([]);
  });

  it('should return a single empty line for an empty value', () => {
    expect(TokenizeCodeLines('', PrimitiveCodeLanguageEnum.Html)).toEqual([[]]);
  });
});
