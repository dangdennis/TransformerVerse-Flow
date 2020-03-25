// TransformerVerse.cdc

// The TransformerVerse contract dictates the laws of operations for the Transformer and their fuel, Energon. 
// As an Transformer continues to get traded among accounts, their powers and rankings will increase.
access(all) contract TransformerVerse {
    // Bot is the public layer for a Transformer resource
    access(all) resource interface Bot {
        access(all) var timesTraded: UInt64
        access(all) var name: String
    }

    access(all) let Decepticons: String
    access(all) let Autobots: String

    // Transformer rankings by factions
    access(contract) let autobotRankToTitle: {Int: String}
    access(contract) let decepticonRankToTitle: {Int: String}

    // Declare the Transformer resource type
    access(all) resource Transformer: Bot {
        // The unique ID that differentiates each Transformer
        access(all) let id: UInt64
        // Transformer name
        access(all) var name: String
        // isNamed is a flag to allow renaming a Transformer once
        access(self) var isNamed: String
        // faction: Autobots vs Decepticons
        access(all) let faction: String
        // physicalPower dictates the physical combat ability of an Transformer
        access(all) var physicalPower: UInt64
        // energyPower dictates the energy combat ability of an Transformer
        access(all) var energyPower: UInt64
        // speed dictates the ability of an Transformer to initiate an attack
        access(all) var speed: UInt64
        // growth dictates the ability for an Transformer to rank up and increase in combat and transform capabilities
        access(all) var growth: UInt64
        // transform is the ability of an Transformer to assume the form of an entity
        access(all) var transform: UInt64
        // rank is an Transformer's "level" or class tier. The higher the rank, the higher the Transformer's combat prowess. 
        access(all) var rank: Int
        // timesTraded counts the number of times this resource has been 
        access(all) var timesTraded: UInt64



        init(id: UInt64, faction: String, growth: UInt64, transform: UInt64, physical: UInt64, energy: UInt64, speed: UInt64) {
            self.id = id
            self.faction = faction
            self.growth = growth
            self.transform = transform
            self.physicalPower = physical
            self.energyPower = energy
            self.speed = speed
            self.rank = 1
            self.timesTraded = 0
            self.name = "Unnamed Transformer"
        }

        // a Transformer can only be named once
        access(all) fun setName(name: String) {
            if !self.isNamed {
                self.name = name
            }
            self.isNamed = true
        }

        access(all) fun title(): String? {
            if self.faction == TransformerVerse.Autobots {
                return TransformerVerse.autobotRankToTitle[self.rank]
            } else {
                return TransformerVerse.decepticonRankToTitle[self.rank]
            }
        }
    }

    // TransformerReceiver is the public interface for external actors to interact with the receiver's TransformerGarage
    access(all) resource interface TransformerReceiver {
        access(all) fun deposit(token: @Transformer)
        access(all) fun getIDs(): [UInt64]
        access(all) fun idExists(id: UInt64): Bool
    }

    // The definition of the TransformerGarage resource that
    // holds the Transformer that a user owns
    access(all) resource TransformerGarage: TransformerReceiver {
        // dictionary of Transformer conforming tokens
        // Transformer is a resource type with an `UInt64` ID field
        access(all) var ownedTransformers: @{UInt64: Transformer}

        // Initialize the Transformer field to an empty TransformerGarage
        init () {
            self.ownedTransformers <- {}
        }

        // withdraw removes an Transformer from the TransformerGarage 
        // and moves it to the calling context
        access(all) fun withdraw(withdrawID: UInt64): @Transformer {
            // If the Transformer isn't found, the transaction panics and reverts
            let token <- self.ownedTransformers.remove(key: withdrawID) ?? panic("missing Transformer")

            return <-token
        }

        // deposit takes a Transformer as an argument and 
        // adds it to the TransformerGarages dictionary
        access(all) fun deposit(token: @Transformer) {
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedTransformers[token.id] <- token
            destroy oldToken
        }

        // idExists checks to see if a Transformer with the given ID exists in the TransformerGarage
        access(all) fun idExists(id: UInt64): Bool {
            return self.ownedTransformers[id] != nil
        }

        // getIDs returns an array of the IDs that are in the TransformerGarage
        access(all) fun getIDs(): [UInt64] {
            return self.ownedTransformers.keys
        }

        destroy() {
            destroy self.ownedTransformers
        }
    }

    // creates a new empty TransformerGarage resource and returns it 
    access(all) fun createEmptyTransformerGarage(): @TransformerGarage {
        return <- create TransformerGarage()
    }

    // The AllSpark creates new Transformer.
    access(all) resource AllSpark {
        // id is the primary key for all Transformer. 
        // It also keeps track of the total number of Transformer in existence.
        access(self) var id: UInt64
        access(self) let TransformerSupply: {Int: Int}
        access(self) var TransformerRankGeneratorCounter: Int

        init() {
            self.id = 1
            // TransformerRankGeneratorCounter maintains random state specifically for rank/growth
            // Start off at Prime rank (10) for the genesis token!
            // TODO: Once we get some floor and modulo, can reuse the RNG struct
            self.TransformerRankGeneratorCounter = 10 

            self.TransformerSupply = {
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
        }

        // create creates a new Transformer with a new ID and attributes
        // and deposits it in the recipient's TransformerGarage.
         access(all) fun create(recipient: &TransformerReceiver) {
            let growth = self.rollGrowth()

            // create a new Transformer
            var newTransformer <- create Transformer(id: self.id, faction: self.whichFaction(TransformerVerse.rng.roll()), growth: UInt64(growth), transform: UInt64(TransformerVerse.rng.roll()), physical: UInt64(TransformerVerse.rng.roll()), energy: UInt64(TransformerVerse.rng.roll()), speed: UInt64(TransformerVerse.rng.roll()))
            
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-newTransformer)

            // change the id so that each ID is unique
            self.id = self.id + UInt64(1)
        }

        // whichFaction will return a Transformer faction dependent on roll
        access(self) fun whichFaction(_ roll: Int): String {
            if roll > 50 {
                return TransformerVerse.Decepticons
            } else {
                return TransformerVerse.Autobots
            }
        }


        // rollGrowth will return a "random" number
        access(self) fun rollGrowth(): Int {
            if self.isSupplyEmpty() {
                return 1
            }

            var currentGrowth = self.TransformerRankGeneratorCounter
            while self.TransformerSupply[currentGrowth] == 0 {
                currentGrowth = currentGrowth - 1
                if currentGrowth < 1 {
                    currentGrowth = 10
                }
            }
            self.updateTransformerSupply(rank: currentGrowth) 
            self.updateGrowthCounter()
            return currentGrowth
        }

        access(self) fun isSupplyEmpty(): Bool {
            let keys = self.TransformerSupply.keys
            var idx = 1
            while idx <= self.TransformerSupply.length {
                if let supply = self.TransformerSupply[idx] {
                    if supply != 0 {
                        return false
                    }
                }
                idx = idx + 1
            }

            return true
        }
        
        // updateTransformerSupply simply decrements from the total supply
        access(self) fun updateTransformerSupply(rank: Int) {
            if let supply = self.TransformerSupply[rank] {
                let newSupply = supply - 1
                self.TransformerSupply[rank] = newSupply
            }
        }

        // updateGrowthCounter updates the index that selects our "random" number
        access(self) fun updateGrowthCounter() {
            if self.TransformerRankGeneratorCounter == self.TransformerSupply.keys.length {
                // reset the counter
                self.TransformerRankGeneratorCounter = 1
            } else {
                self.TransformerRankGeneratorCounter = self.TransformerRankGeneratorCounter + 1
            }
        }
    }

    access(all) let rng: RNG

	init() {
		// store an empty Transformer TransformerGarage in account storage
        let oldTransformerGarage <- self.account.storage[TransformerGarage] <- create TransformerGarage()
        destroy oldTransformerGarage

        // publish a reference to the TransformerGarage in storage
        self.account.published[&TransformerReceiver] = &self.account.storage[TransformerGarage] as &TransformerReceiver

        // store the Transformer minter resource in account storage
        let oldAllSpark <- self.account.storage[AllSpark] <- create AllSpark()
        destroy oldAllSpark

        self.Autobots = "Autobots"
        self.autobotRankToTitle = {
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

        self.Decepticons = "Decepticons"
        self.decepticonRankToTitle = {
            1: "Rank 1",
            2: "Rank 2",
            3: "Rank 3",
            4: "Rank 4",
            5: "Rank 5",
            6: "Rexxar",
            7: "Vaporus",
            8: "Larraxus",
            9: "Imperior",
            10: "Emperor"
        }

        self.rng = RNG()
	}

    /* 
    * Below this line are additional helper resources and structs.
    * Ideally I have many other contract files where I'd store these helpers instead.
    */

    // RNG is necessary atm to act as a temporary form of random number generator
    access(all) struct RNG {
        access(all) var diceOne: [Int; 100]
        access(all) var diceTwo: [Int; 100]
        access(all) var counterOne: Int
        access(all) var counterTwo: Int

        init() {
            // My amazingly smart RNG machine
            self.diceOne = [63, 23, 50, 68, 29, 71, 27, 25, 72, 85, 90, 55, 89, 82, 33, 57, 53, 57, 97, 69, 83, 5, 81, 89, 37, 18, 63, 26, 13, 64, 84, 5, 29, 23, 10, 67, 94, 61, 91, 79, 78, 61, 92, 98, 26, 91, 86, 49, 56, 34, 65, 80, 25, 21, 90, 36, 30, 52, 32, 16, 55, 77, 30, 62, 65, 71, 58, 27, 73, 60, 2, 63, 34, 73, 27, 42, 85, 94, 50, 90, 20, 87, 42, 43, 77, 4, 95, 66, 63, 93, 53, 25, 91, 1, 53, 74, 2, 100, 92, 5]
            self.diceTwo = [39, 2, 67, 61, 95, 21, 77, 25, 59, 24, 94, 92, 8, 69, 50, 81, 85, 65, 82, 8, 35, 6, 8, 4, 42, 88, 67, 16, 53, 10, 19, 9, 84, 30, 83, 84, 31, 94, 57, 5, 59, 16, 17, 53, 6, 100, 15, 16, 62, 95, 70, 35, 63, 72, 21, 62, 97, 79, 42, 64, 66, 81, 75, 15, 87, 10, 16, 67, 81, 61, 80, 62, 75, 95, 65, 65, 39, 30, 87, 19, 89, 8, 75, 30, 27, 77, 95, 41, 67, 46, 68, 4, 24, 93, 1, 77, 76, 95, 80, 58]
            self.counterOne = 0
            self.counterTwo = 0
        }

        // roll will return a "random" number
        access(all) fun roll(): Int {
            let fate = self.diceOne[self.counterOne] + self.diceTwo[self.counterTwo]
            self.updateCounters()
            return fate
        }

        // updateCounters manually "randomizes" the dice's index counters
        access(all) fun updateCounters() {
            // If I was smart enough, I'd probably have a better solution given the current language constraints. Maybe try some bitwise operation.
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
    }
}

