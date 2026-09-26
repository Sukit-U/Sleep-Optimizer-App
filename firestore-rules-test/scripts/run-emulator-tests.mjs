// Runs the rules tests inside the Firestore emulator.
//
// The Firestore emulator requires Java 11+ (firebase-tools requires 21+). On
// this machine the only JDK 21 is the one bundled with Android Studio, so we
// default JAVA_HOME to it and put it on PATH ahead of any older system Java.
// Override by exporting JAVA_HOME before running.
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const pkgDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const env = { ...process.env };
if (!env.JAVA_HOME) {
  env.JAVA_HOME = 'C:\\Program Files\\Android\\Android Studio\\jbr';
}
env.PATH = `${path.join(env.JAVA_HOME, 'bin')}${path.delimiter}${env.PATH ?? ''}`;

const result = spawnSync(
  'npx',
  [
    'firebase',
    'emulators:exec',
    '--only', 'firestore',
    '--project', 'rules-test',
    // Quoted so the Windows shell joining keeps it as one CLI argument.
    // Runs the suite directly — NOT `npm test`, which would re-invoke this
    // runner inside the emulator and recursively spawn a second emulator
    // that collides with this one's ports.
    '"node --test --test-reporter=spec firestore.rules.test.mjs"',
  ],
  { stdio: 'inherit', env, shell: true, cwd: pkgDir },
);

process.exit(result.status ?? 1);
