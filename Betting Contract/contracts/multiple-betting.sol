pragma solidity ^0.4.20;
contract Betting {
    
    //only one owner, defined when contract is created
    // define outcomes at start
    function Betting(uint[] _outcomes) public {
        outcomesCount = 0;
        owner = msg.sender;
        for (uint i = 0; i < _outcomes.length; i++) {
            outcomes[i] = _outcomes[i];
            outcomesCount += 1;
        }
        sameLastOutcome = true;
        lastOutcome = 0;
    }
    /* Fallback function */
    function() public payable {
        revert();
    }
    struct Bet {
        uint outcome;
        uint amount;
        bool initialized;
        bool won;
    }
    struct Balance {
        uint value;
        bool initialized;
    }
    address public owner;
    address public oracle;
    uint private balance;
    // false is some gamblers bet different
    bool private sameLastOutcome;
    // last bet class bet
    uint private lastOutcome;
    uint private outcomesCount;
    uint private addressesCount;
    mapping (uint => address) addresses;
    mapping (address => Bet) bets;
    mapping(uint => uint) outcomes;
    mapping(address => Balance) balances;
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
        for (uint i = 0; i < outcomesCount; i++) {
            if (outcome == outcomes[i]) {
                exists = true;
                break;
            }
        }
        require(exists == true);
        _;
    }
        
    // integrity check, gambler can only bet once
    // if address already exist in contract, have already bet
    function checkGamblerCanBet(address gambler) view private returns (bool) {
        if (bets[gambler].initialized == true) {
            return false;
        }
        return true;
    }
    
    // integrity check, owner cannot bet
    function checkGamblerIsNotOwner(address gambler) view private returns (bool) {
        return (owner != gambler);
    }
    
    // integrity check, oracle cannot be gambler
    function checkGamblerIsNotOracle(address gambler) view private returns (bool) {
        return (gambler != oracle);
    }
    
    // integrity check, oracle is not owner
    function checkOracleIsNotOwner(address newOracle) view private returns (bool) {
        return (newOracle != owner);
    }
    
    //
    function comparelastOutcome(uint outcome) private {
        if (lastOutcome == 0) {
            lastOutcome = outcome;
        } else if (lastOutcome != outcome) {
            sameLastOutcome = false;
        }
    }
    
    // bet check, all gamblers did not bet in the same
    function checkGamblersDontBetInTheSame() view private returns (bool) {
        return !sameLastOutcome;
    }
    /* Owner chooses their trusted Oracle */
    // define oracle, only by owner, returns true if success, false otherwise
    function chooseOracle(address _oracle) public ownerOnly() returns (address) {
        // check new oracle is not owner and message sent by owner
        if (checkOracleIsNotOwner(_oracle)) {
            oracle = _oracle;
            return _oracle;
        }
        return 0;
    }
    
    /* Gamblers place their bets, preferably after calling checkOutcomes */
    // make bet, returns true if bet was made, false otherwise
    function makeBet(uint _outcome) payable public returns (bool) {
        // check if gambler is not owner nor oracle, and gambler can bet (didn't bet before)
        if (checkGamblerIsNotOracle(msg.sender) && 
            checkGamblerIsNotOwner(msg.sender) && checkGamblerCanBet(msg.sender)) {
            
            // if address exists, add to balance
            // if not, create an address and add to balance
            addresses[addressesCount] = msg.sender;
            //balances[msg.sender].value += msg.value;
            balances[msg.sender].initialized = true;
            addressesCount += 1;
            bets[msg.sender] = Bet(_outcome, msg.value, false, false);
            balance += msg.value;
            // compare bet class with last bet class and change data
            comparelastOutcome(_outcome);
            
            return true;
        }
        return false;
    }
    // bet rule, if gambler bet in the same reimburse all the funds
    function oracleHasToReturnFunds() private returns (bool) {
        if (!checkGamblersDontBetInTheSame()) {
            for (uint i = 0; i < addressesCount; i++) {
                addresses[i].transfer(bets[addresses[i]].amount);
            }
            return true;
        }
        return false;
    }
    // oracle chooses, check if has to return equal funds
    // it is not efficient, TO DO
    function makeDecision(uint _outcome) public {
        uint poolBalance = 0;
        uint loserGamblers = 0;
        // if bets are in different outcomes
        if (!oracleHasToReturnFunds()) {
            // put eth in each winner balance
            
            for (uint i = 0; i < addressesCount; i++) {
                if (bets[addresses[i]].outcome != _outcome) {
                    poolBalance += bets[addresses[i]].amount;
                    loserGamblers += 1;
                }
                //balances[addresses[i]].value += bets[addresses[i]].amount;
            }
            uint dividedLeftBalance = poolBalance / (outcomesCount - loserGamblers);
            for (i = 0; i < addressesCount; i++) {
                if (bets[addresses[i]].outcome == _outcome) {
                    balances[addresses[i]].value += bets[addresses[i]].amount + dividedLeftBalance;
                    bets[addresses[i]].won = true;
                }
            }
        }
    }
    /* Allow anyone to withdraw their winnings safely (if they have enough) */
    function withdraw(uint withdrawAmount) public returns (uint) {
        if (balances[msg.sender].initialized && balances[msg.sender].value - withdrawAmount >= 0) {
            if (msg.sender.send(withdrawAmount)) {
                balances[msg.sender].value -= withdrawAmount;
                return 1;
            }
        }
        return 0;
    }
    /* Allow anyone to check the outcomes they can bet on */
    function checkOutcomes(uint outcome) public view returns (uint) {
        for (uint i = 0; i < outcomesCount; i++) {
            if (outcome == outcomes[i]) {
                return 1;
            }
        }
        return 0;
    }
    
    /* Allow anyone to check if they won any bets */
    function checkWinnings() public view returns(uint) {
        if (bets[msg.sender].initialized == true && bets[msg.sender].won == true) {
            return 1;
        }
        return 0;
    }
    /* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
    function contractReset() public ownerOnly() {
    }
    function getBalances() public returns(uint) {
        return balances[msg.sender].value;
    }
         
}
