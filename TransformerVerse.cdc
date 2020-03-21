// TransformerVerse.cdc

// The TransformerVerse contract dictates the laws of operations for the Autobots and their fuel, Energon. 
// As an Autobot continues to get traded among accounts, their powers and rankings will increase.
access(all) contract TransformerVerse {
    // Declare the Autobot resource type
    access(all) resource Autobot {
        // The unique ID that differentiates each Autobot
        access(all) let id: UInt64
        // physicalPower dictates the physical combat ability of an Autobot
        access(all) var physicalPower: UInt64
        // energyPower dictates the energy combat ability of an Autobot
        access(all) var energyPower: UInt64
        // speed dictates the ability of an Autobot to initiate an attack
        access(all) var speed: UInt64
        // evolve dictates the ability for an Autobot to rank up and increase in combat and transform capabilities
        access(all) var evolve: UInt64
        // transform is the ability of an Autobot to assume the form of an entity
        access(all) var transform: UInt64
        // rank is an Autobot's "level" or class tier. The higher the rank, the higher the Autobot's combat prowess. 
        access(all) var rank: Int

        // metadata to store additional data
        access(all) var metadata: {String: String}

        init(id: UInt64, evolve: UInt64, transform: UInt64, physical: UInt64, energy: UInt64, speed: UInt64) {
            self.id = id
            self.evolve = evolve
            self.transform = transform
            self.physicalPower = physical
            self.energyPower = energy
            self.speed = speed
            self.metadata = {}
            self.rank = 1
        }
    }

    // AutobotReceiver is the public interface for external actors to interact with the receiver's Garage
    access(all) resource interface AutobotReceiver {
        access(all) fun deposit(token: @Autobot)
        access(all) fun getIDs(): [UInt64]
        access(all) fun idExists(id: UInt64): Bool
    }

    // The definition of the Garage resource that
    // holds the Autobots that a user owns
    access(all) resource Garage: AutobotReceiver {
        // dictionary of Autobot conforming tokens
        // Autobot is a resource type with an `UInt64` ID field
        access(all) var ownedAutobots: @{UInt64: Autobot}

        // Initialize the Autobots field to an empty Garage
        init () {
            self.ownedAutobots <- {}
        }

        // withdraw removes an Autobot from the Garage 
        // and moves it to the calling context
        access(all) fun withdraw(withdrawID: UInt64): @Autobot {
            // If the Autobot isn't found, the transaction panics and reverts
            let token <- self.ownedAutobots.remove(key: withdrawID) ?? panic("missing Autobot")

            return <-token
        }

        // deposit takes a Autobot as an argument and 
        // adds it to the Garages dictionary
        access(all) fun deposit(token: @Autobot) {
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedAutobots[token.id] <- token
            destroy oldToken
        }

        // idExists checks to see if a Autobot with the given ID exists in the Garage
        access(all) fun idExists(id: UInt64): Bool {
            return self.ownedAutobots[id] != nil
        }

        // getIDs returns an array of the IDs that are in the Garage
        access(all) fun getIDs(): [UInt64] {
            return self.ownedAutobots.keys
        }

        destroy() {
            destroy self.ownedAutobots
        }
    }

    // creates a new empty Garage resource and returns it 
    access(all) fun createNewGarage(): @Garage {
        return <- create Garage()
    }

    // AllSpark
    //
    // A resource to be owned by the root contract.
    // The AllSpark creates new Autobots.
    access(all) resource AllSpark {

        // The primary key for all Autobots. 
        // It also keeps track of the total number of Autobots in existence.
        access(all) var idCount: UInt64

        init() {
            self.idCount = 1
        }

        // create 
        //
        // create creates a new Autobot with a new ID and attributes
        // and deposits it in the recipient's Garage.
        access(all) fun create(recipient: &AutobotReceiver) {

            // create a new Autobot
            var newAutobot <- create Autobot(id: self.idCount, evolve: 100, transform: 100, physical: 100, energy: 100, speed: 100)
            
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
		// store an empty Autobot Garage in account storage
        let oldGarage <- self.account.storage[Garage] <- create Garage()
        destroy oldGarage

        // publish a reference to the Garage in storage
        self.account.published[&AutobotReceiver] = &self.account.storage[Garage] as &AutobotReceiver

        // store a minter resource in account storage
        let oldMinter <- self.account.storage[AllSpark] <- create AllSpark()
        destroy oldMinter
	}
}
