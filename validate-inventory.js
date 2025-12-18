#!/usr/bin/env node

const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const fs = require('fs');

// Load schema and data
const schema = JSON.parse(fs.readFileSync('/workspace/docs/repo-keeper/schemas/inventory.schema.json', 'utf8'));
const inventory = JSON.parse(fs.readFileSync('/workspace/docs/repo-keeper/INVENTORY.json', 'utf8'));

// Create validator
const ajv = new Ajv({ allErrors: true, verbose: true });
addFormats(ajv);

// Validate
const validate = ajv.compile(schema);
const valid = validate(inventory);

if (valid) {
  console.log('\n✓ VALIDATION SUCCESSFUL');
  console.log('The INVENTORY.json is valid according to the schema.\n');
  process.exit(0);
} else {
  console.log('\n✗ VALIDATION FAILED');
  console.log('Errors found:\n');
  validate.errors.forEach((err, i) => {
    console.log(`${i + 1}. ${err.instancePath || '/'}`);
    console.log(`   ${err.message}`);
    if (err.params) {
      console.log(`   Params:`, JSON.stringify(err.params, null, 2));
    }
    console.log();
  });
  process.exit(1);
}
