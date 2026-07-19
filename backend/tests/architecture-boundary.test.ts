import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';

const source = (relative: string) => readFileSync(resolve(process.cwd(), relative), 'utf8');

describe('child and guardian data boundary', () => {
  it('keeps the child DTO and child play route independent from adult field notes', () => {
    expect(source('src/domain/childExperience.ts')).not.toContain('adultExploratoryNote');
    expect(source('src/routes/deepening.ts')).not.toContain('adultExploratoryNote');
    expect(source('src/domain/adultExploratoryNote.ts')).not.toContain('childExperience');
  });
});
