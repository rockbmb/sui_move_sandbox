import { execSync } from 'child_process';
import { readFileSync } from 'fs';
import { homedir } from 'os';
import path from 'path';
import { fileURLToPath } from 'node:url';

import {
    Ed25519Keypair,
    JsonRpcProvider,
    RawSigner,
    TransactionBlock,
    UpgradePolicy,
    fromB64,
    devnetConnection,
} from '@mysten/sui.js';

const SUI = 'sui';
const POLICY_PACKAGE_ID = '0x911a11d99dfe9dc4bec24bfb669636445a68c2763f67b902dee03cfa1557a8c1';
//const EXAMPLE_PACKAGE_ID = '0xe64132e8abe9d5520ecde5088d9d6c7637e7b462505b87c18fb3ffab04858cd0';
const EXAMPLE_PACKAGE_ID = '0x1e8ff98c804ff33dd4b6186d6f083d852e8e810dc195f654cfe3a3728d5fdb68';
// The `UpgradeCap` ID below is for a policy that only permits package upgrades on Saturday
// In order to choose a different day:
// 1. go to `publish.js`, and
// 2. rename `saturdayUpgradeCap` and give it the value of the weekday to be tested
//    - weekdays are of `sui::u8`, range from 0 to 6, and start on Monday.
// 3. rerun `node publish.js`
const CAP_ID = '0x6f9e42f3118ceacb0f8e4ed6de8819a1e57988b2e37347c4e26dda6128c474f7';

const sender = execSync(`${SUI} client active-address`, { encoding: 'utf8' }).trim();
const keyPair = (() => {
    const keystore = JSON.parse(
        readFileSync(
            path.join(homedir(), '.sui', 'sui_config', 'sui.keystore'),
            'utf8',
        )
    );

    for (const priv of keystore) {
        const raw = fromB64(priv);
        if (raw[0] !== 0) {
            continue;
        }

        const pair = Ed25519Keypair.fromSecretKey(raw.slice(1));
        if (pair.getPublicKey().toSuiAddress() === sender) {
            return pair;
        }
    }
    
    throw new Error(`keypair not found for sender: ${sender}`);
})();

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const packagePath = path.join(__dirname, 'example');

const { modules, dependencies, digest } = JSON.parse(
    execSync(
        `${SUI} move build --dump-bytecode-as-base64 --path ${packagePath}`,
        { encoding: 'utf-8'},
    ),
);

const tx = new TransactionBlock();
const cap = tx.object(CAP_ID);
const ticket = tx.moveCall({
    target: `${POLICY_PACKAGE_ID}::day_of_week::authorize_upgrade`,
    arguments: [
        cap,
        tx.pure(UpgradePolicy.COMPATIBLE),
        tx.pure(digest),
    ],
});

const receipt = tx.upgrade({
    modules,
    dependencies,
    packageId: EXAMPLE_PACKAGE_ID,
    ticket,
});

tx.moveCall({
    target: `${POLICY_PACKAGE_ID}::day_of_week::commit_upgrade`,
    arguments: [cap, receipt],
})

const provider = new JsonRpcProvider(devnetConnection);
const signer = new RawSigner(keyPair, provider);

const result = await signer.signAndExecuteTransactionBlock({
    transactionBlock: tx,
    options: {
        showEffects: true,
        showObjectChanges: true,
    }
});

console.log(result)
