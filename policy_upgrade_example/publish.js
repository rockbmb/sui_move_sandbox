// Define some constants relevant to the upgrade policy Sui Move package
const SUI = 'sui';
const POLICY_PACKAGE_ID = '0x911a11d99dfe9dc4bec24bfb669636445a68c2763f67b902dee03cfa1557a8c1';

// Add boilerplate code to get the keypair for the currently active address in the Sui Client CLI:
import { execSync } from 'child_process';
import { readFileSync } from 'fs';
import { homedir } from 'os';
import path from 'path';

import {
    Ed25519Keypair,
    fromB64,
} from '@mysten/sui.js';

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

// Define the path of the package you are publishing.
//
// The following snippet assumes that the package is in a sibling directory to
// publish.js, called example:
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Location of package relative to current directory
const packagePath = path.join(__dirname, 'example');

// Building the Sui Move package
const { modules, dependencies } = JSON.parse(
    execSync(
        `${SUI} move build --dump-bytecode-as-base64 --path ${packagePath}`,
        { encoding: 'utf-8'},
    ),
);

// Next, construct the transaction to publish the package.
//
// Wrap its UpgradeCap in a "day of the week" policy, which permits upgrades on
// Saturdays, and send the new policy back:
import { TransactionBlock } from '@mysten/sui.js';

const tx = new TransactionBlock();
const packageUpgradeCap = tx.publish({ modules, dependencies });
const saturdayUpgradeCap = tx.moveCall({
    target: `${POLICY_PACKAGE_ID}::day_of_week::new_policy`,
    arguments: [
        packageUpgradeCap,
        tx.pure(5), // 5 = Saturday
    ],
});

tx.transferObjects([saturdayUpgradeCap], tx.pure(sender));

// Finally, execute that transaction and display its effects to the console.
import { JsonRpcProvider, RawSigner, devnetConnection } from '@mysten/sui.js'
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

// 06/05/2023 notes
// Creation of another policy for Saturday, package ID
// 0xbb63c68acef28d95b1a29f990a3efbb0705d9e14f232a3ef8ae1986949cd5e8a
// and object ID
// 0x6f9e42f3118ceacb0f8e4ed6de8819a1e57988b2e37347c4e26dda6128c474f7