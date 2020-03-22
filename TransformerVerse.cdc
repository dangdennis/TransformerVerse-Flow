// TransformerVerse.cdc

// The TransformerVerse contract dictates the laws of operations for the Autobots and their fuel, Energon. 
// As an Autobot continues to get traded among accounts, their powers and rankings will increase.
access(all) contract TransformerVerse {
    // Tradables is the base layer for any tradable resource
    access(all) resource interface Tradables {
        access(all) var timesTraded: UInt64
    }

    // Declare the Autobot resource type
    access(all) resource Autobot: Tradables {
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
        // timesTraded counts the number of times this resource has been 
        access(all) var timesTraded: UInt64

        // additional metadata fields
        access(all) let rankToTitle: {Int: String}

        init(id: UInt64, evolve: UInt64, transform: UInt64, physical: UInt64, energy: UInt64, speed: UInt64) {
            self.id = id
            self.evolve = evolve
            self.transform = transform
            self.physicalPower = physical
            self.energyPower = energy
            self.speed = speed
            self.rank = 1
            self.timesTraded = 0

            // TODO: There has to be a better place to set the rankToTitle mapping.
            // Move this into a getter somewhere else. Ideally an Autobot can reference it as some struct from TransformerVerse
            self.rankToTitle = {
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

        // wonder how I can turn this into a struct getter. Is that possible for resources?
        access(all) fun title(): String? {
            return self.rankToTitle[self.rank]
        }
    }

    // AutobotReceiver is the public interface for external actors to interact with the receiver's AutobotGarage
    access(all) resource interface AutobotReceiver {
        access(all) fun deposit(token: @Autobot)
        access(all) fun getIDs(): [UInt64]
        access(all) fun idExists(id: UInt64): Bool
    }

    // The definition of the AutobotGarage resource that
    // holds the Autobots that a user owns
    access(all) resource AutobotGarage: AutobotReceiver {
        // dictionary of Autobot conforming tokens
        // Autobot is a resource type with an `UInt64` ID field
        access(all) var ownedAutobots: @{UInt64: Autobot}

        // Initialize the Autobots field to an empty AutobotGarage
        init () {
            self.ownedAutobots <- {}
        }

        // withdraw removes an Autobot from the AutobotGarage 
        // and moves it to the calling context
        access(all) fun withdraw(withdrawID: UInt64): @Autobot {
            // If the Autobot isn't found, the transaction panics and reverts
            let token <- self.ownedAutobots.remove(key: withdrawID) ?? panic("missing Autobot")

            return <-token
        }

        // deposit takes a Autobot as an argument and 
        // adds it to the AutobotGarages dictionary
        access(all) fun deposit(token: @Autobot) {
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedAutobots[token.id] <- token
            destroy oldToken
        }

        // idExists checks to see if a Autobot with the given ID exists in the AutobotGarage
        access(all) fun idExists(id: UInt64): Bool {
            return self.ownedAutobots[id] != nil
        }

        // getIDs returns an array of the IDs that are in the AutobotGarage
        access(all) fun getIDs(): [UInt64] {
            return self.ownedAutobots.keys
        }

        destroy() {
            destroy self.ownedAutobots
        }
    }

    // creates a new empty AutobotGarage resource and returns it 
    access(all) fun createNewAutobotGarage(): @AutobotGarage {
        return <- create AutobotGarage()
    }

    // AllSpark is to be owned by the root contract.
    // The AllSpark creates new Autobots.
    // TODO: Encapsulate RNG related code into a working struct or resource
    access(all) resource AllSpark {
        // idCounter is the primary key for all Autobots. 
        // It also keeps track of the total number of Autobots in existence.
        access(all) var idCounter: UInt64
        access(all) let autobotSupply: {Int: Int}

        init() {
            self.idCounter = 1

            self.autobotRankGeneratorCounter = 10 // Start off at Prime rank for the genesis token!
            self.autobotSupply = {
                1: 100000,
                2: 10000,
                3: 5000,
                4: 2000,
                5: 1000,
                6: 500,
                7: 100,
                8: 50,
                9: 15,
                10: 5
            }
            
            // RNG stuff lol
            self.diceOne = [63, 23, 50, 68, 29, 71, 27, 25, 72, 85, 90, 55, 89, 82, 33, 57, 53, 57, 97, 69, 83, 5, 81, 89, 37, 18, 63, 26, 13, 64, 84, 5, 29, 23, 10, 67, 94, 61, 91, 79, 78, 61, 92, 98, 26, 91, 86, 49, 56, 34, 65, 80, 25, 21, 90, 36, 30, 52, 32, 16, 55, 77, 30, 62, 65, 71, 58, 27, 73, 60, 2, 63, 34, 73, 27, 42, 85, 94, 50, 90, 20, 87, 42, 43, 77, 4, 95, 66, 63, 93, 53, 25, 91, 1, 53, 74, 2, 100, 92, 5]
            self.diceTwo = [39, 2, 67, 61, 95, 21, 77, 25, 59, 24, 94, 92, 8, 69, 50, 81, 85, 65, 82, 8, 35, 6, 8, 4, 42, 88, 67, 16, 53, 10, 19, 9, 84, 30, 83, 84, 31, 94, 57, 5, 59, 16, 17, 53, 6, 100, 15, 16, 62, 95, 70, 35, 63, 72, 21, 62, 97, 79, 42, 64, 66, 81, 75, 15, 87, 10, 16, 67, 81, 61, 80, 62, 75, 95, 65, 65, 39, 30, 87, 19, 89, 8, 75, 30, 27, 77, 95, 41, 67, 46, 68, 4, 24, 93, 1, 77, 76, 95, 80, 58]
            self.counterOne = 0
            self.counterTwo = 0
        }

        // create creates a new Autobot with a new ID and attributes
        // and deposits it in the recipient's AutobotGarage.
         access(all) fun create(recipient: &AutobotReceiver) {
            // TODO decrease supply depending on evolve level
            let evolveRank = self.rollEvolvability()

            // create a new Autobot
            var newAutobot <- create Autobot(id: self.idCounter, evolve: UInt64(evolveRank), transform: UInt64(self.rollDice()), physical: UInt64(self.rollDice()), energy: UInt64(self.rollDice()), speed: UInt64(self.rollDice()))
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newAutobot)

            // change the id so that each ID is unique
            self.idCounter = self.idCounter + UInt64(1)
        }

        /* 
        * Below this line are additional helper resources and structs for the AllSpark
        * Basically hacks to handle stateful number generation
        * Ideally I have unlimited contract files or working structs/resources where I'd store these helpers instead.
        */
        access(self) var autobotRankGeneratorCounter: Int
        access(self) var diceOne: [Int]
        access(self) var diceTwo: [Int]
        access(self) var counterOne: Int
        access(self) var counterTwo: Int

        // rollDice will return a "random" number
        access(all) fun rollDice(): Int {
            let fate = self.diceOne[self.counterOne] + self.diceTwo[self.counterTwo]
            self.calculateNewCounters()
            return fate
        }

        // calculateNewCounters manually "randomizes" the dice's index counters
        access(self) fun calculateNewCounters() {
            // If I was smart enough, I'd probably have a better solution given the current language constraints
            // Maybe try some bitwise operation
            if self.counterOne == self.diceOne.length {
                self.counterOne = 0
            } else {
                self.counterOne = self.counterOne + 1
            }

            if self.counterTwo == self.diceTwo.length {
                self.counterTwo = 0
            } else {
                self.counterTwo = self.counterTwo + 1
            }
        }

        // rollEvolvability will return a "random" number
        access(all) fun rollEvolvability(): Int {
            let evolvability = self.autobotRankGeneratorCounter
            self.calculateNewEvolveCounter()
            return evolvability
        }

        access(all) fun calculateNewEvolveCounter() {
            if self.autobotRankGeneratorCounter == self.autobotSupply.keys.length {
                // reset the counter
                self.autobotRankGeneratorCounter = 1
            } else {
                self.autobotRankGeneratorCounter = self.autobotRankGeneratorCounter + 1
            }
        }
    }

	init() {
		// store an empty Autobot AutobotGarage in account storage
        let oldAutobotGarage <- self.account.storage[AutobotGarage] <- create AutobotGarage()
        destroy oldAutobotGarage

        // publish a reference to the AutobotGarage in storage
        self.account.published[&AutobotReceiver] = &self.account.storage[AutobotGarage] as &AutobotReceiver

        // store a minter resource in account storage
        let oldMinter <- self.account.storage[AllSpark] <- create AllSpark()
        destroy oldMinter
	}

    /* 
    * Below this line are additional helper resources and structs.
    * Ideally I have many other contract files where I'd store these helpers instead.
    */

    // RNG is necessary atm to act as a temporary form of random number generator
    // Question: Why can't I make this RNG access(self)
    /*
    access(all) resource RNG {
        access(all) var diceOne: [Int; 6]
        access(all) var diceTwo: [Int; 6]
        access(self) var counterOne: Int
        access(self) var counterTwo: Int

        init() {
            self.diceOne = [1,2,3,4,5,6]
            self.diceTwo = [1,2,3,4,5,6]

            self.counterOne = 0
            self.counterTwo = 5
        }

        access(all) fun rollDice(): Int {
            let fate = self.diceOne[self.counterOne] + self.diceTwo[self.counterTwo]
            self.calculateNewCounters()
            return fate
        }

        // calculateNewCounters manually "randomizes" the dice's index counters
        access(self) fun calculateNewCounters() {
            // If I was smart enough, I'd probably have a better solution given the current language constraints
            if self.counterOne == 5 {
                self.counterOne = 0
            } else {
                self.counterOne = self.counterOne + 1
            }

            if self.counterTwo == 5 {
                self.counterTwo = 0
            } else {
                self.counterTwo = self.counterTwo + 1
            }
        }
    }
    */
}

