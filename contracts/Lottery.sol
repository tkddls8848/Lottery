pragma solidity >=0.4.21 <0.6.0;

contract Lottery {

    struct betInfo {
        uint256 answerBlocknumber;
        address payable betPerson;
        byte challenges;
    }

    uint256 private head;
    uint256 private tail;
    mapping(uint256=>betInfo) private betInfoMap;

    address public owner;

    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;
    address constant internal BLOCK_INTERVAL = 3;
    uint256 constant internal BLOCK_LIMIT = 256;

    uint256 private pot;

    event BET(uint256 answerBlocknumber, address betPerson, byte challenges)

    constructor() public {
        owner = msg.sender;
    }

    function getValue() public pure returns (uint256 value){
        return 5;
    }

    function getPot() public view returns (uint256 potValue) {
        return pot;
    }

    /**
    @dev 배팅을 하고 , 이더 보내고, 해쉬값 보낸다.
    @param challenges 유저입력해쉬 
    @return 함수 수행여부에 따른 boolean
     */
    function bet(byte challenges) public payable returns (bool result) {
        require(msg.value == BET_AMOUNT, 'not enough ETH');
        require(pushBet(challenges), 'cant pushBet');
        emit BET(tail-1, msg.sender, challenges);

        return true;
    }

    function getBetInfo(uint256 index) public view returns (uint256 answerBlocknumber, address betPerson, byte challenges){
        BetInfo memory b = betInfoMap[index];

        answerBlocknumber = b.answerBlocknumber;
        betPerson = b.betPerson;
        challenges = b.challenges;
    }

    function pushBet(byte hashcode) public returns (bool){
        BetInfo memory b;

        answerBlocknumber = block.number + BLOCK_INTERVAL;
        betPerson = msg.sender;
        challenges = hashcode;

        betInfoMap[tail] = b;
        tail++;

        return true;
    }

    function popBet(uint256 index) public returns (bool){
        delete betInfoMap[index];
        
        return true;   
    }
}