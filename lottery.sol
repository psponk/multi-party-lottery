// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Lottery {
    address public owner;
    uint public stage;
    uint public numParticipants;
    uint public pot;
    mapping(address => bool) public hasCommitted;
    mapping(address => bool) public hasRevealed;
    mapping(address => uint) public commitment;
    mapping(address => uint) public revealValue;
    uint public startTime;
    uint public revealTime;
    uint public determineTime;

constructor(uint _numParticipants, uint _T1, uint _T2) {
    owner = msg.sender;
    numParticipants = _numParticipants;
    stage = 1;
    startTime = block.timestamp;
    revealTime = startTime + _T1;
    determineTime = revealTime + _T2;
}

    function commit(uint _value) external payable {
        require(stage == 1, "Not in commit stage");
        require(msg.value == 0.001 ether, "Please send 0.001 ether with your commit");
        require(_value >= 0 && _value <= 999, "Value must be between 0 and 999");
        require(!hasCommitted[msg.sender], "Already committed");

        pot += msg.value;
        hasCommitted[msg.sender] = true;
        commitment[msg.sender] = _value;
        
        if (block.timestamp >= revealTime) {
            stage = 3;
        }
    }

    function reveal(uint _value) external {
        require(stage == 2, "Not in reveal stage");
        require(block.timestamp < revealTime, "Reveal period ended");
        require(hasCommitted[msg.sender], "Not committed");
        require(!hasRevealed[msg.sender], "Already revealed");

        hasRevealed[msg.sender] = true;
        revealValue[msg.sender] = _value;
        
        if (block.timestamp >= revealTime && !determineWinner()) {
            stage = 4;
        }
    }

    function determineWinner() internal returns (bool) {
        require(stage == 3, "Not in determine winner stage");
        require(block.timestamp < determineTime, "Determine winner period ended");

        uint finalValue = 0;
        address[] memory winners;
        uint numWinners = 0;

        for (uint i = 0; i < numParticipants; i++) {
            address participant = address(uint160(i)); // Convert uint to address
            if (hasRevealed[participant]) {
                finalValue ^= revealValue[participant];
                winners[numWinners++] = participant;
            }
        }

        if (finalValue == 0 || block.timestamp >= determineTime) {
            if (finalValue == 0) {
                // Distribute pot equally among all participants
                uint reward = pot / numParticipants;
                for (uint i = 0; i < numWinners; i++) {
                    payable(winners[i]).transfer(reward);
                }
            } else {
                // Distribute pot to owner
                payable(owner).transfer(pot);
            }
            stage = 5;
            return true;
        }

        return false;
    }

    function withdraw() external {
        require(stage == 4 || stage == 5, "Cannot withdraw at this stage");
        require(hasCommitted[msg.sender], "Not committed");
        require(!hasRevealed[msg.sender] || revealTime >= block.timestamp, "Already revealed");

        payable(msg.sender).transfer(0.001 ether);
        hasCommitted[msg.sender] = false;
    }
}