// TransformerVerse.cdc

// The TransformerVerse contract dictates the laws of operations for the Autobots
// and their fuel, Energon. 
access(all) contract TransformerVerse {
    // Declare the Autobot resource type
    access(all) resource Autobot {
        // The unique ID that differentiates each Autobot
        access(all) let id: UInt64

        // String mapping to hold metadata
        access(all) var metadata: {String: String}

        // Initialize both fields in the init function
        init(initID: UInt64) {
            self.id = initID
            self.metadata = {}
        }
    }

    // We define this interface purely as a way to allow users
    // to create public, restricted references to their Autobot Collection.
    // They would use this to only expose the deposit, getIDs,
    // and idExists fields in their Collection
    access(all) resource interface AutobotReceiver {

        access(all) fun deposit(token: @Autobot)

        access(all) fun getIDs(): [UInt64]

        access(all) fun idExists(id: UInt64): Bool
    }

    // The definition of the Collection resource that
    // holds the Autobots that a user owns
    access(all) resource Collection: AutobotReceiver {
        // dictionary of Autobot conforming tokens
        // Autobot is a resource type with an `UInt64` ID field
        access(all) var ownedAutobots: @{UInt64: Autobot}

        // Initialize the Autobots field to an empty collection
        init () {
            self.ownedAutobots <- {}
        }

        // withdraw 
        //
        // Function that removes an Autobot from the collection 
        // and moves it to the calling context
        access(all) fun withdraw(withdrawID: UInt64): @Autobot {
            // If the Autobot isn't found, the transaction panics and reverts
            let token <- self.ownedAutobots.remove(key: withdrawID) ?? panic("missing Autobot")

            return <-token
        }

        // deposit 
        //
        // Function that takes a Autobot as an argument and 
        // adds it to the collections dictionary
        access(all) fun deposit(token: @Autobot) {
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedAutobots[token.id] <- token
            destroy oldToken
        }

        // idExists checks to see if a Autobot with the given ID exists in the collection
        access(all) fun idExists(id: UInt64): Bool {
            return self.ownedAutobots[id] != nil
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all) fun getIDs(): [UInt64] {
            return self.ownedAutobots.keys
        }

        destroy() {
            destroy self.ownedAutobots
        }
    }

    // creates a new empty Collection resource and returns it 
    access(all) fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // AutobotMinter
    //
    // Resource that would be owned by an admin or by a smart contract 
    // that allows them to mint new Autobots when needed
    access(all) resource AutobotMinter {

        // the ID that is used to mint Autobots
        // it is onlt incremented so that Autobot ids remain
        // unique. It also keeps track of the total number of Autobots
        // in existence
        access(all) var idCount: UInt64

        init() {
            self.idCount = 1
        }

        // mintAutobot 
        //
        // Function that mints a new Autobot with a new ID
        // and deposits it in the recipients collection using their collection reference
        access(all) fun mintAutobot(recipient: &AutobotReceiver) {

            // create a new Autobot
            var newAutobot <- create Autobot(initID: self.idCount)
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newAutobot)

            // change the id so that each ID is unique
            self.idCount = self.idCount + UInt64(1)
        }
    }

        // AutobotRankings correlates rank number to rank name
    access(all) struct AutobotRankings {
        access(all) let rankToNames: {Int: String}

        init() {
            self.rankToNames = {
                1: "Rank 1",
                2: "Rank 2",
                3: "Rank 3",
                4: "Rank 4",
                5: "Rank 5",
                6: "Maximus",
                7: "Magnus",
                8: "Rodimus",
                9: "Optimus",
                10: "Prime"
            }
        }
    }

	init() {
		// store an empty Autobot Collection in account storage
        let oldCollection <- self.account.storage[Collection] <- create Collection()
        destroy oldCollection

        // publish a reference to the Collection in storage
        self.account.published[&AutobotReceiver] = &self.account.storage[Collection] as &AutobotReceiver

        // store a minter resource in account storage
        let oldMinter <- self.account.storage[AutobotMinter] <- create AutobotMinter()
        destroy oldMinter
	}
}
