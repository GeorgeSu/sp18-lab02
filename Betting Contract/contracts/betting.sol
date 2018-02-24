pragma solidity ^0.4.19;


contract Betting {
    /* Constructor function, where owner and outcomes are set */
    function Betting(uint[] _outcomes) public {
        owner = msg.sender;
        numOutcomes = 0;
        for (uint i=0; i < _outcomes.length; i++) {
            outcomes[i] = _outcomes[i];
            numOutcomes++;
        }
    }

    /* Fallback function */
    function() public payable {
        revert();
    }

    /* Standard state variables */
    address public owner;
    address public gamblerA;
    address public gamblerB;
    address public oracle;
    uint public numOutcomes;

    /* Structs are custom data structures with self-defined parameters */
    struct Bet {
        uint outcome;
        uint amount;
        bool initialized;
    }

    /* Keep track of every gambler's bet */
    mapping (address => Bet) bets;
    /* Keep track of every player's winnings (if any) */
    mapping (address => uint) winnings;
    /* Keep track of all outcomes (maps index to numerical outcome) */
    mapping (uint => uint) public outcomes;

    /* Add any events you think are necessary */
    event BetMade(address gambler);
    event BetClosed();

    /* Uh Oh, what are these? */
    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }
    modifier oracleOnly() {
        require(msg.sender == oracle);
        _;
    }
    modifier outcomeExists(uint outcome) {
        bool exists = false;
        for (uint i=0; i < numOutcomes; i++) {
            if (outcomes[i] == outcome) {
                exists = true;
            }
        }
        require(exists == true);
        _;
    }

    /* Owner chooses their trusted Oracle */
    function chooseOracle(address _oracle) public ownerOnly() returns (address) {
        require(oracle != gamblerA);
        require(oracle != gamblerB);
        oracle = _oracle;
    }

    /* Gamblers place their bets, preferably after calling checkOutcomes */
    function makeBet(uint _outcome) public payable returns (bool) {
        // checkOutcomes(_outcome);
        if (gamblerA == 0) {
            gamblerA = msg.sender;
            bets[gamblerA] = Bet(_outcome, msg.value, true);
            BetMade(gamblerA);
        } else if (gamblerB == 0) {
            if (gamblerB == gamblerA) {
                BetClosed();
                return;
            }
            gamblerB = msg.sender;
            bets[gamblerB] = Bet(_outcome, msg.value, true);
            BetMade(gamblerB);
        } else {
            BetClosed();
            return;
        }
    }

    /* The oracle chooses which outcome wins */
    function makeDecision(uint _outcome) public oracleOnly() outcomeExists(_outcome) {
        if (bets[gamblerA].initialized == true) {
            if (bets[gamblerA].outcome == _outcome) {
                winnings[gamblerA] += bets[gamblerA].amount;
            }
        }
        if (bets[gamblerB].initialized == true) {
            if (bets[gamblerB].outcome == _outcome) {
                winnings[gamblerB] += bets[gamblerB].amount;
            }
        }
    }

    /* Allow anyone to withdraw their winnings safely (if they have enough) */
    function withdraw(uint withdrawAmount) public returns (uint) {
        if (winnings[msg.sender] >= withdrawAmount ) {
            msg.sender.transfer(withdrawAmount);
        } else {
            return;
        }
    }
    
    // /* Allow anyone to check the outcomes they can bet on */
    // function checkOutcomes(uint outcome) public view returns (uint) {
    // }
    
    /* Allow anyone to check if they won any bets */
    function checkWinnings() public view returns(uint) {
        return winnings[msg.sender];
    }

    /* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
    function contractReset() public ownerOnly() {
        delete gamblerA;
        delete gamblerB;
    }
}