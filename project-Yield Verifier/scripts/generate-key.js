const { Wallet } = require('ethers');
const fs = require('fs');
const path = require('path');

// Generate a new random wallet
const wallet = Wallet.createRandom();

// Get the private key
const privateKey = wallet.privateKey;

// Read the current .env file
const envPath = path.join(__dirname, '..', '.env');
const envContent = fs.readFileSync(envPath, 'utf8');

// Update the PRIVATE_KEY line
const updatedContent = envContent.replace(/PRIVATE_KEY=.*/, `PRIVATE_KEY=${privateKey}`);

// Write back to .env file
fs.writeFileSync(envPath, updatedContent);

console.log('New private key has been generated and saved to .env file');