/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

contract EtherLottery {
    address public owner;
    uint256 public ticketPrice;
    uint256 public threshold;
    uint256 public totalTicketsSold;
    bool public isLotteryClosed;
    address[] public participants;

    mapping(address => uint256) public ticketBalances;

    event LotteryClosed(address winner, uint256 prizePool);

    constructor(uint256 _ticketPrice, uint256 _threshold) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        threshold = _threshold;
        totalTicketsSold = 0;
        isLotteryClosed = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function buyTicket() public payable {
        require(!isLotteryClosed, "Lottery is closed.");
        require(msg.value == ticketPrice, "Incorrect ticket price.");
        require(ticketBalances[msg.sender] == 0, "Already bought a ticket.");

        totalTicketsSold++;
        participants.push(msg.sender);
        ticketBalances[msg.sender] = msg.value;

        if (totalTicketsSold == threshold) {
            closeLottery();
        }
    }

    function closeLottery() private {
        require(!isLotteryClosed, "Lottery is already closed.");
        require(totalTicketsSold == threshold, "Threshold not reached.");

        uint256 winnerIndex = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.difficulty))
        ) % participants.length;
        address payable winner = payable(participants[winnerIndex]);
        uint256 prizePool = ticketPrice * totalTicketsSold;

        isLotteryClosed = true;
        emit LotteryClosed(winner, prizePool);

        ticketBalances[winner] = 0;
        winner.transfer(prizePool);
    }

    function withdraw() public {
        require(isLotteryClosed, "Lottery is not closed.");
        require(ticketBalances[msg.sender] > 0, "No balance to withdraw.");

        uint256 balance = ticketBalances[msg.sender];
        ticketBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    function removeParticipant(address participant) private {
        for (uint256 i = 0; i < participants.length; i++) {
            if (participants[i] == participant) {
                participants[i] = participants[participants.length - 1];
                participants.pop();
                return;
            }
        }
    }

    function refund() public {
        require(isLotteryClosed, "Lottery is not closed.");
        require(totalTicketsSold < threshold, "Threshold is already reached.");
        require(ticketBalances[msg.sender] > 0, "No balance to refund.");

        uint256 balance = ticketBalances[msg.sender];
        ticketBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        removeParticipant(msg.sender);
    }
}
