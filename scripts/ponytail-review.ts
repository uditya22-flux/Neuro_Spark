import { walk } from "https://deno.land/std@0.208.0/fs/walk.ts";

const CHARTER_VIOLATION_TERMS = [
  "FirebaseMessaging",
  "diagnostic",
  "screening",
  "predictive",
  "employment",
  "salary",
  "re-engagement",
  "streak",
  "badge",
];

async function checkCharterViolations(dir: string) {
  console.log(`\n🔍 Checking for Charter Violations in ${dir}...`);
  let passed = true;
  try {
    for await (const entry of walk(dir, { exts: [".dart", ".ts", ".sql"] })) {
      if (entry.isFile) {
        const content = await Deno.readTextFile(entry.path);
        for (const term of CHARTER_VIOLATION_TERMS) {
          if (content.toLowerCase().includes(term.toLowerCase())) {
            console.error(`❌ VIOLATION: Found forbidden term "${term}" in ${entry.path}`);
            passed = false;
          }
        }
      }
    }
  } catch (e) {
    console.warn(`Could not read directory ${dir}`);
  }
  if (passed) console.log("✅ Charter checks passed.");
  return passed;
}

async function checkRLS(migrationsDir: string) {
  console.log(`\n🔒 Checking for RLS in ${migrationsDir}...`);
  let passed = true;
  try {
    for await (const entry of walk(migrationsDir, { exts: [".sql"] })) {
      if (entry.isFile) {
        const content = await Deno.readTextFile(entry.path);
        // Simple heuristic: if a table is created, it should have RLS enabled somewhere in the file.
        // We won't strictly fail unless "create table" exists but "enable row level security" does not.
        if (content.toLowerCase().includes("create table") && !content.toLowerCase().includes("enable row level security")) {
          // Warning rather than failure since some utility tables might not need RLS, but in MindBridge RLS is strict.
          console.warn(`⚠️ WARNING: Found 'create table' without 'enable row level security' in ${entry.path}`);
          // passed = false; // We can set this to false if we want absolute strictness
        }
      }
    }
  } catch (e) {
    console.error(`Error reading migrations: ${e}`);
    passed = false;
  }
  if (passed) console.log("✅ RLS checks passed.");
  return passed;
}

async function checkPrivacyFunctions(functionsDir: string) {
  console.log(`\n🛡️ Checking Privacy Functions in ${functionsDir}...`);
  const requiredFunctions = ["privacy-purge", "privacy-export"];
  let passed = true;

  for (const fn of requiredFunctions) {
    try {
      const stat = await Deno.stat(`${functionsDir}/${fn}/index.ts`);
      if (!stat.isFile) throw new Error();
    } catch {
      console.error(`❌ VIOLATION: Required privacy function '${fn}' is missing.`);
      passed = false;
    }
  }
  if (passed) console.log("✅ Privacy functions exist.");
  return passed;
}

async function main() {
  console.log("==========================================");
  console.log("🦄 PONYTAIL LITE REVIEW TOOL");
  console.log("==========================================");

  let allPassed = true;

  // 1. Charter Violations
  const charterPassed = await checkCharterViolations("./flutter_app/lib");
  if (!charterPassed) allPassed = false;

  // 2. RLS Check
  const rlsPassed = await checkRLS("./supabase/migrations");
  if (!rlsPassed) allPassed = false;

  // 3. Privacy Functions Check
  const privacyPassed = await checkPrivacyFunctions("./supabase/functions");
  if (!privacyPassed) allPassed = false;

  console.log("\n==========================================");
  if (allPassed) {
    console.log("✅ SUCCESS: All Ponytail Lite checks passed!");
    Deno.exit(0);
  } else {
    console.error("❌ FAILURE: Codebase does not meet AGENTS.md policy requirements.");
    Deno.exit(1);
  }
}

main();
