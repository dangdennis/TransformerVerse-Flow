// InitAccountsWithEverything.cdc

import TransformerVerse from 0x01
import Energon from 0x02

transaction {
    // Autobot minter to roll and create new Autobots
    let allSparkMinter: &TransformerVerse.AllSpark

    // Energon minter to create new vaults to hold Energon
    let energonVaultMinter: &Energon.VaultMinter

    // References to the accounts' new vaults and garages so the minters can add new resources during execution
    let recipient1Garage: &TransformerVerse.AutobotReceiver
    let recipient2Garage: &TransformerVerse.AutobotReceiver
    let recipient1Vault: &Energon.Receiver
    let recipient2Vault: &Energon.Receiver

    // Taking in all 4 accounts because it makes my life easier creating all the foundation resources in one-go
    // TODO: Separate the minting of Vault and Collection
    prepare(minter1: Account, minter2: Account, recipient1: Account, recipient2: Account) {
        // Save a reference to the AllSpark minter
        self.allSparkMinter = &minter1.storage[TransformerVerse.AllSpark] as &TransformerVerse.AllSpark

        // Save a reference to the Energon minter
        self.energonVaultMinter = &minter2.storage[Energon.VaultMinter] as &Energon.VaultMinter

        // Create the collections and vaults for the other accounts
        let oldGarage1 <- recipient1.storage[TransformerVerse.AutobotGarage] <- TransformerVerse.createEmptyAutobotGarage()
        destroy oldGarage1
        let oldGarage2 <- recipient2.storage[TransformerVerse.AutobotGarage] <- TransformerVerse.createEmptyAutobotGarage()
        destroy oldGarage2

        let oldVault1 <- recipient1.storage[Energon.Vault] <- Energon.createEmptyVault()
        destroy oldVault1
        let oldVault2 <- recipient2.storage[Energon.Vault] <- Energon.createEmptyVault()
        destroy oldVault2
        
        self.recipient1Garage = &recipient1.storage[TransformerVerse.AutobotGarage] as &TransformerVerse.AutobotReceiver
        self.recipient2Garage = &recipient2.storage[TransformerVerse.AutobotGarage] as &TransformerVerse.AutobotReceiver
        
        self.recipient1Vault = &recipient1.storage[Energon.Vault] as &Energon.Receiver
        self.recipient2Vault = &recipient2.storage[Energon.Vault] as &Energon.Receiver
    }

    execute {
        // Create some Autobots and hella Energon 
        mintAutobots(recipient: self.recipient1Garage, minter: self.allSparkMinter)
        mintAutobots(recipient: self.recipient2Garage, minter: self.allSparkMinter)
        mintEnergon(recipient: self.recipient1Vault, minter: self.energonVaultMinter)
        mintEnergon(recipient: self.recipient2Vault, minter: self.energonVaultMinter)

        log("execute: mint a crap ton of things")
    }

    post {
        // Check that we created the right number of Autobots 
        self.recipient1Garage.getIDs().length == 10: "Shoot, not enough Autobots were created"
        self.recipient2Garage.getIDs().length == 10: "Shoot, not enough Autobots were created"
        self.recipient1Vault.balance == UInt64(500000): "Shoot, not enough Energon were received"
        self.recipient2Vault.balance == UInt64(500000): "Shoot, not enough Energon were received"
    }
}

// mintEnergon mints and 
access(all) fun mintEnergon(recipient: &Energon.Receiver, minter: &Energon.VaultMinter) {
    minter.mintEnergon(amount: 500000, recipient: recipient)
}

// mintAutobots creates a handful of Autobots for an AutobotReceiver
access(all) fun mintAutobots(recipient: &TransformerVerse.AutobotReceiver, minter: &TransformerVerse.AllSpark) {
    var x = 0
    while x < 10 {
        minter.create(recipient: recipient)
        x = x + 1
    }
}