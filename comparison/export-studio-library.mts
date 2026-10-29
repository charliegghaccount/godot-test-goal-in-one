// Regenerate the regression fixture through the original Studio tools, not copied approximations.
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { writeFileSync } from 'node:fs';
const source = process.env.REFERENCE_REPO || '/workspace/goal-in-one-test';
const { blank } = await import(pathToFileURL(resolve(source, 'src/editor/model.ts')).href);
const { add } = await import(pathToFileURL(resolve(source, 'src/editor/objects.ts')).href);
const draft = blank('rectangle');
draft.draftId = 'v7-studio-library';
draft.level.name = 'Original Studio object library';
for (const [tool, x, y] of [['rotor',350,330],['swing',650,350],['breakable',820,500],['ice',400,640],['wind',1020,360],['spring',200,640],['timed-gate',1080,570]]) {
  add(draft.level, tool, { x, y });
}
writeFileSync('tests/fixtures/studio-library.json', JSON.stringify(draft, null, 2));
